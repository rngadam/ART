package com.xinchejian.art.client;

import android.app.Activity;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.widget.EditText;

public class SettingsActivity extends Activity {

	private EditText editTextServerPort;
	private EditText editTextServerIp;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
        setContentView(R.layout.settings);
        editTextServerIp = (EditText) findViewById(R.id.editTextServerIp);
        editTextServerPort = (EditText) findViewById(R.id.editTextServerPort);
        SharedPreferences preferences = getSharedPreferences(ClientConstants.PREFS_STORE, MODE_WORLD_WRITEABLE);
        editTextServerIp.setText(preferences.getString(ClientConstants.SERVER_IP_PREF, ClientConstants.DEFAULT_IP));
        editTextServerPort.setText("" + preferences.getInt(ClientConstants.SERVER_PORT_PREF, ClientConstants.DEFAULT_PORT));
	}

	@Override
	protected void onStop(){
	   super.onStop();
	
	  // We need an Editor object to make preference changes.
	  // All objects are from android.context.Context
	  SharedPreferences settings = getSharedPreferences(ClientConstants.PREFS_STORE, MODE_WORLD_WRITEABLE);
	  SharedPreferences.Editor editor = settings.edit();
	  editor.putString(ClientConstants.SERVER_IP_PREF, editTextServerIp.getText().toString());
	  editor.putInt(ClientConstants.SERVER_PORT_PREF, Integer.valueOf(editTextServerPort.getText().toString()));
	
	  // Commit the edits!
	  editor.commit();
	}	

}
