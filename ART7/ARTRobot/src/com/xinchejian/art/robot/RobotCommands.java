package com.xinchejian.art.robot;

public class RobotCommands extends RobotUpdatable {
	public static enum Directions {
		NEUTRAL, FORWARD_LEFT, FORWARD, FORWARD_RIGHT, REVERSE_LEFT, REVERSE, REVERSE_RIGHT
	}

	private Directions direction = Directions.NEUTRAL;

	public void setDirection(Directions direction) {
		this.direction = direction;
		updated();
	}

	public Directions getDirection() {
		return direction;
	}
	
	@Override
	public String toString() {
		return super.toString() 
			+ " direction: " + getDirection().name();
	}

	public void update(RobotCommands robotCommands) {
		if(!this.equals(robotCommands)) {
			setDirection(robotCommands.getDirection());
		}
	}	
}
