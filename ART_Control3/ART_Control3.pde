#include <Ultrasonic.h>
#include <Servo.h> 
#include <limits.h>

// various directions we can go to
const int FORWARD =  2;      // the number of the LED pin
const int REVERSE =  3;  
const int LEFT = 4;  
const int RIGHT =  5;  

// Arduino pins mapping
const int SENSOR_SERVO = 11;
const int ULTRASONIC_TRIG = 8;
const int ULTRASONIC_ECHO = 9;


/*
We're sweeping the servo either left or right
*/
const boolean SERVO_MOVING_LEFT = true;
const boolean SERVO_MOVING_RIGHT = false;

/* 
HC-SR04 Ultrasonic sensor
effectual angle: <15°
ranging distance : 2cm – 500 cm
resolution : 0.3 cm
*/
const byte SENSOR_LOOKING_FORWARD_ANGLE = 90; 
const byte SENSOR_ARC_DEGREES = 15; // 180, 90, 15 all divisible by 15
const int MAXIMUM_SENSOR_SERVO_ANGLE = 180;
const int MINIMUM_SENSOR_SERVO_POS = 1;
const int NUMBER_READINGS = MAXIMUM_SENSOR_SERVO_ANGLE/SENSOR_ARC_DEGREES; // 180/15 = 12
const int SENSOR_LOOKING_FORWARD_READING_INDEX = SENSOR_LOOKING_FORWARD_ANGLE/SENSOR_ARC_DEGREES; // 90/15 = 6

/*
Robot related information
*/
const int MINIMUM_DISTANCE = 50;

enum states {
  SWEEPING = 'S',
  GO = 'G',
  DECISION = 'D',
  STUCK = 'K',
  TURN = 'T',
};



// Global variable
// first sweep we move from left to right
boolean servo_dir = SERVO_MOVING_RIGHT;
// this contains readings from a sweep
int sensor_distance_readings_cm[NUMBER_READINGS];
const int NO_READING = -1;
// we start with a sweep
char current_state = SWEEPING;
// contains target angle
int turn_towards;

int timed_operation_initiated_millis = 0;

// variable to store the servo current and desired angle 
int desired_sensor_servo_angle = SENSOR_LOOKING_FORWARD_ANGLE;   
int current_sensor_servo_angle = 0;

// Two useful objects...
Servo sensor_servo;  // create servo object to control a servo 
Ultrasonic sensor = Ultrasonic(ULTRASONIC_TRIG, ULTRASONIC_ECHO);

void setup() { 
  // these map to the contact switches on the RF
  pinMode(FORWARD, OUTPUT);     
  pinMode(REVERSE, OUTPUT);    
  pinMode(LEFT, OUTPUT);  
  pinMode(RIGHT, OUTPUT);  
  full_stop();
  sensor_servo.attach(SENSOR_SERVO);

  Serial.begin(9600);
}

/*
Makes sure that exclusive directions are prohibited
*/
void go(int dir) {
  
  switch(dir) {
  case FORWARD:
    digitalWrite(REVERSE, LOW);
    digitalWrite(FORWARD, HIGH);   
    break;
  case REVERSE:
    digitalWrite(FORWARD, LOW);   
    digitalWrite(REVERSE, HIGH);   
    break;  
  case LEFT:
    digitalWrite(RIGHT, LOW);   
    digitalWrite(LEFT, HIGH);   
    break;
  case RIGHT:
    digitalWrite(LEFT, LOW);   
    digitalWrite(RIGHT, HIGH);   
    break;            
  }
}

void suspend(int dir) {
  digitalWrite(dir, LOW);
}

void full_stop() {
  digitalWrite(FORWARD, LOW);
  digitalWrite(REVERSE, LOW);
  digitalWrite(LEFT, LOW);
  digitalWrite(RIGHT, LOW);
}


/*
record current time to compare to
*/
void start_timed_operation() {
  timed_operation_initiated_millis = millis();
}

/*
Check whether the timer has expired
if expired, returns true
if not expired, returns false
*/
boolean timed_operation_expired(int duration_millis) {
  int current_time = millis();
  if((current_time - timed_operation_initiated_millis) < duration_millis) {
    return false;
  }
  return true;
}


int convert_reading_index(int angle) {
  return angle/SENSOR_ARC_DEGREES;
}

void read_sensor(int angle) {
  int index = convert_reading_index(angle);
  sensor_distance_readings_cm[index] = sensor.Ranging(CM);
  Serial.print("Sensor reading:");
  Serial.print(angle);
  Serial.print(":");
  Serial.println(sensor_distance_readings_cm[index]);
}

/*
Read the current angle and store it in the readings array
Find the next angle that has no reading
If found, set the desired angle to that and return false
If not found, returns true
*/

boolean sensor_sweep() {
  // read current position
  read_sensor(current_sensor_servo_angle);
  for(int i=0; i<NUMBER_READINGS*2; i++) {
    desired_sensor_servo_angle += (servo_dir == SERVO_MOVING_RIGHT ? 1 : -1) * SENSOR_ARC_DEGREES;
    if(sensor_distance_readings_cm[convert_reading_index(desired_sensor_servo_angle)] == NO_READING) {
      // the next desired position does indeed not have a reading
      // so we can read that position next time sensor_sweep is called
      return false;
    }
    // has a reading already, so we will get a new value but first check we haven't exceeded limits of servo
    if(desired_sensor_servo_angle >= MAXIMUM_SENSOR_SERVO_ANGLE) {
      servo_dir = !servo_dir;
      desired_sensor_servo_angle = MAXIMUM_SENSOR_SERVO_ANGLE;
    } 
    else if(desired_sensor_servo_angle <= MINIMUM_SENSOR_SERVO_POS) {
      servo_dir = !servo_dir;
      desired_sensor_servo_angle = MINIMUM_SENSOR_SERVO_POS;    
    }
  }
  // no NO_READING values left so the sweep is completed!
  desired_sensor_servo_angle = SENSOR_LOOKING_FORWARD_ANGLE;
  return true; 
}

void update_servo_position() {
  if(current_sensor_servo_angle != desired_sensor_servo_angle) {
    sensor_servo.write(desired_sensor_servo_angle-1);              // tell servo to go to position in variable 'pos' 
    current_sensor_servo_angle = desired_sensor_servo_angle;
    Serial.print("SERVO:");
    Serial.print(servo_dir);
    Serial.println(desired_sensor_servo_angle);
    delay(500); // wait for the servo to get there!
  }
}

void start_sweep() {
  current_state = SWEEPING;
  for(int i=0; i<NUMBER_READINGS; i++) {
    sensor_distance_readings_cm[i] = NO_READING;
  }
  desired_sensor_servo_angle = MINIMUM_SENSOR_SERVO_POS;
}

boolean potential_collision() {
  read_sensor(SENSOR_LOOKING_FORWARD_ANGLE);
  return sensor_distance_readings_cm[SENSOR_LOOKING_FORWARD_READING_INDEX] <= MINIMUM_DISTANCE;
}

int find_best_direction_degrees() {
  int longest_value = -1;
  int longest_index = -1;
  for(int i=0; i<NUMBER_READINGS; i++) {
    if(sensor_distance_readings_cm[i] > longest_value) {
      longest_value = sensor_distance_readings_cm[i];
      longest_index = i;
    }
  }
  if(longest_index != -1) {
    return longest_index * SENSOR_ARC_DEGREES;
  }
  return NO_READING;
}

void start_turn() {
  current_state = TURN;
  desired_sensor_servo_angle = SENSOR_LOOKING_FORWARD_ANGLE;
  if(turn_towards < SENSOR_LOOKING_FORWARD_ANGLE) {
    go(LEFT);
  } 
  else {
    go(RIGHT);
  }
  go(FORWARD);
  start_timed_operation();
}

boolean handle_turn() {
  return timed_operation_expired(2000);
}

void loop(){
  int initial_state = current_state;
  switch(current_state) {
  case SWEEPING:
    if(sensor_sweep()) {
      // sweep completed, decision time!
      current_state = DECISION;
      desired_sensor_servo_angle = SENSOR_LOOKING_FORWARD_ANGLE;
    } // else keep sweeping!
    break;
  case GO: 
    if(potential_collision()) {
      // we're going to crash into something, stop and find an alternative
      full_stop();
      start_sweep();
    } 
    else {
      // keep moving!
      go(FORWARD);
    }
    break;
  case DECISION:
    // we want to turn towards the longest opening
    turn_towards = find_best_direction_degrees();
    if(turn_towards != NO_READING) {
      start_turn();
    } 
    else {
      current_state = STUCK;
    }
    break;
  case STUCK:
    // TODO: check if we can reverse...
    // for now... re-sweep, maybe the obstacle will go away...
    current_state = SWEEPING;
    break;
  case TURN:
    if(potential_collision()) {
      full_stop();
    }
    if(handle_turn()) {
      // we've turned! try to move forward now
      current_state = GO;
    }
    break;
  default:
    Serial.println("BAD STATE!");
    break;
  }
  
  // states above update servo position
  update_servo_position();

  if(initial_state != current_state) {
    Serial.print("INITIAL STATE:");
    Serial.print((char)initial_state);
    Serial.print(" FINAL STATE:");
    Serial.println((char)current_state);
  }
}

