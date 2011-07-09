package com.xinchejian.art.video.client;


import java.io.DataInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.SocketException;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.ReentrantLock;
import java.util.zip.InflaterInputStream;

import android.app.Service;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Bitmap.Config;
import android.os.Binder;
import android.os.IBinder;
import android.util.Log;
import android.widget.Toast;

public class VideoStreamingReceiverService extends Service {
	@Override
	public void onRebind(Intent intent) {
		super.onRebind(intent);
		mutatePause(false);
	}

	@Override
	public void onStart(Intent intent, int startId) {
		super.onStart(intent, startId);
		mutatePause(false);
	}

	private static final String TAG = VideoStreamingReceiverService.class.getName();
	// Binder given to clients
	private final IBinder binder = new LocalBinder();
	private final ReentrantLock lock = new ReentrantLock();
	private final Condition suspended = lock.newCondition();
	private volatile boolean isPaused = false;
	private volatile boolean isExit = false;
	private Thread clientThread;
	private byte[] buffer;
	private int[] secondaryBuffer;
	private LinkedBlockingQueue<Bitmap> bitmaps = new LinkedBlockingQueue<Bitmap>(5);

	private Runnable clientThreadRunnable = new Runnable() {
		
		@Override
		public void run() {
			while (!isExit) {
				Socket socket = new Socket();
		
				try {
					socket.connect( new InetSocketAddress("10.0.0.17", 8888), 10000);
				} catch (IOException e) {
					Log.e(TAG, "Error getting client socket", e);
					try {
						Thread.sleep(5000);
					} catch (InterruptedException e1) {
						// TODO Auto-generated catch block
						e1.printStackTrace();
					}
					continue;
				}
				if(!socket.isConnected()) {
					continue;
				}
				DataInputStream dataInputStream;
				try {
					InputStream inputStream = socket.getInputStream();
					dataInputStream = new DataInputStream(inputStream);
				} catch (IOException e) {
					Log.e(TAG, "Error getting input stream", e);
					return;
				}
				Log.d(TAG, "Client connected to server");
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
					int uncompressed;
					int compressed;
					int width;
					int height;
					try {
						socket.setSoTimeout(5000);
					} catch (SocketException e) {
						Log.d(TAG, "could not set socket timeout", e);
					}							
					try {
						uncompressed = dataInputStream.readInt();
						compressed = dataInputStream.readInt();
						width = dataInputStream.readInt();
						height = dataInputStream.readInt();
					} catch (IOException e) {
						Log.e(TAG, "Error reading header information", e);
						break;
					} 
					
					Log.i(TAG, "Receiving uncompressed " + uncompressed + " compressed " + compressed + " of width " + width + " and height " + height);
					if(uncompressed > buffer.length || uncompressed <= 0) {
						Log.e(TAG, "Buffer is too small or invalid for uncompressed data " + buffer.length);
						break;
					}
					if(width > 1024 || height > 768) {
						Log.e(TAG, "Invalid image size");
						break;
					}
					InflaterInputStream inflater = new InflaterInputStream(dataInputStream);
					try {
						int read = 0;
						while(read != uncompressed) {
							read += inflater.read(buffer, read, uncompressed - read);
						}
					} catch (IOException e) {
						Log.e(TAG, "Failed reading stream!");
						break;
					} catch(RuntimeException e) {
						Log.e(TAG, "Error inflating data", e);
						break;
					}
					try {
						Bitmap processImage = processImage(buffer, uncompressed, width, height);
						if(bitmaps.remainingCapacity() > 0) {
							bitmaps.put(processImage);
						}
					} catch (InterruptedException e) {
						e.printStackTrace();
					} catch(IllegalArgumentException e) {
						Log.e(TAG, "Error processing image");
						break;
					}
				}
				try {
					socket.close();
				} catch (IOException e) {
					Log.d(TAG, "Error closing socket");
				}
			}
		}


		private Bitmap processImage(byte[] buffer, int uncompressed, int width, int height) {
			decodeYUV420SP(secondaryBuffer, buffer, width, height);
			return Bitmap.createBitmap(secondaryBuffer, width, height, Config.ARGB_8888);
		}
	};
	/**
	 * Class used for the client Binder. Because we know this service always
	 * runs in the same process as its clients, we don't need to deal with IPC.
	 */
	public class LocalBinder extends Binder {
		public VideoStreamingReceiverService getService() {
			// Return this instance of LocalService so clients can call public
			// methods
			return VideoStreamingReceiverService.this;
		}
	}


	@Override
	public IBinder onBind(Intent intent) {
		Toast.makeText(getApplicationContext(), "binding", Toast.LENGTH_SHORT)
				.show();
		mutatePause(false);
		return binder;
	}

	private void mutatePause(boolean flag) {
		lock.lock();
		try {
			isPaused = flag;
			suspended.signal();
		} finally {
			lock.unlock();
		}
	}

	@Override
	public void onCreate() {
		super.onCreate();
		Log.d(TAG, "onCreate");
		buffer = new byte[1000000];
		secondaryBuffer = new int[1000000];
        if(clientThread == null) {
			clientThread = new Thread(clientThreadRunnable);
			clientThread.start();
        }
		mutatePause(false);
		mutateExit(false);
	}


	@Override
	public int onStartCommand(Intent intent, int startId, int i) {
		Log.d(TAG, "onStartCommand");
		return super.onStartCommand(intent, startId, i);
	}
	
	@Override
	public void onDestroy() {
		super.onDestroy();
		Log.d(TAG, "onDestroy");	
		mutateExit(true);
	}

	private void mutateExit(boolean flag) {
		lock.lock();
		try {
			isExit = flag;
			suspended.signal();
		} finally {
			lock.unlock();
		}
	}

	// services exposed...

	@Override
	public void onLowMemory() {
		super.onLowMemory();
		Log.d(TAG, "onLowMemory");		
	}

	@Override
	public boolean onUnbind(Intent intent) {
		mutatePause(true);
		return super.onUnbind(intent);
	}

	static public void decodeYUV420SP(int[] rgb, byte[] yuv420sp, int width,
			int height) {
		final int frameSize = width * height;

		for (int j = 0, yp = 0; j < height; j++) {
			int uvp = frameSize + (j >> 1) * width, u = 0, v = 0;
			for (int i = 0; i < width; i++, yp++) {
				int y = (0xff & ((int) yuv420sp[yp])) - 16;
				if (y < 0)
					y = 0;
				if ((i & 1) == 0) {
					v = (0xff & yuv420sp[uvp++]) - 128;
					u = (0xff & yuv420sp[uvp++]) - 128;
				}
				int y1192 = 1192 * y;
				int r = (y1192 + 1634 * v);
				int g = (y1192 - 833 * v - 400 * u);
				int b = (y1192 + 2066 * u);

				if (r < 0)
					r = 0;
				else if (r > 262143)
					r = 262143;
				if (g < 0)
					g = 0;
				else if (g > 262143)
					g = 262143;
				if (b < 0)
					b = 0;
				else if (b > 262143)
					b = 262143;

				rgb[yp] = 0xff000000 | ((r << 6) & 0xff0000)
						| ((g >> 2) & 0xff00) | ((b >> 10) & 0xff);
			}
		}
	}    

	public Bitmap getNextBitmap() {
		if(bitmaps.isEmpty())
			return null;
		try {
			return bitmaps.take();
		} catch (InterruptedException e) {
			return null;
		}
	}
}
