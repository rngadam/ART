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
DFR15 METAL GEAR SERVO
Voltage: +4.8-7.2V
Current: 180mA(4.8V)；220mA（6V）
Speed(no load)：0.17 s/60 degree (4.8V);0.25 s/60 degree (6.0V)
Torque：10Kg·cm(4.8V) 12KG·cm(6V) 15KG·cm(7.2V)
Temperature:0-60 Celius degree
Size：40.2 x 20.2 x 43.2mm
Weight：48g
*/
const int SERVO_TURN_RATE_PER_SECOND = 300; // 60/0.2

/* 
HC-SR04 Ultrasonic sensor
effectual angle: <15°
ranging distance : 2cm – 500 cm
resolution : 0.3 cm
*/
const int SENSOR_LOOKING_FORWARD_ANGLE = 90; 
// rotating counterclockwise...
const int SENSOR_LOOKING_LEFT_ANGLE = 135; 
const int SENSOR_LOOKING_RIGHT_ANGLE = 45; 
const int SENSOR_ARC_DEGREES = 15; // 180, 90, 15 all divisible by 15
const int MAXIMUM_SENSOR_SERVO_ANGLE = 180;
const int MINIMUM_SENSOR_SERVO_ANGLE = 1;
const int NUMBER_READINGS = MAXIMUM_SENSOR_SERVO_ANGLE/SENSOR_ARC_DEGREES; // 180/15 = 12 reading values in front
const int SENSOR_LOOKING_FORWARD_READING_INDEX = SENSOR_LOOKING_FORWARD_ANGLE/SENSOR_ARC_DEGREES; // 90/15 = 6
const int SENSOR_PRECISION_CM = 1;
// speed of sound at sea level = 340.29 m / s
// spec range is 5m * 2 (return) = 10m
// 10 / 341 = ~0.029
const int SENSOR_MINIMAL_WAIT_ECHO_MILLIS = 29;

/*
Robot related information
*/
const int ROBOT_TURN_RATE_PER_SECOND = 90;
const int SAFE_DISTANCE = 50;
const int CRITICAL_DISTANCE = 20;
enum states {
  SWEEPING = 'S',
  GO = 'G',
  DECISION = 'D',
  STUCK = 'K',
  TURN = 'T',
};



// Global variable
// this contains readings from a sweep
int sensor_distance_readings_cm[NUMBER_READINGS];
const int NO_READING = -1;
// we start with a sweep
char current_state = SWEEPING;
// contains target angle
int turn_towards;

enum {
  WAIT_FOR_SERVO_TO_TURN,
  WAIT_FOR_ROBOT_TO_TURN,
  WAIT_FOR_ECHO,
  WAIT_ARRAY_SIZE
};

int timed_operation_initiated_millis[WAIT_ARRAY_SIZE];
int timed_operation_desired_wait_millis[WAIT_ARRAY_SIZE];

// variables to store the servo current and desired angle 
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
  for(int i=0; i<WAIT_ARRAY_SIZE; i++) {
    timed_operation_initiated_millis[i] = 0;  
    timed_operation_desired_wait_millis[i] = 0;
  }
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
void start_timed_operation(int index, int duration) {
  timed_operation_initiated_millis[index] = millis();
  timed_operation_desired_wait_millis[index] = duration;
  Serial.print("Timer added type ");
  Serial.print(index);
  Serial.print(" wait in millis:");
  Serial.println(duration);
}

/*
Check whether the timer has expired
if expired, returns true
if not expired, returns false
*/
boolean timed_operation_expired(int index) {
  int current_time = millis();
  if((current_time - timed_operation_initiated_millis[index]) < timed_operation_desired_wait_millis[index]) {
    return false;
  }
  return true;
}

int expected_wait_millis(int turn_rate, int initial_angle, int desired_angle) {
  int delta;
  if(initial_angle < 1 || desired_angle < 1) { 
    return 0;
  } else if(initial_angle == desired_angle) {
    return 0;
  } else if(initial_angle > desired_angle) {
    delta = initial_angle - desired_angle;
  } else {
    delta = desired_angle - initial_angle;
  }
  return (float(delta)/float(turn_rate))*1000.0;
}

int convert_reading_index(int angle) {
  return angle/SENSOR_ARC_DEGREES;
}

int read_sensor(int angle) {
  int index = convert_reading_index(angle);
  
  if(!timed_operation_expired(WAIT_FOR_ECHO)) {
    return NO_READING;
  }
  
  int measured_value = sensor.Ranging(CM);
  
  start_timed_operation(WAIT_FOR_ECHO, SENSOR_MINIMAL_WAIT_ECHO_MILLIS);
  
  if(abs(measured_value - sensor_distance_readings_cm[index]) > SENSOR_PRECISION_CM) {
    sensor_distance_readings_cm[index] = measured_value;
    Serial.print("Sensor reading:");
    Serial.print(angle);
    Serial.print(":");
    Serial.println(sensor_distance_readings_cm[index]);
  }
  return sensor_distance_readings_cm[index];
}

/*
Read the current angle and store it in the readings array
Find the next angle that has no reading
If found, set the desired angle to that and return false
If not found, returns true
*/

void start_sweep() {
  current_state = SWEEPING;
  /*for(int i=0; i<NUMBER_READINGS; i++) {
    sensor_distance_readings_cm[i] = NO_READING;
  }*/
  desired_sensor_servo_angle = MINIMUM_SENSOR_SERVO_ANGLE;
}

boolean sensor_sweep() {
  if(!timed_operation_expired(WAIT_FOR_SERVO_TO_TURN)) {
    return false;
  }
  
  // read current position
  if(read_sensor(current_sensor_servo_angle) == NO_READING) {
    return false;
  }

  desired_sensor_servo_angle += SENSOR_ARC_DEGREES;
  
  // has a reading already, so we will get a new value but first check we haven't exceeded limits of servo
  if(desired_sensor_servo_angle >= MAXIMUM_SENSOR_SERVO_ANGLE) {
    desired_sensor_servo_angle = MAXIMUM_SENSOR_SERVO_ANGLE;
    return true;
  } 
  
  if(desired_sensor_servo_angle <= MINIMUM_SENSOR_SERVO_ANGLE) {
    desired_sensor_servo_angle = MINIMUM_SENSOR_SERVO_ANGLE;    
  }
  
  return false; 
}

void update_servo_position() {  
  if(current_sensor_servo_angle != desired_sensor_servo_angle) {
    sensor_servo.write(desired_sensor_servo_angle-1);              // tell servo to go to position in variable 'pos' 

    int wait_millis = expected_wait_millis(SERVO_TURN_RATE_PER_SECOND, current_sensor_servo_angle, desired_sensor_servo_angle);
    start_timed_operation(WAIT_FOR_SERVO_TO_TURN, wait_millis);

    current_sensor_servo_angle = desired_sensor_servo_angle;

    Serial.print("SERVO:");
    Serial.println(desired_sensor_servo_angle);
  }
}


boolean potential_collision() {
  read_sensor(SENSOR_LOOKING_FORWARD_ANGLE);
  return sensor_distance_readings_cm[SENSOR_LOOKING_FORWARD_READING_INDEX] <= SAFE_DISTANCE;
}

boolean imminent_collision() {
  read_sensor(SENSOR_LOOKING_FORWARD_ANGLE);
  return sensor_distance_readings_cm[SENSOR_LOOKING_FORWARD_READING_INDEX] <= CRITICAL_DISTANCE;
}

int find_best_direction_degrees() {
  int longest_value = -1;
  int longest_index = -1;
  for(int i=0; i<NUMBER_READINGS; i++) {
    if(sensor_distance_readings_cm[i] > longest_value && sensor_distance_readings_cm[i] >= SAFE_DISTANCE) {
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
    go(RIGHT);
  } 
  else {
    go(LEFT);
  }
  go(FORWARD);
  int expected_wait = expected_wait_millis(ROBOT_TURN_RATE_PER_SECOND, SENSOR_LOOKING_FORWARD_ANGLE, turn_towards);
  start_timed_operation(WAIT_FOR_ROBOT_TO_TURN, expected_wait);
  Serial.print("Waiting for robot to turn millis: ");
  Serial.println(expected_wait);
}

boolean handle_turn() {
  // turn until we expect to meet the desired angle
  return timed_operation_expired(WAIT_FOR_ROBOT_TO_TURN);
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
    if(imminent_collision()) {
      full_stop();
    }
    if(handle_turn()) {
      // we've turned! reset and try to move forward now
      full_stop();
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

