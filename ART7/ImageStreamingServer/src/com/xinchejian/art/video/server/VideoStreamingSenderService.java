package com.xinchejian.art.video.server;

import java.io.DataOutputStream;
import java.io.IOException;
import java.io.OutputStream;
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
import android.hardware.Camera;
import android.hardware.Camera.Size;
import android.os.Binder;
import android.os.IBinder;
import android.util.Log;

public class VideoStreamingSenderService extends Service {
	private static final String TAG = VideoStreamingSenderService.class.getCanonicalName();
	private final ReentrantLock lock = new ReentrantLock();
	private final Condition suspended = lock.newCondition();
	private boolean isPaused = false;
	private boolean isExit = false;
	private int sent;

	private Camera camera;
	protected int frames;
	private long startTime;
	private Deflater compresser;
	private final class PreviewCallbackImplementation implements
			Camera.PreviewCallback {
		public void onPreviewFrame(byte[] previewFrameBytes, Camera camera) {
			try {
				if (camera == null) {
					return;
				}
				if(!freeFrames.isEmpty()) {
					Frame frame;
					frame = freeFrames.take();
					compresser.reset();
					compresser.setInput(previewFrameBytes);
					compresser.finish();
					frame.compressedSize = compresser.deflate(frame.data);
					frame.uncompressedSize = previewFrameBytes.length;
					filledFrames.put(frame);
					frames++;
				} else {
					dropped++;
				}
			} catch (InterruptedException e) {
				e.printStackTrace();
			} 
		}
	}
	private final class serverThreadRunnable implements Runnable {
		@Override
		public void run() {
			ServerSocket serverSocket;
			try {
				serverSocket = new ServerSocket();
				SocketAddress address = new InetSocketAddress(getLocalIpAddress(), 8888);
				serverSocket.bind(address);
			} catch (IOException e) {
				Log.e(TAG, "Could not create server socket", e);
				return;
			}
			while (!isExit) {
				Socket socket;
				try {
					Log.d(TAG, "Waiting for connection!");
					socket = serverSocket.accept();
				} catch (IOException e) {
					Log.e(TAG, "Error getting client socket", e);
					return;
				}
				DataOutputStream dataOutputStream;
				try {
					OutputStream outputStream = socket.getOutputStream();
					dataOutputStream = new DataOutputStream(outputStream);
				} catch (IOException e) {
					Log.e(TAG, "Error getting outputstream", e);
					return;
				}
				Log.d(TAG, "accepted new socket connection and created outputstream");
				while (socket.isConnected()) {
					lock.lock();
					try {
						if(isPaused) {
							suspended.await();
							continue;
						}
						if(isExit) {
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
						Log.i(TAG, "Writing out uncompressed " + frame.uncompressedSize + " compressed " + frame.compressedSize + " of width " + preW + " and height " + preH);
						dataOutputStream.writeInt(frame.uncompressedSize);
						dataOutputStream.writeInt(frame.compressedSize);
						dataOutputStream.writeInt(preW);
						dataOutputStream.writeInt(preH);
						dataOutputStream.write(frame.data, 0, frame.compressedSize);
						sent++;
					} catch (IOException e) {
						Log.e(TAG, "Error writing to output stream", e);
						break;
					} finally {
						freeFrames.add(frame);
					}
				}
				try {
					socket.close();
				} catch (IOException e) {
					Log.d(TAG, "Error closing socket");
				}
			}
		}
	}
	private class Frame {
		public Frame() {
			uncompressedSize = 0;
			compressedSize = 0;
		}
		byte[] data;
		int uncompressedSize;
		int compressedSize;
	}
	private LinkedBlockingQueue<Frame> freeFrames;
	private LinkedBlockingQueue<Frame> filledFrames = new LinkedBlockingQueue<Frame>();
	private int preH;
	private int preW;
	private Thread serverThread;
	private static final int NUMBER_OF_BUFFERS = 5;
	private static final int COMPRESSED_FRAME_SIZE = 500000;
	byte[][] buffers;
	private int bytesPerPixel;
	private int dropped;

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
		closeCamera();
	}

	@Override
	public boolean onUnbind(Intent intent) {
		Log.d(TAG, "onUnbind");
		return super.onUnbind(intent);
	}

	public class LocalBinder extends Binder {
		public VideoStreamingSenderService getService() {
			// Return this instance of LocalService so clients can call public
			// methods
			return VideoStreamingSenderService.this;
		}
	}
	private final IBinder binder = new LocalBinder();
	
	@Override
	public IBinder onBind(Intent intent) {
		Log.d(TAG, "onBind");
		changePauseState(false);
		return binder;
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

	Camera.PreviewCallback previewCallback = new PreviewCallbackImplementation();
	private int minFps;
	private int maxFps;

	/** Called when the activity is first created. */

	@Override
	public void onCreate() {
		super.onCreate();
		changePauseState(false);
		compresser = new Deflater();
		compresser.setStrategy(Deflater.HUFFMAN_ONLY);
		if(freeFrames == null) {
			freeFrames = new LinkedBlockingQueue<Frame>();
			for (int i = 0; i < NUMBER_OF_BUFFERS; i++) {
				Frame frame = new Frame();
				frame.data = new byte[COMPRESSED_FRAME_SIZE];
				freeFrames.add(frame);
			}
		}
		if(serverThread == null) {
			serverThread = new Thread(new serverThreadRunnable());
			serverThread.start();
		}
		openCamera();
	
	}

	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		return START_STICKY;
	}

	private void openCamera() {
		lock.lock();
		try {
			camera = Camera.open();
			Camera.Parameters parameters = camera.getParameters();

			List<int[]> supportedPreviewFpsRange = parameters.getSupportedPreviewFpsRange();
			minFps = supportedPreviewFpsRange.get(Camera.Parameters.PREVIEW_FPS_MIN_INDEX)[0];
			maxFps = supportedPreviewFpsRange.get(Camera.Parameters.PREVIEW_FPS_MIN_INDEX)[1];
			List<Size> supportedPreviewSizes = parameters.getSupportedPreviewSizes();
			Size selectedSize = supportedPreviewSizes.get(0);
			for(Size size : supportedPreviewSizes) {
				if(size.width < selectedSize.width) 
					selectedSize = size;
			}
			parameters.setPreviewSize(selectedSize.width, selectedSize.height);
			
			parameters.setPreviewFpsRange(minFps, maxFps);
			preH = parameters.getPreviewSize().height;
			preW = parameters.getPreviewSize().width;
			camera.setParameters(parameters);
			bytesPerPixel = 4;
			if (buffers == null) {
				int frameSize = preH * preW * bytesPerPixel;
				Log.d(TAG, "Frame size is " + frameSize);
				// buffers = new byte[NUMBER_OF_BUFFERS][frameSize];
			}

			// camera.setPreviewCallbackWithBuffer(previewCallback);
			camera.setPreviewCallback(previewCallback);
			camera.startPreview();
			startTime = System.currentTimeMillis();
			sent = 0;
			dropped = 0;
			frames = 0;
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
				/ (System.currentTimeMillis() - startTime) 
				+ " dropped " + dropped
				+ " sent " + sent
				+ "\nminfps " + minFps
				+ " maxfps " + maxFps
				+ "\nwidth " + preW 
				+ " height " + preH;
	}
}