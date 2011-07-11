package com.xinchejian.art.client;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.locks.ReentrantLock;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.CompoundButton;
import android.widget.CompoundButton.OnCheckedChangeListener;
import android.widget.ImageView;
import android.widget.TableLayout;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.ToggleButton;

import com.xinchejian.art.client.ReceiverService.LocalBinder;
import com.xinchejian.art.robot.RobotCommands;
import com.xinchejian.art.robot.RobotData;

public class ClientActivity extends Activity {
	protected static final String TAG = ClientActivity.class.getCanonicalName();

	private ImageView imageView;
	private boolean isRobotUpdating;
	private long lastRobotUpdate;
	private ToggleButton lastToggleButton;
	private final ReentrantLock lock = new ReentrantLock();
	private ReceiverClient receiverClient;
	private ServiceConnection receiverServiceConnection = new ServiceConnection() {

		public void onServiceConnected(ComponentName className, IBinder service) {
			Toast.makeText(ClientActivity.this,
					"Service connected " + className, Toast.LENGTH_SHORT)
					.show();
			LocalBinder binder = (LocalBinder) service;
			receiverClient = new ReceiverClient(binder.getService());
			mutateReceiverState(true);
			mutateRobotUpdateState(true);
		}

		public void onServiceDisconnected(ComponentName className) {
			Toast.makeText(ClientActivity.this,
					"Service disconnected " + className, Toast.LENGTH_SHORT)
					.show();
			mutateReceiverState(false);
			mutateRobotUpdateState(false);
		}
	};
	private Runnable receiverUpdateRunnable = new Runnable() {
		@Override
		public void run() {
			// Log.d(TAG, "Updating client UI");
			if (displayStatusOnScreen) {
				textViewStreamStatus.setText(getDisplayStatus());
			} else {
				textViewStreamStatus.setVisibility(View.INVISIBLE);
			}
			Bitmap nextBitmap = receiverClient.getNextBitmap();
			if (nextBitmap != null) {
				imageView.setImageBitmap(nextBitmap);
				displayed++;
			} else {
				underflow++;
			}

			mutateReceiverState(isReceiverUpdating);
		}
	};
	private final RobotCommands robotCommands = new RobotCommands();
	private final RobotData robotData = new RobotData();
	private Runnable robotUpdaterRunnable = new Runnable() {
		@Override
		public void run() {
			robotData.update(receiverClient.getRobotData());
			processRobotUpdate();
			mutateRobotUpdateState(isRobotUpdating);
		}
	};
	private long startTime;
	private TableLayout tableLayout;
	private TextView textViewStreamStatus;
	private ToggleButton toggleButtonBackward;
	private ToggleButton toggleButtonBackwardLeft;
	private ToggleButton toggleButtonBackwardRight;
	private ToggleButton toggleButtonForward;
	private ToggleButton toggleButtonForwardLeft;
	private ToggleButton toggleButtonForwardRight;
	private ToggleButton toggleButtonLeft;

	private ToggleButton toggleButtonNeutral;
	
	private ToggleButton toggleButtonRight;

	private Map<RobotData.RobotSensors, Boolean> toggles = new HashMap<RobotData.RobotSensors, Boolean>();

	private Handler handler = new Handler();
	protected int displayed;

	protected boolean displayStatusOnScreen = false;

	protected boolean isReceiverUpdating;

	protected int underflow;
	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		startReceiverService();
		setContentView(R.layout.main);
		imageView = (ImageView) findViewById(R.id.imageView1);
		textViewStreamStatus = (TextView) findViewById(R.id.textViewStreamStatus);
		tableLayout = (TableLayout) findViewById(R.id.tableLayout1);
		toggleButtonForwardLeft = getToggleButton(R.id.toggleButtonForwardLeft,
				RobotCommands.Directions.FORWARD_LEFT);
		toggleButtonForward = getToggleButton(R.id.toggleButtonForward,
				RobotCommands.Directions.FORWARD);
		toggleButtonForwardRight = getToggleButton(
				R.id.toggleButtonForwardRight,
				RobotCommands.Directions.FORWARD_RIGHT);
		toggleButtonLeft = getToggleButton(R.id.toggleButtonLeftSide,
				RobotCommands.Directions.NEUTRAL);
		toggleButtonNeutral = getToggleButton(R.id.toggleButtonNeutral,
				RobotCommands.Directions.NEUTRAL);
		toggleButtonRight = getToggleButton(R.id.toggleButtonRightSide,
				RobotCommands.Directions.NEUTRAL);
		toggleButtonBackwardLeft = getToggleButton(
				R.id.toggleButtonBackwardLeft,
				RobotCommands.Directions.REVERSE_LEFT);
		toggleButtonBackward = getToggleButton(R.id.toggleButtonBackward,
				RobotCommands.Directions.REVERSE);
		toggleButtonBackwardRight = getToggleButton(
				R.id.toggleButtonBackwardRight,
				RobotCommands.Directions.REVERSE_RIGHT);
		tableLayout.setShrinkAllColumns(true);
		tableLayout.setStretchAllColumns(true);
	}
	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.console_menu, menu);
		return true;
	}
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		// Handle item selection
		switch (item.getItemId()) {
		case R.id.exit:
			finish();
			return true;
		case R.id.settings:
			Intent intent = new Intent(this, SettingsActivity.class);
			startActivityForResult(intent, 0);
			return true;
		case R.id.stats:
			AlertDialog.Builder builder = new AlertDialog.Builder(this);
			builder.setMessage(getDisplayStatus());
			builder.show();
			return true;
		default:
			return super.onOptionsItemSelected(item);
		}
	}

	private void bindReceiverService() {
		Toast.makeText(this,
				"Connecting to service " + ReceiverService.class.getName(),
				Toast.LENGTH_SHORT).show();
		// Bind to the service
		Intent intent = getReceiverServiceIntent();

		bindService(intent, receiverServiceConnection, Context.BIND_AUTO_CREATE);
	}

	private void mutateRobotUpdateState(boolean flag) {
		lock.lock();
		try {
			isRobotUpdating = flag;
			handler.removeCallbacks(robotUpdaterRunnable);
			if (flag) {
				handler.postDelayed(robotUpdaterRunnable, 300);
			} else {
				displayed = 0;
				underflow = 0;
				startTime = System.currentTimeMillis();	
			}
		} finally {
			lock.unlock();
		}
	}

	private String getDisplayStatus() {
		return receiverClient.getStatus() + " display fps: " + displayed * 1000
				/ (System.currentTimeMillis() + 1 - startTime)
				+ " underflow (Hz) " + (System.currentTimeMillis() - startTime)
				/ ((underflow + 1) * 1000) + " displayed " + displayed
				+ " RobotData " + robotData.toString()
				+ " RobotCommands " + robotCommands.toString();
	}

	private Intent getReceiverServiceIntent() {
		Intent intent = new Intent(this, ReceiverService.class);
		SharedPreferences preferences = getSharedPreferences(
				ClientConstants.PREFS_STORE, MODE_WORLD_WRITEABLE);

		intent.putExtra(ReceiverService.SERVER_ADDRESS_ATTRIBUTE, preferences
				.getString(ClientConstants.SERVER_IP_PREF,
						ClientConstants.DEFAULT_IP));
		intent.putExtra(ReceiverService.SERVER_PORT_ATTRIBUTE, preferences
				.getInt(ClientConstants.SERVER_PORT_PREF,
						ClientConstants.DEFAULT_PORT));
		return intent;
	}

	private ToggleButton getToggleButton(int id,
			final RobotCommands.Directions direction) {
		final ToggleButton toggleButton = (ToggleButton) findViewById(id);

		toggleButton.setOnCheckedChangeListener(new OnCheckedChangeListener() {
			public void onCheckedChanged(CompoundButton buttonView,
					boolean isChecked) {
				if (isChecked) {
					robotCommands.setDirection(direction);
					if (receiverClient != null) {
						receiverClient.send(robotCommands);
					}
				}
				if (lastToggleButton != null) {
					lastToggleButton.setChecked(false);
				}
				lastToggleButton = toggleButton;

			}
		});
		return toggleButton;
	}

	private void processRobotUpdate() {
		if(robotData.getLastUpdate() > lastRobotUpdate) {
			updateCollisionUI(toggleButtonForward,
					RobotData.RobotSensors.FORWARD_INFRARED);
			updateCollisionUI(toggleButtonForwardLeft,
					RobotData.RobotSensors.FORWARD_LEFT_INFRARED);
			updateCollisionUI(toggleButtonForwardRight,
					RobotData.RobotSensors.FORWARD_RIGHT_INFRARED);
			updateCollisionUI(toggleButtonLeft, RobotData.RobotSensors.LEFT_INFRARED);
			updateCollisionUI(toggleButtonRight,
					RobotData.RobotSensors.RIGHT_INFRARED);
			updateCollisionUI(toggleButtonBackward,
					RobotData.RobotSensors.BACKWARD_INFRARED);
		} 
		lastRobotUpdate = robotData.getLastUpdate();
	}

	private void startReceiverService() {
		Intent intent = getReceiverServiceIntent();
		// we start the service with the intent to make sure that it always
		// runs in the background even if we unbind from the service.
		ComponentName componentName = startService(intent);
		if (componentName == null) {
			Toast.makeText(this, "Could not connect to service",
					Toast.LENGTH_SHORT).show();
		}
	}

	private void unbindReceiverService() {
		unbindService(receiverServiceConnection);
	}

	private void updateCollisionUI(ToggleButton toggleButton, RobotData.RobotSensors sensor) {
		if(robotData.isCollisionDetected(sensor)) {
			toggleButton.setTextColor(Color.RED);
		} else {
			toggleButton.setTextColor(Color.BLACK);
		}
		/*Boolean currentValue = robotData.isCollisionDetected(sensor);
		Boolean previousValue;
		if (toggles.containsKey(sensor)) {
			// Log.d(TAG, "Getting existing value for mask " + key);
			previousValue = toggles.get(sensor);
		} else {
			// Log.d(TAG, "First time we record value for mask " + key);
			previousValue = !currentValue;
		}

		if (!currentValue.equals(previousValue)) {
			Log.d(TAG, "Updating ToggleButton " + toggleButton.getText()
					+ " to " + currentValue);
			if (currentValue.booleanValue()) {
				toggleButton.setTextColor(Color.RED);
			} else {
				toggleButton.setTextColor(Color.BLACK);
			}
			toggleButton.postInvalidate();
			toggles.put(sensor, currentValue);
		}*/
	}

	private void mutateReceiverState(boolean state) {
		lock.lock();
		try {
			isReceiverUpdating = state;
			if (isReceiverUpdating) {
				handler.postDelayed(receiverUpdateRunnable, 20);
			}
		} finally {
			lock.unlock();
		}
		
	}

	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);
		// rebind...
		bindReceiverService();
	}

	@Override
	protected void onStart() {
		super.onStart();
		bindReceiverService();
	}

	@Override
	protected void onStop() {
		super.onStop();
		unbindReceiverService();
	}
}