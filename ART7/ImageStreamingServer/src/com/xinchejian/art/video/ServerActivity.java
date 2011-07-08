package com.xinchejian.art.video;

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
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.ReentrantLock;
import java.util.zip.Deflater;

import android.app.Activity;
import android.hardware.Camera;
import android.os.Bundle;
import android.util.Log;
import android.view.Surface;
import android.widget.TextView;

public class ServerActivity extends Activity {
	private final ReentrantLock lock = new ReentrantLock();
	private final Condition suspended = lock.newCondition();
	private boolean isPaused = false;
	private boolean isExit = false;

	@Override
	protected void onDestroy() {
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
	protected void onPause() {
		Log.d(TAG, "onPause");
		super.onPause();
		lock.lock();
		try {
			isPaused = true;
		} finally {
			lock.unlock();
		}
		closeCamera();
	}

	@Override
	protected void onResume() {
		super.onResume();
		openCamera();
		lock.lock();
		try {
			isPaused = false;
			suspended.signal();
		} finally {
			lock.unlock();
		}
	}

	protected static final String TAG = ServerActivity.class.getCanonicalName();
	private TextView status;
	private Camera camera;
	protected int fps;
	protected long startTime;
	private Deflater compresser;
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
	private static final int NUMBER_OF_BUFFERS = 3;
	private static final int COMPRESSED_FRAME_SIZE = 1000000;
	byte[][] buffers;
	private int bytesPerPixel;
	Camera.PreviewCallback previewCallback = new Camera.PreviewCallback() {

		public void onPreviewFrame(byte[] previewFrameBytes, Camera camera) {
			lock.lock();
			try {
				if (camera == null) {
					return;
				}
				Frame frame;
				if(freeFrames.isEmpty()) {
					frame = filledFrames.take();
				} else {
					frame = freeFrames.take();
				}
				compresser.reset();
				compresser.setInput(previewFrameBytes);
				compresser.finish();
				frame.compressedSize = compresser.deflate(frame.data);
				frame.uncompressedSize = previewFrameBytes.length;
				filledFrames.put(frame);

				status.setText("Frame rate: " + fps++ * 1000
						/ (System.currentTimeMillis() - startTime));
			} catch (InterruptedException e) {
				e.printStackTrace();
			} finally {
				lock.unlock();
			}
		}

	};

	/** Called when the activity is first created. */

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		compresser = new Deflater();
		if(freeFrames == null) {
			freeFrames = new LinkedBlockingQueue<Frame>();
			for (int i = 0; i < NUMBER_OF_BUFFERS; i++) {
				Frame frame = new Frame();
				frame.data = new byte[COMPRESSED_FRAME_SIZE];
				freeFrames.add(frame);
			}
		}
		setContentView(R.layout.main);
		status = (TextView) findViewById(R.id.textView1);

		serverThread = new Thread(new Runnable() {

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
						Frame data;
						try {
							data = filledFrames.take();
						} catch (InterruptedException e) {
							Log.e(TAG, "Error getting filled frame", e);
							continue;
						}
						try {
							Log.i(TAG, "Writing out uncompressed " + data.uncompressedSize + " compressed " + data.compressedSize + " of width " + preW + " and height " + preH);
							dataOutputStream.writeInt(data.uncompressedSize);
							dataOutputStream.writeInt(data.compressedSize);
							dataOutputStream.writeInt(preW);
							dataOutputStream.writeInt(preH);
							dataOutputStream.write(data.data, 0, data.compressedSize);
						} catch (IOException e) {
							Log.e(TAG, "Error writing to output stream", e);
							break;
						} finally {
							freeFrames.add(data);
						}
					}
					try {
						socket.close();
					} catch (IOException e) {
						Log.d(TAG, "Error closing socket");
					}
				}
			}
		});
		serverThread.start();
	
	}

	private void openCamera() {
		lock.lock();

		try {
			camera = Camera.open();
			Camera.Parameters parameters = camera.getParameters();
			preH = parameters.getPreviewSize().height;
			preW = parameters.getPreviewSize().width;
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
		} finally {
			lock.unlock();
		}
	}

	public void setCameraDisplayOrientation() {
		android.hardware.Camera.CameraInfo info = new android.hardware.Camera.CameraInfo();
		android.hardware.Camera.getCameraInfo(0, info);
		int rotation = getWindowManager().getDefaultDisplay().getRotation();
		int degrees = 0;
		switch (rotation) {
		case Surface.ROTATION_0:
			degrees = 0;
			break;
		case Surface.ROTATION_90:
			degrees = 90;
			break;
		case Surface.ROTATION_180:
			degrees = 180;
			break;
		case Surface.ROTATION_270:
			degrees = 270;
			break;
		}

		int result;
		if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
			result = (info.orientation + degrees) % 360;
			result = (360 - result) % 360; // compensate the mirror
		} else { // back-facing
			result = (info.orientation - degrees + 360) % 360;
		}
		camera.setDisplayOrientation(result);
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
}