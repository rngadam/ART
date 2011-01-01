#include <Ultrasonic.h>
#include <Servo.h> 
#include <limits.h>

enum LOG_LEVELS {
   ERROR,
   INFO,
   DEBUG,
   TRACE,
};
int LOG_LEVEL = TRACE;

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
Temperature:0-60 Celcius degree
Size：40.2 x 20.2 x 43.2mm
Weight：48g
*/
const int SERVO_TURN_RATE_PER_SECOND = 100; // 100 = 60/(0.2*3) where 3 is caused by load?

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
const int MINIMUM_SENSOR_SERVO_ANGLE = 0;
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
const int FORWARD_TIME_UNIT_MILLIS = 1000;

enum states {
  // start state
  INITIAL = 'I',
  FULL_SWEEP = 'S',
  QUICK_SWEEP = 'Q',
  // dynamic requires fast sensor readings
  DYNAMIC_FORWARD = 'F',
  DYNAMIC_REVERSE = 'B',
  DYNAMIC_TURN = 'T',
  DECISION = 'D',
  // units advancement
  FORWARD_LEFT_UNIT = '1',
  FORWARD_UNIT = '2',
  FORWARD_RIGHT_UNIT = '3',
  REVERSE_LEFT_UNIT = '4',
  REVERSE_UNIT = '5',
  REVERSE_RIGHT_UNIT = '6',
  // decision making
  QUICK_DECISION = '?',
  REVERSE_QUICK_DECISION = '<',
  
  // end state
  STUCK = 'K',
};

// Global variable
// this contains readings from a sweep
int sensor_distance_readings_cm[NUMBER_READINGS];
const int NO_READING = -1;
char current_state = INITIAL;
// contains target angle
int turn_towards;

enum {
  WAIT_FOR_SERVO_TO_TURN,
  WAIT_FOR_ROBOT_TO_TURN,
  WAIT_FOR_ECHO,
  WAIT_FOR_ROBOT_TO_MOVE,
  WAIT_FOR_ROBOT_TO_ADVANCE_UNIT,
  WAIT_ARRAY_SIZE, // always last...
};

int timed_operation_initiated_millis[WAIT_ARRAY_SIZE];
int timed_operation_desired_wait_millis[WAIT_ARRAY_SIZE];

// variables to store the servo current and desired angle 
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
  safe_update_servo_position(SENSOR_LOOKING_FORWARD_ANGLE);   
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
  if(LOG_LEVEL >= TRACE) {
    Serial.print("Timer added type ");
    Serial.print(index);
    Serial.print(" wait in millis:");
    Serial.println(duration);
  }
}

/*
Check whether the timer has expired
if expired, returns true else returns false
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
  if(initial_angle < 0 || desired_angle < 0) { 
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

int read_sensor() {
  if(!timed_operation_expired(WAIT_FOR_SERVO_TO_TURN)) {
    return NO_READING;
  }
  
  if(!timed_operation_expired(WAIT_FOR_ECHO)) {
    return NO_READING;
  }
  
  int measured_value = sensor.Ranging(CM);
  
  start_timed_operation(WAIT_FOR_ECHO, SENSOR_MINIMAL_WAIT_ECHO_MILLIS);
  
  int index = convert_reading_index(current_sensor_servo_angle);
  // only update if the value is different beyond precision of sensor
  if(abs(measured_value - sensor_distance_readings_cm[index]) > SENSOR_PRECISION_CM) {
    sensor_distance_readings_cm[index] = measured_value;
  }
  if(LOG_LEVEL >= INFO) {
    Serial.print("Sensor reading:");
    Serial.print(current_sensor_servo_angle);
    Serial.print(":");
    Serial.println(sensor_distance_readings_cm[index]);
  }
  return sensor_distance_readings_cm[index];
}

int get_last_reading_for_angle(int angle) {
  return sensor_distance_readings_cm[convert_reading_index(angle)];
}

/*
Initialize sweep (setting state and position sensor to be ready)
*/
void init_sweep() {
  current_state = FULL_SWEEP;
  safe_update_servo_position(MINIMUM_SENSOR_SERVO_ANGLE);
}

/*
Read the current angle and store it in the readings array
Find the next angle that has no reading
If found, set the desired angle to that and return false
If not found, returns true
*/
boolean sensor_sweep() {
  // read current value
  if(read_sensor() == NO_READING) {
    return false;
  }

  // we have a valid value, so move to the next  position
  int desired_sensor_servo_angle = current_sensor_servo_angle + SENSOR_ARC_DEGREES;
  
  // we've completed from MINIMUM_SENSOR_SERVO_ANGLE to MAXIMUM_SENSOR_SERVO_ANGLE
  if(desired_sensor_servo_angle > MAXIMUM_SENSOR_SERVO_ANGLE) {
    return true;
  } 
  
  // we always use read_sensor() before reaching here
  update_servo_position(desired_sensor_servo_angle);
  // keep doing the sweep
  return false; 
}

/*
make sure that the servo is at target position before returning
if you don't use this, you need to check yourself that the timer has expired...
*/
void safe_update_servo_position(int desired_sensor_servo_angle) {  
    update_servo_position(desired_sensor_servo_angle);
    while(!timed_operation_expired(WAIT_FOR_SERVO_TO_TURN)) {
      delay(10);
    }
}

void update_servo_position(int desired_sensor_servo_angle) {  
  if(current_sensor_servo_angle != desired_sensor_servo_angle) {
    sensor_servo.write(desired_sensor_servo_angle-1);              // tell servo to go to position in variable 'pos' 

    int wait_millis = expected_wait_millis(SERVO_TURN_RATE_PER_SECOND, current_sensor_servo_angle, desired_sensor_servo_angle);
    start_timed_operation(WAIT_FOR_SERVO_TO_TURN, wait_millis);

    current_sensor_servo_angle = desired_sensor_servo_angle;
    if(LOG_LEVEL >= DEBUG) {
      Serial.print("SERVO:");
      Serial.println(desired_sensor_servo_angle);
    }
  }
}

boolean potential_collision() {
  return sensor_distance_readings_cm[SENSOR_LOOKING_FORWARD_READING_INDEX] <= SAFE_DISTANCE;
}

boolean imminent_collision() {
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

/*
Find out where we get the best distance range and go towards that
If all the distances in front are unsafe, return REVERSE
*/
int quick_decision() {
  // one of the value has been updated, check to see if we should go left or right 
  // or just keep going forward
  int left_value = get_last_reading_for_angle(SENSOR_LOOKING_LEFT_ANGLE);
  int right_value = get_last_reading_for_angle(SENSOR_LOOKING_RIGHT_ANGLE);
  int forward_value = get_last_reading_for_angle(SENSOR_LOOKING_FORWARD_ANGLE);
  
  if(left_value > forward_value && left_value > right_value) {
    if(left_value < SAFE_DISTANCE) {
      return REVERSE;
    }
    return LEFT;
  } else if(right_value > forward_value && right_value > left_value) {
    if(right_value < SAFE_DISTANCE) {
      return REVERSE;
    }
    return RIGHT;
  } else {
    if(forward_value < SAFE_DISTANCE) {
      return REVERSE; 
    }
    return FORWARD;
  }
}

/*
completes once the sensor has readings left, right and center
*/
boolean check_left;
int quick_sweep_number_readings;
void init_quick_sweep() {
  full_stop();
  quick_sweep_number_readings = 0;
  check_left = true; // always want to go left first
  current_state = QUICK_SWEEP;
  safe_update_servo_position(SENSOR_LOOKING_FORWARD_ANGLE);
}

boolean quick_sweep() {
    // we check if we have an updated value here
    if(read_sensor() != NO_READING) {
      quick_sweep_number_readings++;
      // we have an updated value, if it's a center value
      // move the servo to get left and right readings
      if(current_sensor_servo_angle == SENSOR_LOOKING_FORWARD_ANGLE) {
        // go left or right depending on check_left
        if(check_left) {
          // inside read_sensor() which guarantees servo timer expired
          update_servo_position(SENSOR_LOOKING_LEFT_ANGLE);
        } else {  
          // inside read_sensor() which guarantees servo timer expired
          update_servo_position(SENSOR_LOOKING_RIGHT_ANGLE);
        }
      } else {
        // check left toggles between true and false here
        check_left = !check_left;
        // return to center; this mean we read twice as often forward than left or right
        update_servo_position(SENSOR_LOOKING_FORWARD_ANGLE);
      }
      return true;
    }
    return false;
}

void init_turn() {
  full_stop();
  current_state = DYNAMIC_TURN;
  safe_update_servo_position(SENSOR_LOOKING_FORWARD_ANGLE);
  // 0-90 is to the right
  if(turn_towards < SENSOR_LOOKING_FORWARD_ANGLE) {
    go(RIGHT);
  } 
  // 90 to 180 is to the left
  else {
    go(LEFT);
  }
  go(FORWARD);
  int expected_wait = expected_wait_millis(ROBOT_TURN_RATE_PER_SECOND, SENSOR_LOOKING_FORWARD_ANGLE, turn_towards);
  start_timed_operation(WAIT_FOR_ROBOT_TO_TURN, expected_wait);
  if(LOG_LEVEL >= DEBUG) {
    Serial.print("Waiting for robot to turn millis: ");
    Serial.println(expected_wait);
  }
}

void init_go_forward() {
  full_stop();
  current_state = DYNAMIC_FORWARD;
  safe_update_servo_position(SENSOR_LOOKING_FORWARD_ANGLE);
}

void init_decision() {
  full_stop();
  current_state = DECISION;
  safe_update_servo_position(SENSOR_LOOKING_FORWARD_ANGLE);
}

void init_stuck() {
  full_stop();
  current_state = STUCK;
}

void init_quick_decision() {
  full_stop();
  current_state = QUICK_DECISION;
}

void init_direction_unit(int decision) {
  full_stop();
  if(decision == REVERSE) {
    current_state = REVERSE_QUICK_DECISION;
    return; // switching state
  }
  
  start_timed_operation(WAIT_FOR_ROBOT_TO_ADVANCE_UNIT, FORWARD_TIME_UNIT_MILLIS);
  go(FORWARD);
  switch(decision) {
    case LEFT:
      current_state = FORWARD_LEFT_UNIT;
      go(LEFT);
      break;
    case RIGHT:
      current_state = FORWARD_RIGHT_UNIT;
      go(RIGHT);
      break;
    case FORWARD:
      current_state = FORWARD_UNIT;
      break;
    default:
      if(LOG_LEVEL >= ERROR) {
        Serial.print("BAD STATE IN init_direction_unit:");
        Serial.println(decision);
      }
      break;
  }
}

void init_direction_reverse_unit(int dir) {  
  full_stop();
  start_timed_operation(WAIT_FOR_ROBOT_TO_ADVANCE_UNIT, FORWARD_TIME_UNIT_MILLIS);
  go(REVERSE);
  switch(dir) {
    case LEFT:
      current_state = REVERSE_LEFT_UNIT;
      go(RIGHT); // going left reverse means wheels pointing right
      break;
    case RIGHT:
      current_state = REVERSE_RIGHT_UNIT;
      go(LEFT); // going right reverse means wheels pointing left
      break;
    case REVERSE:
      current_state = REVERSE_UNIT;
      break;
    default:
      if(LOG_LEVEL >= ERROR) {
        Serial.print("BAD STATE IN init_direction_reverse_unit:");
        Serial.println(dir);
      }
      break;
  }
}

void loop(){
  int initial_state = current_state;
  switch(current_state) {
  // initial; this initiates what type of sub-state-machine we want to use
  // dynamic: more complex states that are supposed to adjust while moving
  // unit: move one unit, scan, decide, move one unit, scan, decide, move one unit...
  case INITIAL:
    // wait for the first reading...
    if(read_sensor() != NO_READING) {
      init_quick_sweep(); // change this to change sub-state-machine
    }
    break;
    
  // dynamic states
  case FULL_SWEEP:
    if(sensor_sweep()) {
      // sweep completed, decision time!
      init_decision();
    } // else keep sweeping!
    break;
  case DYNAMIC_FORWARD:
    if(potential_collision()) {
      // we're going to crash into something, stop and find an alternative
      init_sweep();
    } else { 
      go(FORWARD);
      if(quick_sweep()) {
        suspend(LEFT);
        suspend(RIGHT);
        int decision = quick_decision();
        if(decision == REVERSE) {
          init_stuck();
        } else {
          go(decision);
        }
      }
    }
    break;
  case DECISION:
    // we want to turn towards the longest opening
    turn_towards = find_best_direction_degrees();
    if(turn_towards != NO_READING) {
      init_turn();
    } 
    else {
      init_stuck();
    }
    break;
  case DYNAMIC_TURN:
    read_sensor();
    if(imminent_collision()) {
      init_stuck();
    }
    if(timed_operation_expired(WAIT_FOR_ROBOT_TO_TURN)) {
      // we've turned! reset and try to move forward now
      init_go_forward();
    }
    break;
  case STUCK:
    go(REVERSE);
    if(quick_sweep()) {
      if(!potential_collision()) {
        init_sweep();
      }
    }
    break;
  
  // unit behavior
  case QUICK_SWEEP:
    if(quick_sweep()) {
      // sweep has read one more reading
      if(quick_sweep_number_readings == 3) {
        // we've completed three readings
        init_quick_decision();
      }
    }
    break;
  case QUICK_DECISION:
    init_direction_unit(quick_decision());
    break;
  case REVERSE_QUICK_DECISION:
    // no sensors to tell us if we can reverse
    // or what direction to prefer so we always do...
    init_direction_reverse_unit(REVERSE);
    break;
  case FORWARD_UNIT:
  case FORWARD_LEFT_UNIT:
  case FORWARD_RIGHT_UNIT:
  case REVERSE_UNIT:
  case REVERSE_LEFT_UNIT:
  case REVERSE_RIGHT_UNIT:
    // all directions work the same: we wait!
    if(timed_operation_expired(WAIT_FOR_ROBOT_TO_ADVANCE_UNIT)) {
      init_quick_sweep();
    }
    break;
  default:
    if(LOG_LEVEL >= ERROR) { 
        Serial.print("BAD STATE IN main loop:");
        Serial.println(current_state);
    }
    break;
  }

  if(initial_state != current_state) {
    if(LOG_LEVEL >= INFO) {
      Serial.print("INITIAL STATE:");
      Serial.print((char)initial_state);
      Serial.print(" FINAL STATE:");
      Serial.println((char)current_state);
    }
  }
}

