package com.xinchejian.art.server;

import java.util.concurrent.locks.ReentrantLock;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.widget.TextView;
import android.widget.Toast;

import com.xinchejian.art.robot.RobotData;
import com.xinchejian.art.server.SenderService.LocalBinder;

public class ServerActivity extends Activity {
	private ReentrantLock lock = new ReentrantLock();
	
	private final class RobotServiceConnection implements ServiceConnection {
		public void onServiceConnected(ComponentName className, IBinder service) {
			RobotService.LocalBinder binder = (RobotService.LocalBinder) service;
			robotServiceClient = new RobotServiceClient(binder.getService());
			updateRobotStatus(true);
		}

		public void onServiceDisconnected(ComponentName className) {
			handler.removeCallbacks(robotUpdateRunnable);
			robotServiceClient = null;
			updateRobotStatus(false);
		}
	}

	private final class VideoStreamingSenderServiceConnection implements
			ServiceConnection {
		public void onServiceConnected(ComponentName className, IBinder service) {
			Log.d(TAG, "Connected to service " + className);
			LocalBinder binder = (LocalBinder) service;
			senderServiceClient = new SenderServiceClient(binder.getService());
			updateSender(true);
		}

		public void onServiceDisconnected(ComponentName className) {
			Log.d(TAG, "Disconnecting from service " + className);
			updateSender(false);
			senderServiceClient = null;
		}
	}

	private static final String TAG = ServerActivity.class.getCanonicalName();;
	protected static final int STATUS_UPDATE_RATE_MS = 1000;
	public RobotServiceClient robotServiceClient;
	private TextView ip;
	private ServiceConnection robotConnection = new RobotServiceConnection();
	private Runnable robotUpdateRunnable = new Runnable() {
		private int messagesLastUiUpdate;

		public void run() {
			textViewRobotState
					.setText("Robot state"
							+ "\n\tUSB state: " + robotServiceClient.getCurrentStateName()
							+ "\n\tRobot command " + robotServiceClient.getCurrentCommand()
							+ "\n\tRobot data " + robotServiceClient.getCurrentData());
							
			int messagesReceived = robotServiceClient.getMessagesReceived();
			textViewRobotMessages.setText("Messages "
					+ (messagesReceived - messagesLastUiUpdate)
					/ (STATUS_UPDATE_RATE_MS / 1000) + " Hz" 
					+ "\n\tMessages count: " + messagesReceived);
			textViewActivityState.setText("Activity state" 
					+ "\n\tisRobotStateUpdating " + isRobotStatusUpdating
					+ "\n\tisSenderUpdating " + isSenderUpdating
					+ "\n\tSimulation running " + isSimulating);
			messagesLastUiUpdate = messagesReceived;
			updateRobotStatus(isRobotStatusUpdating);
		}
	};
	
	private Runnable senderUpdateRunnable = new Runnable() {
		public void run() {
			senderStatus.setText("Video status: " + senderServiceClient.getStatus());
			ip.setText("IP: " + senderServiceClient.getIp());
			updateSender(isSenderUpdating);
		}
	};	
	private TextView senderStatus;
	private TextView textViewRobotMessages;;
	private TextView textViewRobotState;
	private Handler handler = new Handler();
	private ServiceConnection videoConnection = new VideoStreamingSenderServiceConnection();
	private SenderServiceClient senderServiceClient;
	protected volatile boolean isRobotStatusUpdating;
	private boolean isSimulating = false;
	private boolean isSenderUpdating = false;
	private TextView textViewActivityState;

	private void updateRobotStatus(boolean state) {
		lock.lock();
		try {
			isRobotStatusUpdating = state;
			if (isRobotStatusUpdating) {
				handler.removeCallbacks(robotUpdateRunnable);
				handler.postDelayed(robotUpdateRunnable, STATUS_UPDATE_RATE_MS);
			}
		} finally {
			lock.unlock();
		}
	}
	

	private void updateSender(boolean state) {
		lock.lock();
		try {
			isSenderUpdating = state;
			if (isSenderUpdating) {
				handler.removeCallbacks(senderUpdateRunnable);
				handler.postDelayed(senderUpdateRunnable, STATUS_UPDATE_RATE_MS);
			}
		} finally {
			lock.unlock();
		}
	}
		
	
	public void bindToRobotService() {
		Toast.makeText(this, "Connecting to service", Toast.LENGTH_SHORT)
				.show();
		// Bind to the service
		bindService(new Intent(this, RobotService.class), robotConnection,
				Context.BIND_AUTO_CREATE);
	}

	/** Called when the activity is first created. */

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main);
		senderStatus = (TextView) findViewById(R.id.textViewVideoState);
		ip = (TextView) findViewById(R.id.textViewIp);
		textViewRobotState = (TextView) findViewById(R.id.textViewRobotState);
		textViewRobotMessages = (TextView) findViewById(R.id.textViewRobotMessages);
		textViewActivityState = (TextView) findViewById(R.id.textViewActivityState);
		startSenderService();
		startRobotService();
	}

	public void startRobotService() {
		Intent intent = new Intent(this, RobotService.class);
		ComponentName componentName = startService(intent);
		if (componentName == null) {
			Toast.makeText(this, "Could not connect to service",
					Toast.LENGTH_SHORT).show();
		}
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
		bindService(new Intent(this, SenderService.class), videoConnection,
				Context.BIND_AUTO_CREATE);
	}

	@Override
	protected void onStart() {
		super.onStart();
		bindToSenderService();
		bindToRobotService();
		updateSimulationStatus(false);
	}

	@Override
	protected void onStop() {
		super.onStop();
		unbindService(videoConnection);
		unbindService(robotConnection);
		updateSimulationStatus(false);
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.console_menu, menu);
		return true;
	}
	
	private Runnable simulationRunnable = new Runnable() {
		final RobotData.RobotSensors[] values = RobotData.RobotSensors.values();
		int currentSimulatedCollisionIndex = 0;
		@Override
		public void run() {
			if(robotServiceClient != null) {
				robotServiceClient.simulateCollision(values[currentSimulatedCollisionIndex], false);
				currentSimulatedCollisionIndex++;
				if(currentSimulatedCollisionIndex >= values.length) {
					currentSimulatedCollisionIndex = 0;
				}
				robotServiceClient.simulateCollision(values[currentSimulatedCollisionIndex], true);
			}
			updateSimulationStatus(isSimulating);
		}
	};

	private void updateSimulationStatus(boolean state) {
		lock.lock();
		try {
			isSimulating = state;
			if(isSimulating) {
				handler.postDelayed(simulationRunnable, 1000);
			}
		} finally {
			lock.unlock();
		}
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		// Handle item selection
		switch (item.getItemId()) {
		case R.id.exit:
			finish();
			return true;
		case R.id.simulate:
			updateSimulationStatus(!isSimulating);
			return true;
		default:
			return super.onOptionsItemSelected(item);
		}
	}	
}