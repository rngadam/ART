package com.xinchejian.art;

import com.xinchejian.art.RobotService.directions;

public class RobotServiceClient {
	public String getLocalIpAddress() {
		return service.getLocalIpAddress();
	}

	private final RobotService service;

	public RobotServiceClient(RobotService service) {
		this.service = service;
	}

	public boolean isThreadRunning() {
		return service.isThreadRunning();
	}

	public int getMessagesReceived() {
		return service.getMessagesReceived();
	}

	public int getCurrentState() {
		return service.getCurrentState();
	}

	public void go(directions direction) {
		service.go(direction);
	}
}
