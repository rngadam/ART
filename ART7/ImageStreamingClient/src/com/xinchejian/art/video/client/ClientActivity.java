package com.xinchejian.art.video.client;

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
import android.widget.Toast;

import com.xinchejian.art.video.client.VideoStreamingReceiverService.LocalBinder;

public class ClientActivity extends Activity {
    @Override
	protected void onPause() {
		super.onPause();
	}

	@Override
	protected void onResume() {
		super.onResume();
        bindService();		
	}

	protected static final String TAG = ClientActivity.class.getCanonicalName();
	private ImageView imageView;
	private Handler imageUpdaterHandler = new Handler();
	private VideoStreamingReceiverClient videoStreamingReceiverClient;

	private ServiceConnection mConnection = new ServiceConnection() {

		public void onServiceConnected(ComponentName className, IBinder service) {
			LocalBinder binder = (LocalBinder) service;
			videoStreamingReceiverClient = new VideoStreamingReceiverClient(binder.getService());
			imageUpdaterHandler.postDelayed(imageUpdaterRunnable, 1000);
		}

		public void onServiceDisconnected(ComponentName className) {
			imageUpdaterHandler.removeCallbacks(imageUpdaterRunnable);
			videoStreamingReceiverClient = null;
		}
	};
	
	public void startService() {
		Intent intent = new Intent(this, VideoStreamingReceiverService.class);
		//we start the service with the intent to make sure that it always
		//runs in the background even if we unbind from the service.
		ComponentName componentName = startService(intent);
		if (componentName == null) {
			Toast.makeText(this, "Could not connect to service",
					Toast.LENGTH_SHORT).show();
		} else {
			bindService();
		}		
	}

	private void bindService() {
		Toast.makeText(this, "Connecting to service " + VideoStreamingReceiverService.class.getName(),
				Toast.LENGTH_SHORT).show();
		// Bind to the service
		bindService(new Intent(this, VideoStreamingReceiverService.class),
				mConnection, Context.BIND_AUTO_CREATE);
	}
	
	/** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        startService(); 
        setContentView(R.layout.main);
        imageView = (ImageView) findViewById(R.id.imageView1);
    }
    
	private Runnable imageUpdaterRunnable = new Runnable() {
		@Override
		public void run() {
			Bitmap nextBitmap = videoStreamingReceiverClient.getNextBitmap();
			if(nextBitmap != null) {
				imageView.setImageBitmap(nextBitmap);
			}
			imageUpdaterHandler.postDelayed(imageUpdaterRunnable, 200);
		}
	};
}