package com.xinchejian.art.server;

import com.xinchejian.art.robot.RobotCommands;
import com.xinchejian.art.robot.RobotData;

public class SenderServiceClient {
	private final SenderService service;

	public SenderServiceClient(SenderService service) {
		this.service = service;
	}

	public String getIp() {
		return service.getLocalIpAddress();
	}

	public String getStatus() {
		return service.getStatus();
	}

	public void send(RobotData robotData) {
		service.send(robotData);
	}

	public RobotCommands getRobotCommands() {
		return service.getRobotCommands();
	}
}
