package com.xinchejian.art.server;

import com.xinchejian.art.robot.RobotCommands;
import com.xinchejian.art.robot.RobotData;
import com.xinchejian.art.robot.RobotData.RobotSensors;

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

	public RobotCommands getCurrentCommand() {
		return service.getCurrentCommand();
	}

	public RobotData getCurrentData() {
		return service.getCurrentData();
	}

	public void simulateCollision(RobotSensors robotSensor, boolean state) {
		service.simulateCollision(robotSensor, state);
	}
}
