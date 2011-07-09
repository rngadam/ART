package com.xinchejian.art.video.server;

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

import com.xinchejian.art.video.server.VideoStreamingSenderService.LocalBinder;

public class ServerActivity extends Activity {
	private static final String TAG = ServerActivity.class.getCanonicalName();
	@Override
	protected void onResume() {
		super.onResume();
		bindToService();
	}
	private TextView status;
	private TextView ip;
	private Handler uiUpdate = new Handler();
	private VideoStreamingSenderServiceClient videoStreamingSenderClient;
	private ServiceConnection mConnection;
	
	public void startService() {
		Intent intent = new Intent(this, VideoStreamingSenderService.class);
		ComponentName componentName = startService(intent);
		if (componentName == null) {
			Toast.makeText(this, "Could not connect to service",
					Toast.LENGTH_SHORT).show();
		} else {
			bindToService();
		}		
	}

	private void bindToService() {
		Toast.makeText(this, "Connecting to service " + VideoStreamingSenderService.class.getSimpleName(),
				Toast.LENGTH_SHORT).show();
		// Bind to the service
		bindService(new Intent(this, VideoStreamingSenderService.class),
				mConnection, Context.BIND_AUTO_CREATE);
	}	
	private Runnable uiUpdateRunnable = new Runnable() {
		@Override
		public void run() {
			Log.d(TAG, "Updating server UI");
			status.setText(videoStreamingSenderClient.getStatus());
			ip.setText(videoStreamingSenderClient.getIp());
			uiUpdate.postDelayed(uiUpdateRunnable, 1000);
		}
		
	};

	/** Called when the activity is first created. */

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		mConnection = new ServiceConnection() {
			public void onServiceConnected(ComponentName className, IBinder service) {
				Log.d(TAG, "Connected to service " + className);
				com.xinchejian.art.video.server.VideoStreamingSenderService.LocalBinder binder = (LocalBinder) service;
				videoStreamingSenderClient = new VideoStreamingSenderServiceClient(binder.getService());
				uiUpdate.postDelayed(uiUpdateRunnable, 1000);
			}

			public void onServiceDisconnected(ComponentName className) {
				Log.d(TAG, "Disconnecting from service " + className);
				uiUpdate.removeCallbacks(uiUpdateRunnable);
				videoStreamingSenderClient = null;
			}
		};
		startService();
		setContentView(R.layout.main);
		status = (TextView) findViewById(R.id.textView1);
		ip = (TextView) findViewById(R.id.textViewIp);
	}

}