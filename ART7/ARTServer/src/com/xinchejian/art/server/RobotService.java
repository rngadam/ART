package com.xinchejian.art.server;

import java.io.FileDescriptor;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.Enumeration;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.os.Binder;
import android.os.IBinder;
import android.os.ParcelFileDescriptor;
import android.util.Log;
import android.widget.Toast;

import com.android.future.usb.UsbAccessory;
import com.android.future.usb.UsbManager;
import com.xinchejian.art.robot.RobotCommands;
import com.xinchejian.art.robot.RobotData;
import com.xinchejian.art.robot.RobotData.RobotSensors;

public class RobotService extends Service {
	@Override
	public void onRebind(Intent intent) {
		super.onRebind(intent);
		mutateClientBindedState(true);
	}

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
		PROCESSING, STARTING_THREAD, WAITING_FOR_ACCESSORY, WAITING_FOR_CLIENT_BIND, WAITING_FOR_CLOSED_ACCESSORY, WAITING_FOR_OPENED_ACCESSORY, WAITING_FOR_PERMISSION, WAITING_FOR_RESET, WAITING_FOR_USB_ATTACHED,
	}

	private static final String ACTION_USB_PERMISSION = "com.xinchejian.art.action.USB_PERMISSION";

	private static final String TAG = RobotService.class.getName();
	private UsbAccessory accessory;
	private Runnable backgroundProcessing = new Runnable() {
		private long lastCheckStateChangeCount;
		private int stateChangeCount;

		public void run() {
			isThreadRunning = true;

			usbManager = UsbManager.getInstance(RobotService.this);
			while (isThreadRunning) {
				states beforeLoopState = currentState;
				lock.lock();
				try {
					switch (currentState) {
					case STARTING_THREAD:
						currentState = states.WAITING_FOR_ACCESSORY;
						break;
					case WAITING_FOR_ACCESSORY:
						UsbAccessory[] accessories = usbManager
								.getAccessoryList();
						accessory = (accessories == null ? null
								: accessories[0]);
						if (accessory != null) {
							if (usbManager.hasPermission(accessory)) {
								currentState = states.WAITING_FOR_CLIENT_BIND;
							} else {
								permissionIntent = PendingIntent.getBroadcast(
										RobotService.this, 0, new Intent(
												ACTION_USB_PERMISSION), 0);
								usbManager.requestPermission(accessory,
										permissionIntent);
								currentState = states.WAITING_FOR_PERMISSION;
							}
						} else {
							mutateUsbAttached(false);
							currentState = states.WAITING_FOR_USB_ATTACHED;
						}
						break;
					case WAITING_FOR_USB_ATTACHED:
						if (isUsbAttached) {
							currentState = states.WAITING_FOR_PERMISSION;
						} else {
							usbAttached.await(5000, TimeUnit.SECONDS);
						}
						break;
					case WAITING_FOR_PERMISSION:
						if (!isUsbAttached) {
							currentState = states.WAITING_FOR_CLOSED_ACCESSORY;
						}
						if (isPermissionGiven) {
							currentState = states.WAITING_FOR_CLIENT_BIND;
						} else {
							permissionGiven.await();
						}
						break;
					case WAITING_FOR_CLIENT_BIND:
						if (!isUsbAttached) {
							currentState = states.WAITING_FOR_CLOSED_ACCESSORY;
						}
						if (isClientBinded) {
							currentState = states.WAITING_FOR_OPENED_ACCESSORY;
						} else {
							clientBinded.await();
						}
						break;
					case WAITING_FOR_OPENED_ACCESSORY:
						if (!isUsbAttached) {
							currentState = states.WAITING_FOR_CLOSED_ACCESSORY;
						}
						if (openAccessory(accessory)) {
							currentState = states.PROCESSING;
						} else {
							currentState = states.WAITING_FOR_ACCESSORY;
						}
						break;
					case PROCESSING:
						if (!isUsbAttached) {
							currentState = states.WAITING_FOR_CLOSED_ACCESSORY;
						}
						if (!isClientBinded) {
							currentState = states.WAITING_FOR_CLOSED_ACCESSORY;
						}
						break;
					case WAITING_FOR_CLOSED_ACCESSORY:
						closeAccessory();
						currentState = states.WAITING_FOR_ACCESSORY;
						break;
					case WAITING_FOR_RESET:
						if (!isUsbAttached) {
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
				if (currentState.equals(states.PROCESSING) && !process()) {
					currentState = states.WAITING_FOR_ACCESSORY;
				}

				if (!beforeLoopState.equals(currentState)) {
					stateChangeCount++;
					if ((System.currentTimeMillis() - lastCheckStateChangeCount) > 5000) {
						if (stateChangeCount > 10) {
							Log.e(TAG,
									"Max change count reached, waiting for reset");
							currentState = states.WAITING_FOR_RESET;
						}
						stateChangeCount = 0;
						lastCheckStateChangeCount = System.currentTimeMillis();
					}
					Log.d(TAG, "Going from state " + beforeLoopState.name()
							+ " to " + currentState.name());
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
					if (inputStream.available() != 0) {
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
							robotData.setCollisions(buffer[i + 1]);
							senderClient.send(robotData);
						}
						i += 2;
						messagesReceived++;
						break;
					}
				}
			}
			robotCommands.update(senderClient.getRobotCommands());
			return sendCommand((byte) robotCommands.getDirection().ordinal(),
					(byte) 100, 0);
		}
	};
	private Thread backgroundThread;
	// Binder given to clients
	private final IBinder binder = new LocalBinder();
	private final Lock lock = new ReentrantLock();
	private final Condition clientBinded = lock.newCondition();

	private states currentState = states.STARTING_THREAD;
	private ParcelFileDescriptor fileDescriptor;
	private FileInputStream inputStream;
	private boolean isClientBinded = false;
	private boolean isPermissionGiven = false;
	private boolean isThreadRunning = false;
	private boolean isUsbAttached = false;

	private int messagesReceived;
	private final RobotCommands robotCommands = new RobotCommands();
	private FileOutputStream outputStream;
	private final Condition permissionGiven = lock.newCondition();
	private PendingIntent permissionIntent;
	private final RobotData robotData = new RobotData();

	private SenderServiceClient senderClient;

	private ServiceConnection senderServiceConnection = new ServiceConnection() {
		@Override
		public void onServiceConnected(ComponentName name, IBinder service) {
			SenderService.LocalBinder binder = (SenderService.LocalBinder) service;
			senderClient = new SenderServiceClient(binder.getService());
		}

		@Override
		public void onServiceDisconnected(ComponentName name) {
			senderClient = null;
		}

	};

	private final Condition usbAttached = lock.newCondition();;
	private UsbManager usbManager;

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
			} else if (UsbManager.ACTION_USB_ACCESSORY_ATTACHED.equals(action)) {
				Log.d(TAG, "USB Attached received");
				mutateUsbAttached(true);
			} else if (UsbManager.ACTION_USB_ACCESSORY_DETACHED.equals(action)) {
				Log.d(TAG, "USB Detached received");
				mutateUsbAttached(false);
				closeAccessory();
				Log.d(TAG, "USB Detached handling completed");
			} else {
				Log.d(TAG, "Unhandled onReceive action " + action);
			}
		}

	};

	private void mutateUsbAttached(boolean state) {
		lock.lock();
		try {
			isUsbAttached = state;
			usbAttached.signal();
		} finally {
			lock.unlock();
		}
	}
	public int getCurrentState() {
		return currentState.ordinal();
	}

	public String getCurrentStateName() {
		return currentState.name();
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

	public int getMessagesReceived() {
		return messagesReceived;
	}

	public void go(RobotCommands.Directions direction) {
		robotCommands.setDirection(direction);
	}

	// services exposed...

	public boolean isThreadRunning() {
		return isThreadRunning;
	}

	@Override
	public IBinder onBind(Intent intent) {
		Toast.makeText(getApplicationContext(), "binding", Toast.LENGTH_SHORT)
				.show();
		bindToSenderService();
		mutateClientBindedState(true);
		return binder;
	}
	
	private void mutateClientBindedState(boolean state) {
		lock.lock();
		try {
			isClientBinded = true;
			clientBinded.signal();
		} finally {
			lock.unlock();
		}
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
	public void onDestroy() {
		super.onDestroy();
		Log.d(TAG, "onDestroy");
		isThreadRunning = false;
	}

	@Override
	public void onLowMemory() {
		super.onLowMemory();
		Log.d(TAG, "onLowMemory");
	}

	@Override
	public int onStartCommand(Intent intent, int startId, int i) {
		Log.d(TAG, "onStartCommand");
		return super.onStartCommand(intent, startId, i);
	}

	@Override
	public boolean onUnbind(Intent intent) {
		lock.lock();
		mutateClientBindedState(false);
		return super.onUnbind(intent);
	}

	public void startSenderService() {
		Intent intent = new Intent(this, SenderService.class);
		ComponentName componentName = startService(intent);
		if (componentName == null) {
			Toast.makeText(this, "Could not connect to service",
					Toast.LENGTH_SHORT).show();
		}
	}

	private void bindToSenderService() {
		Toast.makeText(this,
				"Connecting to service " + SenderService.class.getSimpleName(),
				Toast.LENGTH_SHORT).show();
		// Bind to the service
		bindService(new Intent(this, SenderService.class),
				senderServiceConnection, Context.BIND_AUTO_CREATE);
	}

	private void closeAccessory() {
		try {
			if (inputStream != null) {
				inputStream.close();
			}
			if (outputStream != null) {
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
		if (accessory == null) {
			Log.e(TAG, "Null accessory");
			return false;
		}
		if (usbManager == null) {
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
		} catch (IllegalArgumentException e) {
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

	private void setupUsbReceiver() {
		Log.d(TAG, "Registering listener");
		IntentFilter filter = new IntentFilter(ACTION_USB_PERMISSION);
		filter.addAction(UsbManager.ACTION_USB_ACCESSORY_DETACHED);
		filter.addAction(UsbManager.ACTION_USB_ACCESSORY_ATTACHED);
		registerReceiver(usbReceiver, filter);
	}

	private void startBackgroundThread() {
		if (backgroundThread == null || !backgroundThread.isAlive()) {
			backgroundThread = new Thread(null, backgroundProcessing,
					"Robot Background Processing");
			backgroundThread.start();
		}
	}

	public RobotCommands getCurrentCommand() {
		return robotCommands;
	}

	public RobotData getCurrentData() {
		return robotData;
	}

	public void simulateCollision(RobotSensors robotSensor, boolean state) {
		robotData.setCollision(robotSensor, state);
		senderClient.send(robotData);
	}
}
