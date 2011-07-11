package com.xinchejian.art.server;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.NetworkInterface;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketAddress;
import java.net.SocketException;
import java.util.Enumeration;
import java.util.List;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.ReentrantLock;
import java.util.zip.Deflater;

import android.app.Service;
import android.content.Intent;
import android.content.SharedPreferences;
import android.hardware.Camera;
import android.hardware.Camera.Size;
import android.os.Binder;
import android.os.IBinder;
import android.util.Log;

import com.xinchejian.art.robot.RobotCommands;
import com.xinchejian.art.robot.RobotData;

public class SenderService extends Service {
	public class LocalBinder extends Binder {
		public SenderService getService() {
			// Return this instance of LocalService so clients can call public
			// methods
			return SenderService.this;
		}
	}

	private class Frame {
		public boolean compression;
		int compressedSize;
		byte[] data;
		int uncompressedSize;

		public Frame() {
			uncompressedSize = 0;
			compressedSize = 0;
			compression = false;
		}
	}

	private final class PreviewCallbackImplementation implements
			Camera.PreviewCallback {
		public void onPreviewFrame(byte[] previewFrameBytes, Camera camera) {
			try {
				if (camera == null) {
					return;
				}
				Frame frame = new Frame();
				frame.compression = compression;
				if (compression) {
					if (!freeBuffers.isEmpty()) {
						frame.data = freeBuffers.take();
						compresser.reset();
						compresser.setInput(previewFrameBytes);
						compresser.finish();
						frame.compressedSize = compresser.deflate(frame.data);
						frame.uncompressedSize = previewFrameBytes.length;
					} else {
						dropped++;
					}
				} else {
					frame.data = previewFrameBytes;
					frame.uncompressedSize = preW * preH * bytesPerPixel;
				}
				filledFrames.put(frame);
				frames++;
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}
	}

	private final class serverThreadRunnable implements Runnable {
		@Override
		public void run() {

			while (!isExit) {
				ServerSocket serverSocket;
				try {
					serverSocket = new ServerSocket();
					String hostName = getLocalIpAddress();
					if (hostName != null) { // may be null when network is off
						SocketAddress address = new InetSocketAddress(hostName,
								8888);
						serverSocket.bind(address);
					} else {
						continue;
					}
				} catch (IOException e) {
					Log.e(TAG, "Could not create server socket", e);
					continue;
				}
				Socket socket;
				try {
					Log.d(TAG, "Waiting for connection!");
					socket = serverSocket.accept();
				} catch (IOException e) {
					Log.e(TAG, "Error getting client socket", e);
					continue;
				}
				DataOutputStream dataOutputStream;
				try {
					dataOutputStream = new DataOutputStream(
							socket.getOutputStream());
				} catch (IOException e) {
					Log.e(TAG, "Error getting outputstream", e);
					continue;
				}
				DataInputStream dataInputStream;
				try {
					dataInputStream = new DataInputStream(
							socket.getInputStream());
				} catch (IOException e) {
					Log.e(TAG, "Error getting inputstream", e);
					continue;
				}
				Log.d(TAG,
						"accepted new socket connection and created outputstream");
				openCamera();
				while (socket.isConnected()) {
					lock.lock();
					try {
						if (isPaused) {
							suspended.await();
							continue;
						}
						if (isExit) {
							break;
						}
					} catch (InterruptedException e) {
						e.printStackTrace();
						continue;
					} finally {
						lock.unlock();
					}
					Frame frame;
					try {
						frame = filledFrames.take();
					} catch (InterruptedException e) {
						Log.e(TAG, "Error getting filled frame", e);
						continue;
					}
					try {
						// Log.i(TAG, "Writing out uncompressed " +
						// frame.uncompressedSize + " compressed " +
						// frame.compressedSize + " of width " + preW +
						// " and height " + preH);
						dataOutputStream.writeInt(frame.uncompressedSize);
						dataOutputStream.writeInt(frame.compressedSize);
						dataOutputStream.writeInt(preW);
						dataOutputStream.writeInt(preH);
						dataOutputStream.writeBoolean(frame.compression);
						dataOutputStream.writeByte(robotData.getCollisions());
						if (frame.compression) {
							dataOutputStream.write(frame.data, 0,
									frame.compressedSize);
						} else {
							dataOutputStream.write(frame.data, 0,
									frame.uncompressedSize);
						}
						sent++;
					} catch (IOException e) {
						Log.e(TAG, "Error writing to output stream", e);
						break;
					} finally {
						if (compression && freeBuffers.isEmpty()) {
							freeBuffers.add(frame.data);
						} else {
							camera.addCallbackBuffer(frame.data);
						}
					}
					try {
						robotCommands.setDirection(RobotCommands.Directions
								.values()[dataInputStream.readInt()]);
					} catch (IOException e) {
						Log.e(TAG, "Error reading from inputstream", e);
						break;
					}
				}
				closeCamera();
				try {
					socket.close();
					serverSocket.close();
				} catch (IOException e) {
					Log.d(TAG, "Error closing socket");
				}
			}
		}
	}

	private static final int COMPRESSED_FRAME_SIZE = 500000;
	private static final int NUMBER_OF_BUFFERS = 5;
	private static final String TAG = SenderService.class.getCanonicalName();

	private final IBinder binder = new LocalBinder();
	private int bytesPerPixel;
	private Camera camera;
	private Deflater compresser;
	private boolean compression = false;

	private int dropped;
	private LinkedBlockingQueue<Frame> filledFrames = new LinkedBlockingQueue<Frame>();
	private LinkedBlockingQueue<byte[]> freeBuffers;
	private boolean isExit = false;

	private boolean isPaused = false;
	private final ReentrantLock lock = new ReentrantLock();
	private int maxFps;
	private int minFps;
	private int preH;
	private int preW;
	private final RobotCommands robotCommands = new RobotCommands();
	private RobotData robotData = new RobotData();
	private int sent;
	private Thread serverThread;
	private long startTime;
	private final Condition suspended = lock.newCondition();
	protected int frames;

	byte[][] buffers;

	Camera.PreviewCallback previewCallback = new PreviewCallbackImplementation();

	public String getLocalIpAddress() {
		try {
			for (Enumeration<NetworkInterface> en = NetworkInterface
					.getNetworkInterfaces(); en.hasMoreElements();) {
				NetworkInterface intf = en.nextElement();
				for (Enumeration<InetAddress> enumIpAddr = intf
						.getInetAddresses(); enumIpAddr.hasMoreElements();) {
					InetAddress inetAddress = enumIpAddr.nextElement();
					if (!inetAddress.isLoopbackAddress()) {
						return inetAddress.getHostAddress().toString();
					}
				}
			}
		} catch (SocketException e) {
			Log.e(TAG, "Could not get local IP", e);
		}
		Log.e(TAG, "Could not get local IP");
		return null;
	}

	public String getStatus() {
		return "Frame rate: " + frames * 1000
				/ (System.currentTimeMillis() - startTime) + " dropped "
				+ dropped + " sent " + sent + "\nminfps " + minFps + " maxfps "
				+ maxFps + "\nwidth " + preW + " height " + preH;
	}

	@Override
	public IBinder onBind(Intent intent) {
		Log.d(TAG, "onBind");
		changePauseState(false);
		return binder;
	}

	/** Called when the activity is first created. */

	@Override
	public void onCreate() {
		super.onCreate();
		changePauseState(false);
		compresser = new Deflater();
		compresser.setStrategy(Deflater.HUFFMAN_ONLY);
		if (freeBuffers == null) {
			freeBuffers = new LinkedBlockingQueue<byte[]>();
			for (int i = 0; i < NUMBER_OF_BUFFERS; i++) {
				freeBuffers.add(new byte[COMPRESSED_FRAME_SIZE]);
			}
		}
		if (serverThread == null) {
			serverThread = new Thread(new serverThreadRunnable());
			serverThread.start();
		}

	}

	@Override
	public void onDestroy() {
		Log.d(TAG, "onDestroy");
		super.onDestroy();
		lock.lock();
		try {
			isExit = true;
			suspended.signal();
		} finally {
			lock.unlock();
		}
	}

	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		return START_STICKY;
	}

	@Override
	public boolean onUnbind(Intent intent) {
		Log.d(TAG, "onUnbind");
		return super.onUnbind(intent);
	}

	public void send(RobotData robotData) {
		if (robotData == null) {
			Log.e(TAG, "Error, tried to send null RobotData object");
		}
		this.robotData.update(robotData);
	}

	private void changePauseState(boolean flag) {
		lock.lock();
		try {
			isPaused = flag;
			suspended.signal();
		} finally {
			lock.unlock();
		}
	}

	private void closeCamera() {
		lock.lock();
		try {
			if (camera != null) {
				camera.stopPreview();
				camera.setPreviewCallback(null);
				camera.release();
				camera = null;
			}
		} finally {
			lock.unlock();
		}
	}

	private void openCamera() {
		lock.lock();
		try {
			camera = Camera.open();
			Camera.Parameters parameters = camera.getParameters();

			int previewFpsRangeIndex = Camera.Parameters.PREVIEW_FPS_MIN_INDEX;
			/*
			 * SharedPreferences preferences =
			 * getSharedPreferences(ServerConstants.PREFS_STORE,
			 * MODE_WORLD_WRITEABLE); boolean use_high_fps =
			 * preferences.getBoolean(ServerConstants.USE_HIGH_FPS_PREF, true);
			 * if(use_high_fps) { previewFpsRangeIndex =
			 * Camera.Parameters.PREVIEW_FPS_MAX_INDEX-1; } else {
			 * previewFpsRangeIndex = Camera.Parameters.PREVIEW_FPS_MIN_INDEX;
			 * 
			 * }
			 */

			List<int[]> supportedPreviewFpsRange = parameters
					.getSupportedPreviewFpsRange();
			if(supportedPreviewFpsRange != null) {
				minFps = supportedPreviewFpsRange.get(previewFpsRangeIndex)[0];
				maxFps = supportedPreviewFpsRange.get(previewFpsRangeIndex)[1];
				parameters.setPreviewFpsRange(minFps, maxFps);
			} else {
				Log.e(TAG, "Supported Preview FPS Range returns null!");
			}

			List<Size> supportedPreviewSizes = parameters.getSupportedPreviewSizes();
			if(supportedPreviewSizes != null) {
				Size selectedSize = supportedPreviewSizes.get(0);
				for (Size size : supportedPreviewSizes) {
					Log.d(TAG, "Supported camera size " + size);
					if (size.width < selectedSize.width)
						selectedSize = size;
				}
				preW = selectedSize.width;
				preH = selectedSize.height;
				parameters.setPreviewSize(preW, preH);
			} else {
				Log.e(TAG, "Supported Preview sizes returns null!");
			}

			camera.setParameters(parameters);
			bytesPerPixel = 4;
			for (byte[] buffer : freeBuffers) {
				camera.addCallbackBuffer(buffer);
			}
			camera.setPreviewCallbackWithBuffer(previewCallback);
			// camera.setPreviewCallback(previewCallback);
			camera.startPreview();
			startTime = System.currentTimeMillis();
			sent = 0;
			dropped = 0;
			frames = 0;
		} finally {
			lock.unlock();
		}
	}

	public RobotCommands getRobotCommands() {
		return robotCommands;
	}
}