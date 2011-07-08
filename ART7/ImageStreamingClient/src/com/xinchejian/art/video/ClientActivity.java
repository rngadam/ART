package com.xinchejian.art.video;

import java.io.DataInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.NetworkInterface;
import java.net.Socket;
import java.net.SocketException;
import java.util.Enumeration;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.ReentrantLock;
import java.util.zip.InflaterInputStream;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.Bitmap.Config;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.widget.ImageView;

public class ClientActivity extends Activity {
    protected static final String TAG = ClientActivity.class.getCanonicalName();
	private ImageView imageView;
	private final ReentrantLock lock = new ReentrantLock();
	private final Condition suspended = lock.newCondition();
	private boolean isPaused = false;
	private boolean isExit = false;
	private Thread clientThread;
	private byte[] buffer;
	private Handler imageUpdaterHandler = new Handler();
	private LinkedBlockingQueue<Bitmap> bitmaps = new LinkedBlockingQueue<Bitmap>();
	
	/** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
		buffer = new byte[3000000];
        imageView = (ImageView) findViewById(R.id.imageView1);
		clientThread = new Thread(new Runnable() {

			@Override
			public void run() {
				while (!isExit) {
					Socket socket = new Socket();
					try {
						socket.connect( new InetSocketAddress("10.0.0.23", 8888));
					} catch (IOException e) {
						Log.e(TAG, "Error getting client socket", e);
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
							uncompressed = dataInputStream.readInt();
							compressed = dataInputStream.readInt();
							width = dataInputStream.readInt();
							height = dataInputStream.readInt();
						} catch (IOException e) {
							Log.e(TAG, "Error reading header information", e);
							break;
						}
						
						Log.i(TAG, "Receiving uncompressed " + uncompressed + " compressed " + compressed + " of width " + width + " and height " + height);
						if(uncompressed > buffer.length) {
							Log.d(TAG, "Buffer is too small for uncompressed data " + buffer.length);
							break;
						}
						InflaterInputStream inflater = new InflaterInputStream(dataInputStream);
						try {
							
							inflater.read(buffer, 0, uncompressed);
						} catch (IOException e) {
							Log.e(TAG, "Failed reading stream!");
							break;
						} catch(RuntimeException e) {
							Log.e(TAG, "Error inflating data", e);
							break;
						}
						try {
							bitmaps.put(processImage(buffer, uncompressed, width, height));
						} catch (InterruptedException e) {
							e.printStackTrace();
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
				int[] output = new int[buffer.length];
				decodeYUV420SP(output, buffer, width, height);
				return Bitmap.createBitmap(output, width, height, Config.ARGB_8888);
			}
		});
		clientThread.start();

		imageUpdaterHandler.postDelayed(imageUpdaterRunnable, 1000);
    }
    
Runnable imageUpdaterRunnable = new Runnable() {
	@Override
	public void run() {
		if(!bitmaps.isEmpty()) {
			try {
				imageView.setImageBitmap(bitmaps.take());
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}
		imageUpdaterHandler.postDelayed(imageUpdaterRunnable, 200);
	}
};
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