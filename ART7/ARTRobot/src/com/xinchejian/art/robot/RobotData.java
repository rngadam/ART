package com.xinchejian.art.robot;


public class RobotData {
	public static final byte FORWARD_RIGHT_INFRARED = 1;
	public static final byte FORWARD_LEFT_INFRARED = 1<<1;
	public static final byte LEFT_INFRARED = 1<<2;
	public static final byte RIGHT_INFRARED = 1<<3;
	public static final byte BACKWARD_INFRARED = 1<<4;
	public static final byte FORWARD_INFRARED = 1<<5;
	
	public byte collisions = 0;
}
