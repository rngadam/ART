package com.xinchejian.art.robot;


public class RobotData extends RobotUpdatable {
	@Override
	public String toString() {
		return super.toString() 
			+ " collisions: " + getCollisions();
	}
	
	public static enum RobotSensors {
		FORWARD_RIGHT_INFRARED,
		FORWARD_LEFT_INFRARED,
		LEFT_INFRARED,
		RIGHT_INFRARED,
		BACKWARD_INFRARED ,
		FORWARD_INFRARED,
	}
	
	private static byte robotSensorsMasks[] = {
		1,
		1 << 1,
		1 << 2,
		1 << 3,
		1 << 4,
		1 << 5,		
	};
	
	private byte collisions = 0;
	
	public boolean isCollisionDetected(RobotSensors sensor) {
		return (robotSensorsMasks[sensor.ordinal()] & collisions) != 0 ;
	}
	public void setCollisions(byte collisions) {
		this.collisions = collisions;
		updated();
	}

	public byte getCollisions() {
		return collisions;
	}
	
	public void setCollision(RobotSensors sensor, boolean state) {
		byte collision = getCollisions();
		if(state)
			collision |= robotSensorsMasks[sensor.ordinal()];
		else
			collision &= ~robotSensorsMasks[sensor.ordinal()];
			
		setCollisions(collision);
	}
	public void update(RobotData robotData) {
		if(robotData == null) {
			return;
		}
		if(!this.equals(robotData)) {
			this.setCollisions(robotData.getCollisions());
		}
	}
}
