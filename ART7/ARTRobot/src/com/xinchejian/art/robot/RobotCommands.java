package com.xinchejian.art.robot;


public class RobotCommands {
	public static enum Directions {
		NEUTRAL,
		FORWARD_LEFT,
		FORWARD,
		FORWARD_RIGHT,
		REVERSE_LEFT,
		REVERSE,
		REVERSE_RIGHT
	}

	public Directions direction = Directions.NEUTRAL;
}
