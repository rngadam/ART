package com.xinchejian.art.video.client;

import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.ReentrantLock;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.xinchejian.art.video.client.VideoStreamingReceiverService.LocalBinder;

public class ClientActivity extends Activity {
	protected static final String TAG = ClientActivity.class.getCanonicalName();
	private final ReentrantLock lock = new ReentrantLock();
	private final Condition isPausedCondition = lock.newCondition();
	private volatile boolean isPaused = true;
	private ImageView imageView;
	private Handler imageUpdaterHandler = new Handler();
	private VideoStreamingReceiverClient videoStreamingReceiverClient;
	private long startTime;
	
	private void changePauseState(boolean flag) {
		lock.lock();
		try {
			isPaused = flag;
			imageUpdaterHandler.removeCallbacks(imageUpdaterRunnable);
			if(!flag) {
				displayed = 0;
				underflow = 0;
				startTime = System.currentTimeMillis();
				imageUpdaterHandler.postDelayed(imageUpdaterRunnable, 200);
			}
			isPausedCondition.signal();
		} finally {
			lock.unlock();
		}
	}

	private ServiceConnection mConnection = new ServiceConnection() {

		public void onServiceConnected(ComponentName className, IBinder service) {
			Toast.makeText(ClientActivity.this, "Service connected " + className,
					Toast.LENGTH_SHORT).show();
			LocalBinder binder = (LocalBinder) service;
			videoStreamingReceiverClient = new VideoStreamingReceiverClient(binder.getService());
			changePauseState(false);
		}

		public void onServiceDisconnected(ComponentName className) {
			Toast.makeText(ClientActivity.this, "Service disconnected " + className,
					Toast.LENGTH_SHORT).show();			
			changePauseState(true);
		}
	};
	private TextView textViewStatus;
	protected int displayed;
	protected int underflow;

	/** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        startService(); 
        setContentView(R.layout.main);
        imageView = (ImageView) findViewById(R.id.imageView1);
        textViewStatus = (TextView) findViewById(R.id.textViewStatus);
    }
    
	@Override
	protected void onStart() {
		super.onStart();
        bindService();	
	}

	@Override
	protected void onStop() {
		super.onStop();
		unbindService(mConnection);
	}
	
	private void startService() {
		Intent intent = new Intent(this, VideoStreamingReceiverService.class);
		//we start the service with the intent to make sure that it always
		//runs in the background even if we unbind from the service.
		ComponentName componentName = startService(intent);
		if (componentName == null) {
			Toast.makeText(this, "Could not connect to service",
					Toast.LENGTH_SHORT).show();
		} 	
	}

	private void bindService() {
		Toast.makeText(this, "Connecting to service " + VideoStreamingReceiverService.class.getName(),
				Toast.LENGTH_SHORT).show();
		// Bind to the service
		bindService(new Intent(this, VideoStreamingReceiverService.class),
				mConnection, Context.BIND_AUTO_CREATE);
	}

    
	private Runnable imageUpdaterRunnable = new Runnable() {
		@Override
		public void run() {
			//Log.d(TAG, "Updating client UI");
			textViewStatus.setText(videoStreamingReceiverClient.getStatus() +  " display fps: " + displayed * 1000
					/ (System.currentTimeMillis() - startTime) 
					+ " underflow (Hz) " + (System.currentTimeMillis() - startTime)/((underflow+1)*1000)
					+ " received " + displayed);
			Bitmap nextBitmap = videoStreamingReceiverClient.getNextBitmap();
			if(nextBitmap != null) {
				imageView.setImageBitmap(nextBitmap);
				displayed++;
			} else {
				underflow++;
			}
			lock.lock();
			try {
				if(!isPaused) {
					imageUpdaterHandler.postDelayed(imageUpdaterRunnable, 40);
				}
			} finally {
				lock.unlock();
			}
		}
	};
}