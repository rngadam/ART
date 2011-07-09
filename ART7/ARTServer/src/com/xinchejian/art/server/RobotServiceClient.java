package com.xinchejian.art.server;

import com.xinchejian.art.robot.RobotCommands;

public class RobotServiceClient {
	private final RobotService service;

	public RobotServiceClient(RobotService service) {
		this.service = service;
	}

	public int getCurrentState() {
		return service.getCurrentState();
	}

	public String getCurrentStateName() {
		return service.getCurrentStateName();
	}

	public String getLocalIpAddress() {
		return service.getLocalIpAddress();
	}

	public int getMessagesReceived() {
		return service.getMessagesReceived();
	}

	public void go(RobotCommands.Directions direction) {
		service.go(direction);
	}
}
