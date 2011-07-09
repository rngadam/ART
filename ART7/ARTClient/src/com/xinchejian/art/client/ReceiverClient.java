package com.xinchejian.art.client;

import com.xinchejian.art.robot.RobotCommands;
import com.xinchejian.art.robot.RobotData;

import android.graphics.Bitmap;

public class ReceiverClient {
	private final ReceiverService service;

	public ReceiverClient(ReceiverService service) {
		this.service = service;
	}

	public Bitmap getNextBitmap() {
		return service.getNextBitmap();
	}

	public RobotData getRobotData() {
		return service.getRobotData();
	}

	public String getStatus() {
		return service.getStatus();
	}

	public void send(RobotCommands robotCommands) {
		service.send(robotCommands);
	}

}
