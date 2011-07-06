package com.xinchejian.art;

import java.io.FileDescriptor;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.os.ParcelFileDescriptor;
import android.util.Log;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.ToggleButton;

import com.android.future.usb.UsbAccessory;
import com.android.future.usb.UsbManager;

public class ConsoleActivity extends Activity implements Runnable {
	private static final int UI_UPDATE_RATE_MS = 1000;

	private static final String ACTION_USB_PERMISSION = "com.xinchejian.art.action.USB_PERMISSION";

	private static final byte FORWARD_RIGHT_INFRARED = 1;
	private static final byte FORWARD_LEFT_INFRARED = 1<<1;
	private static final byte LEFT_INFRARED = 1<<2;
	private static final byte RIGHT_INFRARED = 1<<3;
	private static final byte BACKWARD_INFRARED = 1<<4;
	private static final byte FORWARD_INFRARED = 1<<5;
	private static final int MESSAGE_COLLISIONS = 1;
	private static final String TAG = "ConsoleActivity";
	private Map<Byte, Boolean> toggles = new HashMap<Byte, Boolean>(); 
	UsbAccessory mAccessory;

	Handler messageHandler = new Handler() {
		@Override
		public void handleMessage(Message msg) {
			switch (msg.what) {
				case MESSAGE_COLLISIONS:
					update(msg.arg1, toggleButtonForward, FORWARD_INFRARED);
					update(msg.arg1, toggleButtonForwardLeft, FORWARD_LEFT_INFRARED);
					update(msg.arg1, toggleButtonForwardRight, FORWARD_RIGHT_INFRARED);
					update(msg.arg1, toggleButtonLeft, LEFT_INFRARED);
					update(msg.arg1, toggleButtonRight, RIGHT_INFRARED);
					update(msg.arg1, toggleButtonBackward, BACKWARD_INFRARED);
					break;

			}
		}

		private void update(int arg1, ToggleButton toggleButton, byte byteMask) {
			Boolean currentValue = Boolean.valueOf((arg1 & byteMask) != 0);
			Byte key = Byte.valueOf(byteMask);
			Boolean previousValue;
			if(toggles.containsKey(key)) {
				Log.d(TAG, "Getting existing value for mask " + key);
				previousValue = toggles.get(key);
			} else {
				Log.d(TAG, "First time we record value for mask " + key);
				previousValue = !currentValue;
			}
			
			if(currentValue != previousValue) {
				Log.d(TAG, "Updating ToggleButton " + toggleButton.getText() + " to " + currentValue);
				toggleButton.setChecked(currentValue);
				toggleButton.postInvalidate();
				toggles.put(key, currentValue);
			}
			
		}
	};
	private int messagesReceived;
	private int messagesLastUiUpdate;
	private ParcelFileDescriptor mFileDescriptor;
	private FileInputStream mInputStream;
	private FileOutputStream mOutputStream;
	private PendingIntent mPermissionIntent;
	private boolean mPermissionRequestPending;

	private UsbManager mUsbManager;

	private final BroadcastReceiver mUsbReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			String action = intent.getAction();
			if (ACTION_USB_PERMISSION.equals(action)) {
				synchronized (this) {
					UsbAccessory accessory = UsbManager.getAccessory(intent);
					if (intent.getBooleanExtra(
							UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
						openAccessory(accessory);
					} else {
						Log.d(TAG, "permission denied for accessory "
								+ accessory);
					}
					mPermissionRequestPending = false;
				}
			} else if(UsbManager.ACTION_USB_ACCESSORY_ATTACHED.equals(action)) {
				UsbAccessory accessory = UsbManager.getAccessory(intent);
				openAccessory(accessory);				
			} else if (UsbManager.ACTION_USB_ACCESSORY_DETACHED.equals(action)) {
				UsbAccessory accessory = UsbManager.getAccessory(intent);
				if (accessory != null && accessory.equals(mAccessory)) {
					closeAccessory();
				}
			}
		}
	};
	Runnable stateUpdate = new Runnable() {
		public void run() {
			toggleButtonThreadState.setChecked(thread != null && thread.isAlive());
			if(thread == null || !thread.isAlive()) {
				openAccessory(mAccessory);
			}
			textViewIp.setText(getLocalIpAddress());
			textViewMessages.setText("" + (messagesReceived - messagesLastUiUpdate)/(UI_UPDATE_RATE_MS/1000) + " Hz\n" + messagesReceived);
			messagesLastUiUpdate = messagesReceived;
			stateUpdateHandler.postDelayed(stateUpdate, UI_UPDATE_RATE_MS);		
		}
	};
	Handler stateUpdateHandler = new Handler();
	private TextView textViewIp;

	private Thread thread;

	private ToggleButton toggleButtonAccessoryOpened;

	private ToggleButton toggleButtonBackward;

	private ToggleButton toggleButtonForward;

	private ToggleButton toggleButtonForwardLeft;

	private ToggleButton toggleButtonForwardRight;

	private ToggleButton toggleButtonLeft;

	private ToggleButton toggleButtonRight;

	private ToggleButton toggleButtonThreadState;

	private TextView textViewMessages;

	private void closeAccessory() {
		enableControls(false);
		try {
			if (mFileDescriptor != null) {
				mFileDescriptor.close();
			}
		} catch (IOException e) {
		} finally {
			mFileDescriptor = null;
			mAccessory = null;
		}
	}

	protected void enableControls(boolean enable) {
		toggleButtonAccessoryOpened.setChecked(enable);
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

	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		mUsbManager = UsbManager.getInstance(this);
		mPermissionIntent = PendingIntent.getBroadcast(this, 0, new Intent(
				ACTION_USB_PERMISSION), 0);
		IntentFilter filter = new IntentFilter(ACTION_USB_PERMISSION);
		filter.addAction(UsbManager.ACTION_USB_ACCESSORY_DETACHED);
		filter.addAction(UsbManager.ACTION_USB_ACCESSORY_ATTACHED);
		registerReceiver(mUsbReceiver, filter);

		if (getLastNonConfigurationInstance() != null) {
			mAccessory = (UsbAccessory) getLastNonConfigurationInstance();
			openAccessory(mAccessory);
		}

		setContentView(R.layout.main);
		toggleButtonForward = (ToggleButton) findViewById(R.id.toggleButtonForward);
		toggleButtonForwardLeft = (ToggleButton) findViewById(R.id.toggleButtonForwardLeft);
		toggleButtonForwardRight = (ToggleButton) findViewById(R.id.toggleButtonForwardRight);
		toggleButtonLeft = (ToggleButton) findViewById(R.id.toggleButtonLeftSide);
		toggleButtonRight = (ToggleButton) findViewById(R.id.toggleButtonRightSide);
		toggleButtonBackward = (ToggleButton) findViewById(R.id.toggleButtonBackward);
		textViewIp = (TextView) findViewById(R.id.textViewIp);
		toggleButtonAccessoryOpened = (ToggleButton) findViewById(R.id.toggleButtonAccessoryOpened);
		textViewMessages = (TextView) findViewById(R.id.textViewMessages);
		toggleButtonThreadState = (ToggleButton) findViewById(R.id.toggleButtonThreadState);
		enableControls(false);
		stateUpdateHandler.postDelayed(stateUpdate, 1000);
	}

	@Override
	public void onDestroy() {
		unregisterReceiver(mUsbReceiver);
		super.onDestroy();
	}
	
	@Override
	public void onPause() {
		super.onPause();
		closeAccessory();
	}
	
	@Override
	public void onResume() {
		super.onResume();

		if (mInputStream != null && mOutputStream != null) {
			return;
		}

		UsbAccessory[] accessories = mUsbManager.getAccessoryList();
		UsbAccessory accessory = (accessories == null ? null : accessories[0]);
		if (accessory != null) {
			if (mUsbManager.hasPermission(accessory)) {
				openAccessory(accessory);
			} else {
				synchronized (mUsbReceiver) {
					if (!mPermissionRequestPending) {
						mUsbManager.requestPermission(accessory,
								mPermissionIntent);
						mPermissionRequestPending = true;
					}
				}
			}
		} else {
			Log.e(TAG, "mAccessory is null");
		}
	}

	@Override
	public Object onRetainNonConfigurationInstance() {
		if (mAccessory != null) {
			return mAccessory;
		} else {
			return super.onRetainNonConfigurationInstance();
		}
	}

	public void onStartTrackingTouch(SeekBar seekBar) {
	}
	
	public void onStopTrackingTouch(SeekBar seekBar) {
	}


	private void openAccessory(UsbAccessory accessory) {
		mFileDescriptor = mUsbManager.openAccessory(accessory);
		if (mFileDescriptor != null) {
			mAccessory = accessory;
			FileDescriptor fd = mFileDescriptor.getFileDescriptor();
			mInputStream = new FileInputStream(fd);
			mOutputStream = new FileOutputStream(fd);
			thread = new Thread(null, this, "ART Processing Thread");
			thread.start();
			Log.d(TAG, "accessory opened");
			enableControls(true);
		} else {
			Log.e(TAG, "accessory open fail");
		}
	}

	public void run() {
		int ret = 0;
		byte[] buffer = new byte[16384];
		int i;
		while (ret >= 0) {
			try {
				ret = mInputStream.read(buffer);
			} catch (IOException e) {
				Log.e(TAG, "Could not read from input stream", e);
				break;
			}

			i = 0;
			while (i < ret) {
				int len = ret - i;
				switch (buffer[i]) {
					case 0x1:
						if (len >= 2) {
							Message m = Message.obtain(messageHandler, MESSAGE_COLLISIONS);
							m.arg1 = buffer[i + 1];
							Log.d(TAG, "Read: " + buffer[i + 1]);
							messageHandler.sendMessage(m);
						}
						i += 2;
						messagesReceived++;
						break;
				}
			}

		}
		Log.e(TAG, "Exiting from processing thread");
	}

	public void sendCommand(byte command, byte target, int value) {
		byte[] buffer = new byte[3];
		if (value > 255)
			value = 255;

		buffer[0] = command;
		buffer[1] = target;
		buffer[2] = (byte) value;
		if (mOutputStream != null && buffer[1] != -1) {
			try {
				mOutputStream.write(buffer);
			} catch (IOException e) {
				Log.e(TAG, "write failed", e);
			}
		}
	}
}