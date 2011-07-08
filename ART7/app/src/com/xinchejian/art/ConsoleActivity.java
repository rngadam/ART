package com.xinchejian.art;

import java.util.HashMap;
import java.util.Map;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.util.Log;
import android.widget.CompoundButton;
import android.widget.CompoundButton.OnCheckedChangeListener;
import android.widget.SeekBar;
import android.widget.TableLayout;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.ToggleButton;

import com.xinchejian.art.RobotService.LocalBinder;
import com.xinchejian.art.RobotService.directions;

public class ConsoleActivity extends Activity {
	private static final int UI_UPDATE_RATE_MS = 1000;
	private static final String TAG = "ConsoleActivity";
	
	private Map<Byte, Boolean> toggles = new HashMap<Byte, Boolean>(); 

	private void processRobotUpdate(Intent intent) {
		byte collisions = intent.getByteExtra(RobotService.ROBOT_UPDATE_COLLISIONS, (byte) 0);
		update(collisions, toggleButtonForward, RobotService.FORWARD_INFRARED);
		update(collisions, toggleButtonForwardLeft, RobotService.FORWARD_LEFT_INFRARED);
		update(collisions, toggleButtonForwardRight, RobotService.FORWARD_RIGHT_INFRARED);
		update(collisions, toggleButtonLeft, RobotService.LEFT_INFRARED);
		update(collisions, toggleButtonRight, RobotService.RIGHT_INFRARED);
		update(collisions, toggleButtonBackward, RobotService.BACKWARD_INFRARED);
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
		
		if(!currentValue.equals(previousValue)) {
			Log.d(TAG, "Updating ToggleButton " + toggleButton.getText() + " to " + currentValue);
			if(currentValue.booleanValue()) {
				toggleButton.setTextColor(Color.RED);
			} else {
				toggleButton.setTextColor(Color.BLACK);
			}
			toggleButton.postInvalidate();
			toggles.put(key, currentValue);
		}
		
	}

	private int messagesLastUiUpdate;

	Runnable stateUpdate = new Runnable() {
		public void run() {
			if(robotServiceClient != null) {
				textViewState.setText(robotServiceClient.getCurrentStateName());
				textViewIp.setText(robotServiceClient.getLocalIpAddress());
				int messagesReceived = robotServiceClient.getMessagesReceived();
				textViewMessages.setText("" + (messagesReceived - messagesLastUiUpdate)/(UI_UPDATE_RATE_MS/1000) + " Hz\n" + messagesReceived);
				messagesLastUiUpdate = messagesReceived;
			}
			stateUpdateHandler.postDelayed(stateUpdate, UI_UPDATE_RATE_MS);		
		}
	};
	
	Handler stateUpdateHandler = new Handler();
	
	private TextView textViewIp;
	private ToggleButton toggleButtonBackward;
	private ToggleButton toggleButtonForward;
	private ToggleButton toggleButtonForwardLeft;
	private ToggleButton toggleButtonForwardRight;
	private ToggleButton toggleButtonLeft;
	private ToggleButton toggleButtonRight;
	private TextView textViewMessages;
	private TextView textViewState;
	private ToggleButton toggleButtonNeutral;
	private ToggleButton toggleButtonBackwardLeft;
	private ToggleButton toggleButtonBackwardRight;
	private ToggleButton lastToggleButton;
	
	protected RobotServiceClient robotServiceClient;

	private ServiceConnection mConnection = new ServiceConnection() {
		public void onServiceConnected(ComponentName className, IBinder service) {
			// This is called when the connection with the service has been
			// established, giving us the object we can use to
			// interact with the service. We are communicating with the
			// service using a Messenger, so here we get a client-side
			// representation of that from the raw IBinder object.
			LocalBinder binder = (LocalBinder) service;
			robotServiceClient = new RobotServiceClient(binder.getService());
		}

		public void onServiceDisconnected(ComponentName className) {
			// This is called when the connection with the service has been
			// unexpectedly disconnected -- that is, its process crashed.
			robotServiceClient = null;
		}
	};
	private TableLayout tableLayout;

	
	public void bindToRobotService() {
		Intent intent = new Intent(this, RobotService.class);
		//we start the service with the intent to make sure that it always
		//runs in the background even if we unbind from the service.
		ComponentName componentName = startService(intent);
		if (componentName == null) {
			Toast.makeText(this, "Could not connect to service",
					Toast.LENGTH_SHORT).show();
		} else {
			Toast.makeText(this, "Connecting to service",
					Toast.LENGTH_SHORT).show();
			// Bind to the service
			bindService(new Intent(this, RobotService.class),
					mConnection, Context.BIND_AUTO_CREATE);
		}		
	}
	
	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		IntentFilter filter = new IntentFilter(RobotService.ROBOT_UPDATE);
		registerReceiver(new BroadcastReceiver() {
			@Override
			public void onReceive(Context context, Intent intent) {
				processRobotUpdate(intent);
			}
		}, filter);
		bindToRobotService();
		setContentView(R.layout.main);
		tableLayout = (TableLayout) findViewById(R.id.tableLayout1);

		toggleButtonForwardLeft = getToggleButton(R.id.toggleButtonForwardLeft, RobotService.directions.FORWARD_LEFT);
		toggleButtonForward = getToggleButton(R.id.toggleButtonForward, RobotService.directions.FORWARD);
		toggleButtonForwardRight = getToggleButton(R.id.toggleButtonForwardRight, RobotService.directions.FORWARD_RIGHT);
		toggleButtonLeft = getToggleButton(R.id.toggleButtonLeftSide,  RobotService.directions.NEUTRAL);
		toggleButtonNeutral = getToggleButton(R.id.toggleButtonNeutral,  RobotService.directions.NEUTRAL);
		toggleButtonRight = getToggleButton(R.id.toggleButtonRightSide,  RobotService.directions.NEUTRAL);
		toggleButtonBackwardLeft = getToggleButton(R.id.toggleButtonBackwardLeft, RobotService.directions.REVERSE_LEFT);
		toggleButtonBackward = getToggleButton(R.id.toggleButtonBackward,  RobotService.directions.REVERSE);
		toggleButtonBackwardRight = getToggleButton(R.id.toggleButtonBackwardRight, RobotService.directions.REVERSE_RIGHT);
		textViewIp = (TextView) findViewById(R.id.textViewIp);
		textViewMessages = (TextView) findViewById(R.id.textViewMessages);
		textViewState = (TextView) findViewById(R.id.textViewState);
		tableLayout.setShrinkAllColumns(true);
		tableLayout.setStretchAllColumns(true);
		
		stateUpdateHandler.postDelayed(stateUpdate, 1000);
	}

	private ToggleButton getToggleButton(int id, final directions direction) {
		final ToggleButton toggleButton = (ToggleButton) findViewById(id);
		
		toggleButton.setOnCheckedChangeListener(new OnCheckedChangeListener() {
			public void onCheckedChanged(CompoundButton buttonView,
					boolean isChecked) {
				if(isChecked) {
					robotServiceClient.go(direction);
				}
				lastToggleButton.setChecked(false);
				lastToggleButton = toggleButton;

			}
		});
		return toggleButton;
	}

	@Override
	public void onDestroy() {
		super.onDestroy();
	}
	
	@Override
	public void onPause() {
		super.onPause();
	}
	
	@Override
	public void onResume() {
		super.onResume();
	}

	public void onStartTrackingTouch(SeekBar seekBar) {
	}
	
	public void onStopTrackingTouch(SeekBar seekBar) {
	}
}