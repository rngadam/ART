package com.xinchejian.art.server;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.util.Log;
import android.widget.TextView;
import android.widget.Toast;

import com.xinchejian.art.server.SenderService.LocalBinder;

public class ServerActivity extends Activity {

	private final class RobotServiceConnection implements
	ServiceConnection {
		public void onServiceConnected(ComponentName className, IBinder service) {
			RobotService.LocalBinder binder = (RobotService.LocalBinder) service;
			robotServiceClient = new RobotServiceClient(binder.getService());
			uiUpdate.postDelayed(robotUpdateRunnable, UI_UPDATE_RATE_MS);
		}
		
		public void onServiceDisconnected(ComponentName className) {
			uiUpdate.removeCallbacks(robotUpdateRunnable);
			robotServiceClient = null;
		}
	}
	private final class VideoStreamingSenderServiceConnection implements
			ServiceConnection {
		public void onServiceConnected(ComponentName className, IBinder service) {
			Log.d(TAG, "Connected to service " + className);
			LocalBinder binder = (LocalBinder) service;
			senderServiceClient = new SenderServiceClient(binder.getService());
			uiUpdate.removeCallbacks(videoUpdateRunnable);
			isVideoUpdating = true;
			uiUpdate.postDelayed(videoUpdateRunnable, UI_UPDATE_RATE_MS);
		}

		public void onServiceDisconnected(ComponentName className) {
			Log.d(TAG, "Disconnecting from service " + className);
			isVideoUpdating = false;
			uiUpdate.removeCallbacks(videoUpdateRunnable);
			senderServiceClient = null;
		}
	}

	private static final String TAG = ServerActivity.class.getCanonicalName();;
	protected static final int UI_UPDATE_RATE_MS = 1000;
	public RobotServiceClient robotServiceClient;
	private TextView ip;
	private ServiceConnection robotConnection = new RobotServiceConnection();
	private Runnable robotUpdateRunnable = new Runnable() {
		private int messagesLastUiUpdate;

		public void run() {
			textViewRobotState.setText(robotServiceClient.getCurrentStateName());
			int messagesReceived = robotServiceClient.getMessagesReceived();
			textViewRobotMessages.setText("" + (messagesReceived - messagesLastUiUpdate)/(UI_UPDATE_RATE_MS/1000) + " Hz\n" + messagesReceived);
			messagesLastUiUpdate = messagesReceived;
			uiUpdate.postDelayed(robotUpdateRunnable, UI_UPDATE_RATE_MS);		
		}
	};
	private TextView status;
	private TextView textViewRobotMessages;;
	private TextView textViewRobotState;
	private Handler uiUpdate = new Handler();
	private ServiceConnection videoConnection = new VideoStreamingSenderServiceConnection();
	private SenderServiceClient senderServiceClient;

	private Runnable videoUpdateRunnable = new Runnable() {
		@Override
		public void run() {
			//Log.d(TAG, "Updating server UI");
			status.setText(senderServiceClient.getStatus());
			ip.setText(senderServiceClient.getIp());
			if(isVideoUpdating) {
				uiUpdate.removeCallbacks(videoUpdateRunnable);
				uiUpdate.postDelayed(videoUpdateRunnable, UI_UPDATE_RATE_MS);
			}
		}
		
	};

	protected volatile boolean isVideoUpdating;

	public void bindToRobotService() {
		Toast.makeText(this, "Connecting to service",
				Toast.LENGTH_SHORT).show();
		// Bind to the service
		bindService(new Intent(this, RobotService.class),
				robotConnection, Context.BIND_AUTO_CREATE);
	}

	/** Called when the activity is first created. */

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main);
		status = (TextView) findViewById(R.id.textViewVideoState);
		ip = (TextView) findViewById(R.id.textViewIp);
		textViewRobotState = (TextView) findViewById(R.id.textViewRobotState);
		textViewRobotMessages = (TextView) findViewById(R.id.textViewRobotMessages);
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
		Toast.makeText(this, "Connecting to service " + SenderService.class.getSimpleName(),
				Toast.LENGTH_SHORT).show();
		// Bind to the service
		bindService(new Intent(this, SenderService.class),
				videoConnection, Context.BIND_AUTO_CREATE);
	}
	 
	@Override
	protected void onStart() {
		super.onStart();
		bindToSenderService();
		bindToRobotService();
	}	
	
	@Override
	protected void onStop() {
		super.onStop();
		unbindService(videoConnection);
		unbindService(robotConnection);
	}
}