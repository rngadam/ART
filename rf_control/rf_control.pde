// Introduction to PWM
// http://www.netrino.com/Embedded-Systems/How-To/PWM-Pulse-Width-Modulation
// http://www.vmsk.org/Pulses.pdf
// testing
// http://www.circuit-finder.com/categories/tools-and-measuring/component-tester/448/xtal-tester
// Servo fundamentals
// http://www.princeton.edu/~mae412/TEXT/NTRAK2002/292-302.pdf
// RC transmitter
// http://talkingelectronics.com/projects/27MHz%20Transmitters/27MHzLinks-1.html
// TX2C
// http://www.datasheetarchive.com/pdf-datasheets/Datasheets-23/DSA-446609.html
const int FORWARD_PULSES = 16;
const int REVERSE_PULSES = 40;
const int FORWARD_LEFT_PULSES = 28;
const int FORWARD_RIGHT_PULSES = 34;
const int REVERSE_LEFT_PULSES = 52;
const int REVERSE_RIGHT_PULSES = 46;

const int CONTROL_PULSES = 4;
const int CONTROL_DUTY_CYCLE = 191; // 75% duty cycle
const int CONTROL_PERIOD_PER_PULSE_US = 2800;

const int SEGMENT_DUTY_CYCLE = 127; // 50% duty cycle
const int SEGMENT_PERIOD_PER_PULSE_US = 1400;

const int CONTROL_ICR = 35;
const int SEGMENT_ICR = 175;

const int OUTPUT_PIN = 11;

enum { 
	FORWARD, 
	REVERSE, 
	FORWARD_LEFT, 
	FORWARD_RIGHT, 
	REVERSE_LEFT, 
	REVERSE_RIGHT 
};

void setup() {
	// Pins 11 and 3: controlled by timer 2
	// this sets the prescaler to /64
	// http://www.arduino.cc/playground/Main/TimerPWMCheatsheet
	// TCCR2B = TCCR2B & 0b11111000 | 0x04;
	pinMode(OUTPUT_PIN, OUTPUT);
}

/*
void go(int direction, int duration_ms) {
	int start = millis();
	while((millis() - start) < duration_ms) {
		ICR1 = CONTROL_ICR;
		analogWrite(OUTPUT_PIN, CONTROL_DUTY_CYCLE);
		delayMicroseconds(CONTROL_PULSES * CONTROL_PERIOD_PER_PULSE_US);
		
		ICR1 = SEGMENT_ICR;
		analogWrite(OUTPUT_PIN, SEGMENT_DUTY_CYCLE);
		delayMicroseconds(direction * SEGMENT_PERIOD_PER_PULSE_US);
	}
}
*/

void go(int direction, int duration_ms) {
	int start = millis();
	while((millis() - start) < duration_ms) {
		for(int i=0; i<4; i++) {
			digitalWrite(OUTPUT_PIN, HIGH);
			delayMicroseconds(2100);
			digitalWrite(OUTPUT_PIN, LOW);
			delayMicroseconds(700);
		}
		for(int i=0; i<direction; i++) {
			digitalWrite(OUTPUT_PIN, HIGH);
			delayMicroseconds(700);
			digitalWrite(OUTPUT_PIN, LOW);
			delayMicroseconds(700);
		}
	}
}
void loop() {
	go(FORWARD_PULSES, 1000);
	go(REVERSE_PULSES, 1000);
}

