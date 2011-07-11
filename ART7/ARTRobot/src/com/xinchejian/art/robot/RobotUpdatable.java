package com.xinchejian.art.robot;

public class RobotUpdatable {

	@Override
	public boolean equals(Object arg0) {
		if(arg0 == null)
			return false;
		if(!(arg0 instanceof RobotUpdatable))
			return false;
		if(((RobotUpdatable)arg0).getLastUpdate() != getLastUpdate())
			return false;
		return true;
			
	}

	@Override
	public int hashCode() {
		return (int) getLastUpdate();
	}

	@Override
	public String toString() {
		return "" + (getLastUpdate() & 0xFFFFF);
	}

	private long lastUpdate = System.currentTimeMillis();

	public RobotUpdatable() {
		super();
	}

	protected void updated() {
		setLastUpdate(System.currentTimeMillis());
	}

	public void setLastUpdate(long lastUpdate) {
		this.lastUpdate = lastUpdate;
	}

	public long getLastUpdate() {
		return lastUpdate;
	}

}