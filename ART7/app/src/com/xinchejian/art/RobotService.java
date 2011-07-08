package com.xinchejian.art;


import java.io.FileDescriptor;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.Enumeration;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Binder;
import android.os.IBinder;
import android.os.ParcelFileDescriptor;
import android.util.Log;
import android.widget.Toast;

import com.android.future.usb.UsbAccessory;
import com.android.future.usb.UsbManager;

public class RobotService extends Service {
	private static final String TAG = RobotService.class.getName();
	private static final String ACTION_USB_PERMISSION = "com.xinchejian.art.action.USB_PERMISSION";
	public static final String ROBOT_UPDATE = "com.xinchejian.art.ROBOT_UPDATE";
	public static final String ROBOT_UPDATE_COLLISIONS = null;
	
	public static final byte FORWARD_RIGHT_INFRARED = 1;
	public static final byte FORWARD_LEFT_INFRARED = 1<<1;
	public static final byte LEFT_INFRARED = 1<<2;
	public static final byte RIGHT_INFRARED = 1<<3;
	public static final byte BACKWARD_INFRARED = 1<<4;
	public static final byte FORWARD_INFRARED = 1<<5;
	
	public static enum directions {
		NEUTRAL,
		FORWARD_LEFT,
		FORWARD,
		FORWARD_RIGHT,
		REVERSE_LEFT,
		REVERSE,
		REVERSE_RIGHT
	};


	private int messagesReceived;
	private FileInputStream inputStream;
	private FileOutputStream outputStream;
	private UsbManager usbManager;	
	private ParcelFileDescriptor fileDescriptor;
	private PendingIntent permissionIntent;
	
	private final Lock lock = new ReentrantLock();
	private final Condition permissionGiven  = lock.newCondition(); 
	private final Condition clientBinded  = lock.newCondition(); 
	private final Condition usbAttached = lock.newCondition();
	private boolean isPermissionGiven = false;
	private boolean isClientBinded = false;
	private boolean isUsbAttached = false;
	
	private boolean isThreadRunning = false;

	private states currentState = states.STARTING_THREAD;
	private directions nextDirection = directions.NEUTRAL;
	
	// Binder given to clients
	private final IBinder binder = new LocalBinder();
	private BlockingQueue<byte[]> sendQueue = new LinkedBlockingQueue<byte[]>();
	private Thread backgroundThread;
	private UsbAccessory accessory;
	
	/**
	 * Class used for the client Binder. Because we know this service always
	 * runs in the same process as its clients, we don't need to deal with IPC.
	 */
	public class LocalBinder extends Binder {
		public RobotService getService() {
			// Return this instance of LocalService so clients can call public
			// methods
			return RobotService.this;
		}
	}

	private static enum states {
		STARTING_THREAD,
		WAITING_FOR_USB_ATTACHED,
		WAITING_FOR_ACCESSORY,
		WAITING_FOR_PERMISSION,
		WAITING_FOR_CLIENT_BIND, 
		WAITING_FOR_OPENED_ACCESSORY, 
		PROCESSING,
		WAITING_FOR_CLOSED_ACCESSORY, WAITING_FOR_RESET, 
	};
	
	private Runnable backgroundProcessing = new Runnable() {
		private int stateChangeCount;
		private long lastCheckStateChangeCount;

		public void run() {
			isThreadRunning = true;

			usbManager = UsbManager.getInstance(RobotService.this);
			while(isThreadRunning) {
				states beforeLoopState = currentState;
				lock.lock();
				try {
					switch(currentState) {
					case STARTING_THREAD:
						currentState = states.WAITING_FOR_ACCESSORY;
						break;
					case WAITING_FOR_ACCESSORY:
						UsbAccessory[] accessories = usbManager.getAccessoryList();
						accessory = (accessories == null ? null : accessories[0]);
						if(accessory != null) {
							isUsbAttached = true;
							if(usbManager.hasPermission(accessory)) {
								currentState = states.WAITING_FOR_CLIENT_BIND;								
							} else {
								permissionIntent = PendingIntent.getBroadcast(RobotService.this, 0, new Intent(
										ACTION_USB_PERMISSION), 0);
								usbManager.requestPermission(accessory, permissionIntent);							
								currentState = states.WAITING_FOR_PERMISSION;
							}
						} else {
							isUsbAttached = false;
							currentState = states.WAITING_FOR_USB_ATTACHED;
						}
						break;
					case WAITING_FOR_USB_ATTACHED:
						if(isUsbAttached) {
							currentState = states.WAITING_FOR_PERMISSION;
						} else {
							usbAttached.await();
						}
						break;
					case WAITING_FOR_PERMISSION:
						if(!isUsbAttached) {
							currentState = states.WAITING_FOR_CLOSED_ACCESSORY;
						}
						if(isPermissionGiven) {
							currentState = states.WAITING_FOR_CLIENT_BIND;
						} else {
							permissionGiven.await();
						}
						break;
					case WAITING_FOR_CLIENT_BIND:
						if(!isUsbAttached) {
							currentState = states.WAITING_FOR_CLOSED_ACCESSORY;
						}						
						if(isClientBinded) {
							currentState = states.WAITING_FOR_OPENED_ACCESSORY;
						} else {
							clientBinded.await();
						}
						break;
					case WAITING_FOR_OPENED_ACCESSORY:
						if(!isUsbAttached) {
							currentState = states.WAITING_FOR_CLOSED_ACCESSORY;
						}						
						if(openAccessory(accessory)) {
							currentState = states.PROCESSING;
						} else {
							currentState = states.WAITING_FOR_ACCESSORY;
						}
						break;
					case PROCESSING:
						if(!isUsbAttached) {
							currentState = states.WAITING_FOR_CLOSED_ACCESSORY;
						}						
						if(!isClientBinded) {
							currentState = states.WAITING_FOR_CLOSED_ACCESSORY;
						}
						break;
					case WAITING_FOR_CLOSED_ACCESSORY:
						closeAccessory();
						currentState = states.WAITING_FOR_ACCESSORY;
						break;
					case WAITING_FOR_RESET:
						if(!isUsbAttached) {
							currentState = states.WAITING_FOR_ACCESSORY;
						} else {
							usbAttached.await();
						}						
						break;
					}	
				} catch (InterruptedException e) {
					e.printStackTrace();
				} finally {
					lock.unlock();
				}
				// need to this outside the lock as the read is blocking...
				if(currentState.equals(states.PROCESSING) && !process()) {
					currentState = states.WAITING_FOR_ACCESSORY;
				}
				
				if(!beforeLoopState.equals(currentState)) {
					stateChangeCount++;
					if((System.currentTimeMillis() - lastCheckStateChangeCount) > 5000) {
						if(stateChangeCount > 10) {
							Log.e(TAG, "Max change count reached, waiting for reset");
							currentState = states.WAITING_FOR_RESET;
						}
						stateChangeCount = 0;
						lastCheckStateChangeCount = System.currentTimeMillis();
					}
					Log.d(TAG, "Going from state " + beforeLoopState.name() + " to " + currentState.name());
				}
			} // while(isThreadRunning()
			unregisterReceiver(usbReceiver);
		}

		private boolean process() {
			int ret = 0;
			byte[] buffer = new byte[16384];
			int i;
			while (ret >= 0) {
				try {
					if(inputStream.available() != 0) {
						Log.d(TAG, "Starting blocking read");
						ret = inputStream.read(buffer);
					}
				} catch (IOException e) {
					Log.e(TAG, "Could not read from input stream", e);
					return false;
				}

				i = 0;
				while (i < ret) {
					int len = ret - i;
					switch (buffer[i]) {
						case 0x1:
							if (len >= 2) {
								Log.d(TAG, "Read: " + buffer[i + 1]);
								Intent intent = new Intent(ROBOT_UPDATE);
								intent.putExtra(ROBOT_UPDATE_COLLISIONS, buffer[i + 1]);
					            sendBroadcast(intent);
							}
							i += 2;
							messagesReceived++;
							break;
					}
				}
			}
			return sendCommand((byte)nextDirection.ordinal(), (byte)100, 0);
		}
	};


	@Override
	public IBinder onBind(Intent intent) {
		Toast.makeText(getApplicationContext(), "binding", Toast.LENGTH_SHORT)
				.show();
		lock.lock();
		try {
			isClientBinded = true;
			clientBinded.signal();
		} finally {
			lock.unlock();
		}
		return binder;
	}

	@Override
	public void onCreate() {
		super.onCreate();
		Log.d(TAG, "onCreate");
		usbManager = UsbManager.getInstance(this);
		setupUsbReceiver();
		startBackgroundThread();
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
		isThreadRunning = false;
	}

	// services exposed...

	@Override
	public void onLowMemory() {
		super.onLowMemory();
		Log.d(TAG, "onLowMemory");		
	}


	private void startBackgroundThread() {
		if(backgroundThread == null || !backgroundThread.isAlive()) {
			backgroundThread = new Thread(null, backgroundProcessing, "Robot Background Processing");
			backgroundThread.start();
		}
	}

	private void setupUsbReceiver() {
		Log.d(TAG, "Registering listener");
		IntentFilter filter = new IntentFilter(ACTION_USB_PERMISSION);
		filter.addAction(UsbManager.ACTION_USB_ACCESSORY_DETACHED);
		filter.addAction(UsbManager.ACTION_USB_ACCESSORY_ATTACHED);
		registerReceiver(usbReceiver, filter);
	}

	@Override
	public boolean onUnbind(Intent intent) {
		lock.lock();
		try {
			isClientBinded = false;
			clientBinded.signal();
		} finally {
			lock.unlock();
		}
		return super.onUnbind(intent);
	}

	private final BroadcastReceiver usbReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			String action = intent.getAction();
			accessory = UsbManager.getAccessory(intent);
			if (ACTION_USB_PERMISSION.equals(action)) {
				Log.d(TAG, "USB Permission received");
				lock.lock();
				try {
					isPermissionGiven = intent.getBooleanExtra(
							UsbManager.EXTRA_PERMISSION_GRANTED, false);
					permissionGiven.signal();
				} finally {
					lock.unlock();
				}
			} else if(UsbManager.ACTION_USB_ACCESSORY_ATTACHED.equals(action)) {
				Log.d(TAG, "USB Attached received");				
				lock.lock();
				try {
					isUsbAttached = true;
					usbAttached.signal();
				} finally {
					lock.unlock();			
				}
			} else if (UsbManager.ACTION_USB_ACCESSORY_DETACHED.equals(action)) {
				Log.d(TAG, "USB Detached received");					
				lock.lock();
				try {
					isUsbAttached = false;
					usbAttached.signal();
					closeAccessory();
				} finally {
					lock.unlock();			
				}
				Log.d(TAG, "USB Detached handling completed");	
			} else {
				Log.d(TAG, "Unhandled onReceive action " + action);
			}
		}
	};

	
	private void closeAccessory() {
		try {
			if(inputStream != null) {
				inputStream.close();
			}
			if(outputStream != null) {
				outputStream.close();
			}
			if (fileDescriptor != null) {
				fileDescriptor.close();
			}
		} catch (IOException e) {
			Log.w(TAG, "Error closing accessory ", e);
		} finally {
			fileDescriptor = null;
			accessory = null;
		}
	}
	
	private boolean openAccessory(UsbAccessory accessory) {
		if(accessory == null) {
			Log.e(TAG, "Null accessory");
			return false;
		}
		if(usbManager == null) {
			Log.e(TAG, "USB Manager not running - are you connected?");
			return false;
		}
		try {
			fileDescriptor = usbManager.openAccessory(accessory);
			if (fileDescriptor != null) {
				FileDescriptor fd = fileDescriptor.getFileDescriptor();
				inputStream = new FileInputStream(fd);
				outputStream = new FileOutputStream(fd);
				Log.d(TAG, "accessory opened");
				return true;
			} else {
				Log.e(TAG, "accessory open failed to return a file descriptor");
				return false;
			}
		} catch(IllegalArgumentException e) {
			Log.e(TAG, "accessory open failed on bad accessory", e);
			return false;
			
		}
	}
	
	private boolean sendCommand(byte command, byte target, int value) {
		Log.d(TAG, "Sending command " + command);
		byte[] buffer = new byte[3];
		if (value > 255)
			value = 255;

		buffer[0] = command;
		buffer[1] = target;
		buffer[2] = (byte) value;
		if (outputStream != null && buffer[1] != -1) {
			try {
				outputStream.write(buffer);
			} catch (IOException e) {
				Log.e(TAG, "write failed", e);
				return false;
			}
		} else {
			return false;
		}
		return true;
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

	public boolean isThreadRunning() {
		return isThreadRunning;
	}

	public int getMessagesReceived() {
		return messagesReceived;
	}

	public int getCurrentState() {
		return currentState.ordinal();
	}

	public void go(directions direction) {
		nextDirection = direction;
	}

	public String getCurrentStateName() {
		// TODO Auto-generated method stub
		return currentState.name();
	}	
}
