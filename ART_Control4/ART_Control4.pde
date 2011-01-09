/*****************************************************************************
 * ART CONTROLLER
 * 
 * Copyright 2011 Ricky Ng-Adam
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************/

/*****************************************************************************
 * ARDUINO LIBS
 *****************************************************************************/
#include <Servo.h> 
#include <limits.h>

/*****************************************************************************
 * NY LIBS
 *****************************************************************************/
#include "types.h"
#include "Ultrasonic.h"

/*****************************************************************************
 * LOGGING
 *****************************************************************************/
enum telemetry_types {
  ULTRASONIC_SENSORS,
  STATE_CHANGE,
  SENSOR_SERVO_POSITION_CHANGE,
  CAR_GO_COMMAND,
  CAR_SUSPEND_COMMAND,
  MAX_TELEMETRY_TYPE,
};

/*char* telemetry_types_names[] = {
 "ULTRASONIC_SENSORS",
 "STATE_CHANGE",
 "SENSOR_SERVO_POSITION_CHANGE",
 "CAR_GO_COMMAND",
 "CAR_SUSPEND_COMMAND",
 };*/

#define DEBUG
#define TELEMETRY
#define ERROR_SERIAL_LOGGING   
#undef TRACE_SERIAL_LOGGING  

#ifdef DEBUG
#define DEBUG_PRINT(str)    \
    Serial.print(millis());     \
    Serial.print(": ");    \
    Serial.print(__FUNCTION__); \
    Serial.print(':');      \
    Serial.print(__LINE__);     \
    Serial.print(' ');      \
    Serial.println(str);
#else
#define DEBUG_PRINT(str)
#endif 

#ifdef TELEMETRY
#define LOG_TELEMETRY(type, source, value) \
Serial.print("|"); \
Serial.print(millis()); \
Serial.print(","); \
Serial.print((int)type); \
Serial.print(","); \
Serial.print((int)source); \
Serial.print(","); \
Serial.println((int)value);  
#else
#define LOG_TELEMETRY(type, source, value)
#endif

#ifdef ERROR_SERIAL_LOGGING    
#define LOG_BAD_STATE(value) \
Serial.print(millis()); \
Serial.print(": "); \
Serial.print(__FUNCTION__); \
Serial.print(':'); \
Serial.print(__LINE__); \
Serial.print(' '); \
Serial.println((int)value);
#define LOG_ERROR(message, context, expected, actual) \
Serial.print("ERROR:"); \
Serial.print(millis()); \
Serial.print(":"); \
Serial.print(message); \
Serial.print(" context:"); \
Serial.print((int)context); \
Serial.print(" expected:"); \
Serial.print((int)expected); \
Serial.print(" actual:"); \
Serial.println((int)actual);     
#else
#define LOG_ERROR(message, source, expected, actual)
#define LOG_BAD_STATE(value)
#endif

#ifdef TRACE_SERIAL_LOGGING    
#define LOG_TRACE4(message1, value1, message2, value2) \
Serial.print("TRACE:"); \
Serial.print(millis()); \
Serial.print(":"); \
Serial.print(message1); \
Serial.print((int)value1); \
Serial.print(message2); \
Serial.println((int)value2);   
#define LOG_TRACE2(message1, value1) \
Serial.print("TRACE:"); \
Serial.print(millis()); \
Serial.print(":"); \
Serial.print(message1); \
Serial.println((int)value1); 
#else
#define LOG_TRACE4(message1, value1, message2, value2)
#define LOG_TRACE2(message1, value1)
#endif


/*****************************************************************************
 * ARDUINO PINS MAPPING
 *****************************************************************************/
// ultrasonic
pin_t ULTRASONIC_REVERSE_TRIG = 2;
pin_t ULTRASONIC_REVERSE_ECHO = 3;
pin_t ULTRASONIC_FORWARD_TRIG = 4;
pin_t ULTRASONIC_FORWARD_ECHO = 5;
// various directions we can go to
pin_t FORWARD_PIN =  6;      // the number of the LED pin
pin_t REVERSE_PIN =  7;  
pin_t LEFT_PIN = 8;  
pin_t RIGHT_PIN =  9;  
pin_t PUSHBUTTON_PIN = 10;
// servo
pin_t SENSOR_SERVO_PIN = 12;
// analog adjustments
pin_t FORWARD_POT_PIN = A5;
pin_t REVERSE_POT_PIN = A4;
// buttons

/*****************************************************************************
 * TIMING RELATED
 *****************************************************************************/
enum waits_types {
  WAIT_FOR_SERVO_TO_TURN,
  WAIT_FOR_ECHO,
  WAIT_FOR_ROBOT_TO_MOVE,
  WAIT_FOR_BUTTON_REREAD,
  WAIT_ARRAY_SIZE, // always last...
};

time_ms_t timed_operation_initiated_millis[WAIT_ARRAY_SIZE]; // 4 bytes * 4 = 16 bytes
duration_ms_t timed_operation_desired_wait_millis[WAIT_ARRAY_SIZE]; // 2 bytes * 2 = 4 bytes

/*
record current time to compare to
 */
void start_timed_operation(enum_t index, duration_ms_t duration) {
  timed_operation_initiated_millis[index] = millis();
  timed_operation_desired_wait_millis[index] = duration;
  LOG_TRACE4("Timer added type ", index, " wait in millis:", duration);
}

/*
Check whether the timer has expired
 if expired, returns true else returns false
 */
boolean timed_operation_expired(enum_t index) {
  if((millis() - timed_operation_initiated_millis[index]) < timed_operation_desired_wait_millis[index]) {
    //DEBUG_PRINT("not expired");
    return false;
  }
  //DEBUG_PRINT("expired");
  return true;
}

/*****************************************************************************
 * SENSOR SERVO
 *****************************************************************************/
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
constant_t SERVO_TURN_RATE_MS_PER_DEGREE = 3; 
Servo sensor_servo;   

duration_ms_t expected_wait_millis(turn_rate_t turn_rate, angle_t initial_angle, angle_t desired_angle) {
  angle_t delta;
  duration_ms_t return_value;
  if(initial_angle == desired_angle) {
    return_value = 0;
  } 
  else if(initial_angle > desired_angle) {
    return_value = turn_rate * (initial_angle - desired_angle);
  } 
  else {
    return_value = turn_rate * (desired_angle - initial_angle);
  }
  return return_value;
}

void update_servo_position(angle_t desired_sensor_servo_angle) {  
  duration_ms_t wait_millis;
  switch(desired_sensor_servo_angle) {
  case 0:
  case 45:
  case 90:
  case 135:
    // OK!
    break;
  default:
    LOG_BAD_STATE(desired_sensor_servo_angle);
    return;
    break;
  }
  if(sensor_servo.read() != desired_sensor_servo_angle) {
    // calculate expected wait BEFORE going there...
    wait_millis = expected_wait_millis(SERVO_TURN_RATE_MS_PER_DEGREE, sensor_servo.read(), desired_sensor_servo_angle);
    sensor_servo.write(desired_sensor_servo_angle);              // tell servo to go to position in variable 'pos'
    start_timed_operation(WAIT_FOR_SERVO_TO_TURN, wait_millis);

    LOG_TELEMETRY(SENSOR_SERVO_POSITION_CHANGE, sensor_servo.read(), desired_sensor_servo_angle);
  } 
  else {
    LOG_TRACE2("Requesting sensor servo position already set", desired_sensor_servo_angle);
  }
}

/*****************************************************************************
 * SENSORS
 *****************************************************************************/
/* 
 HC-SR04 Ultrasonic sensor
 effectual angle: <15°
 ranging distance : 2cm – 500 cm
 resolution : 0.3 cm
 */
constant_t SENSOR_ARC_DEGREES = 15; // 180, 90, 15 all divisible by 15
constant_t SENSOR_PRECISION_CM = 1;
large_constant_t SENSOR_MAX_RANGE_CM = 500;
// speed of sound at sea level = 340.29 m / s
// spec range is 5m * 2 (return) = 10m
// 10 / 341 = ~0.029
large_constant_t SPEED_OF_SOUND_CM_PER_S = 34000;
constant_t SENSOR_MINIMAL_WAIT_ECHO_MILLIS = 50; //(SENSOR_MAX_RANGE_CM*2*1000)/SPEED_OF_SOUND_CM_PER_S;

/*

 SENSOR_LEFT(135)      SENSOR_FRONT (90)   SENSOR_RIGHT (45)
 -----------
 |   ^     | 
 |         |
 SENSOR_LEFT_SIDE(0)     |         |       SENSOR_RIGHT_SIDE (0)
 |         |
 |         |
 |         |
 -----------
 SENSOR_BACK_LEFT(45)  SENSOR_BACK(90)     SENSOR_BACK_RIGHT(135)
 */
enum sensor_position {
  SENSOR_LEFT, 
  SENSOR_FRONT, 
  SENSOR_RIGHT,
  SENSOR_LEFT_SIDE,
  SENSOR_RIGHT_SIDE,
  SENSOR_BACK_LEFT,
  SENSOR_BACK,
  SENSOR_BACK_RIGHT,
  NUMBER_READINGS,
};

angle_t sensor_position_to_servo_angle[] = {
  135, // SENSOR_LEFT
  90, // SENSOR_FRONT
  45, // SENSOR_RIGHT
  0, // SENSOR_LEFT_SIDE
  0, // SENSOR_RIGHT_SIDE
  45, // SENSOR_BACK_LEFT
  90, // SENSOR BACK
  135, // SENSOR_BACK_RIGHT
};

enum ultrasonics {
  ULTRASONIC_FORWARD,
  ULTRASONIC_REVERSE,
  ULTRASONIC_DIRECTION_ARRAY_SIZE,
};

enum_t sensor_array_read_next;
sensor_reading_t sensor_distance_readings_cm[NUMBER_READINGS]; // 8 sensors * 4 bytes = 48 bytes
constant_t NO_READING = 0;

Ultrasonic sensor_forward = Ultrasonic(ULTRASONIC_FORWARD_TRIG, ULTRASONIC_FORWARD_ECHO);
Ultrasonic sensor_reverse = Ultrasonic(ULTRASONIC_REVERSE_TRIG, ULTRASONIC_REVERSE_ECHO);

enum_t current_max_sensor() {
  enum_t max_sensor = SENSOR_LEFT;
  for(loop_t i=1;i<NUMBER_READINGS; i++) {
    if(sensor_distance_readings_cm[i] >= sensor_distance_readings_cm[max_sensor]) {
      max_sensor = i;
    }
  }
  return max_sensor;
}

distance_cm_t current_max_distance_cm() {
  return sensor_distance_readings_cm[current_max_sensor()];
}

distance_cm_t update_sensor_value(enum_t sensor, distance_cm_t measured_value) {
  // only update if the value is different beyond precision of sensor
  if(abs(measured_value - sensor_distance_readings_cm[sensor]) > SENSOR_PRECISION_CM) {
    sensor_distance_readings_cm[sensor] = measured_value;
  }
  return sensor_distance_readings_cm[sensor];
}

distance_cm_t read_sensor(enum_t sensor, Ultrasonic& sensor_object) {
  if(!timed_operation_expired(WAIT_FOR_SERVO_TO_TURN)) {
    return NO_READING;
  }

  if(!timed_operation_expired(WAIT_FOR_ECHO)) {
    return NO_READING;
  }

  if(sensor_servo.read() != sensor_position_to_servo_angle[sensor]) {
    LOG_ERROR("read_sensor() servo current_position does not match sensor desired angle", sensor, sensor_position_to_servo_angle[sensor], sensor_servo.read());

    return NO_READING;
  }

  distance_cm_t return_value = update_sensor_value(sensor, sensor_object.Ranging(CM));
  LOG_TELEMETRY(ULTRASONIC_SENSORS, sensor, return_value); 
  start_timed_operation(WAIT_FOR_ECHO, SENSOR_MINIMAL_WAIT_ECHO_MILLIS);
  return return_value;
}

/*****************************************************************************
 * RC CAR RELATED
 *****************************************************************************/
constant_t ROBOT_TURN_RATE_PER_SECOND = 90;
constant_t SAFE_DISTANCE_LARGE_TURN = 50; // distance between table and wall and minus size of robot (when robot is stuck...)
constant_t SAFE_DISTANCE_SMALL_TURN = 25; // one car length...
large_constant_t MAX_TIME_UNIT_MILLIS = 3000;
large_constant_t  MIN_TIME_UNIT_MILLIS = 500;
constant_t CAR_LENGTH = 25;
constant_t CAR_WIDTH = 15;

enum commands {
  FORWARD,
  REVERSE,
  LEFT,
  RIGHT,
  // COMBINED
  FORWARD_LEFT,
  FORWARD_RIGHT,
  REVERSE_LEFT,
  REVERSE_RIGHT,
}; 

bitmask8_t current_command = 0;

/*
Makes sure that exclusive directions are prohibited
 */
void _go(enum_t  dir) {
  switch(dir) {
  case FORWARD:
    digitalWrite(REVERSE_PIN, LOW);
    digitalWrite(FORWARD_PIN, HIGH);   
    break;
  case REVERSE:
    digitalWrite(FORWARD_PIN, LOW);   
    digitalWrite(REVERSE_PIN, HIGH);   
    break;  
  case LEFT:
    digitalWrite(RIGHT_PIN, LOW);   
    digitalWrite(LEFT_PIN, HIGH);   
    break;
  case RIGHT:
    digitalWrite(LEFT_PIN, LOW);   
    digitalWrite(RIGHT_PIN, HIGH);   
    break;       
  default:
    LOG_BAD_STATE(dir);
    break;  
  }
}

void _suspend(enum_t dir) {
  switch(dir) {
  case FORWARD:
    digitalWrite(FORWARD_PIN, LOW);   
    break;
  case REVERSE:
    digitalWrite(REVERSE_PIN, LOW);   
    break;  
  case LEFT:
    digitalWrite(LEFT_PIN, LOW);   
    break;
  case RIGHT:
    digitalWrite(RIGHT_PIN, LOW);   
    break;       
  default:
    LOG_BAD_STATE(dir);
    break;  
  }
}

/*
example:
 dir is REVERSE (value 1)
 so the dir_bitmask is 1 shifted by 1 to the left (0010)
 if current_command is 1010 (or similar), then skip
 otherwise (1000), execute and set current_command = 1000 | 0010 = 1010
 */
void go(enum_t dir) {
  bitmask8_t dir_bitmask = 1 << dir;
  if(!(current_command & dir_bitmask)) {
    _go(dir);
    current_command = current_command | dir_bitmask;
    LOG_TELEMETRY(CAR_GO_COMMAND, current_command, dir);
  }
}

void suspend(enum_t dir) {
  bitmask8_t dir_bitmask = 1 << dir;
  if(current_command & dir_bitmask) {
    _suspend(dir);
    current_command = current_command ^ dir_bitmask;
    LOG_TELEMETRY(CAR_SUSPEND_COMMAND, current_command, dir);    
  }
}

void full_stop() {
  suspend(FORWARD);
  suspend(REVERSE);
  suspend(LEFT);
  suspend(RIGHT);
}

/*****************************************************************************
 * INTERNAL STATES
 *****************************************************************************/
enum states {
  // start state
  INITIAL = 'I',
  FULL_SWEEP = 'Q',
  // units advancement
  FORWARD_LEFT_UNIT = '1',
  FORWARD_UNIT = '2',
  FORWARD_RIGHT_UNIT = '3',
  REVERSE_LEFT_UNIT = '4',
  REVERSE_UNIT = '5',
  REVERSE_RIGHT_UNIT = '6',
  // decision making
  STANDSTILL_DECISION = '?',
  // end state
  STUCK = 'K',
  STOP = '.',
  SMALL_TURN_CCW = '<',
  SMALL_TURN_CW = '>',
};

enum_t current_state = STOP;
enum_t previous_state = FORWARD_UNIT;

/*****************************************************************************
 * SETUP
 *****************************************************************************/
void setup() { 
  // make sure we get all error message output
  Serial.begin(9600);
  Serial.println("------------------");
  Serial.println("ART STARTED ");
  Serial.println("Setting Arduino pins");

  // these map to the contact switches on the RF
  pinMode(FORWARD_PIN, OUTPUT);     
  pinMode(REVERSE_PIN, OUTPUT);    
  pinMode(LEFT_PIN, OUTPUT);  
  pinMode(RIGHT_PIN, OUTPUT);  
  // input potentiometer
  pinMode(FORWARD_POT_PIN, INPUT);
  pinMode(REVERSE_POT_PIN, INPUT);
  //buttons
  pinMode(PUSHBUTTON_PIN, INPUT);

  Serial.println("Full stop");
  full_stop();
  Serial.println("Servo init");
  sensor_servo.attach(SENSOR_SERVO_PIN);
  sensor_servo.write(90);
  delay(500);
  Serial.println("Timers init");
  for(loop_t i=0; i<WAIT_ARRAY_SIZE; i++) {
    timed_operation_initiated_millis[i] = 0;  
    timed_operation_desired_wait_millis[i] = 0;
  }
  Serial.print("ART SETUP COMPLETED ");
  Serial.println(millis());
}

/*****************************************************************************
 * DECISION HELPERS
 *****************************************************************************/
duration_ms_t get_forward_time_millis() {
  duration_ms_t max_time = map(analogRead(FORWARD_POT_PIN), 0, 1024, MIN_TIME_UNIT_MILLIS, MAX_TIME_UNIT_MILLIS);
  duration_ms_t time = map(current_max_distance_cm(), 0, SENSOR_MAX_RANGE_CM, MIN_TIME_UNIT_MILLIS, max_time);
  return time;
}

duration_ms_t get_backward_time_millis() {
  // same logic because we don't have a front sensor...
  duration_ms_t max_time = map(analogRead(REVERSE_POT_PIN), 0, 1024, MIN_TIME_UNIT_MILLIS, MAX_TIME_UNIT_MILLIS);
  duration_ms_t time = map(current_max_distance_cm(), 0, SENSOR_MAX_RANGE_CM, MIN_TIME_UNIT_MILLIS, max_time);
  return time;
}

boolean is_safe_large_turn(enum_t sensor) {
  return sensor_distance_readings_cm[sensor] >= SAFE_DISTANCE_LARGE_TURN;
}

boolean is_safe_small_turn(enum_t sensor) {
  return sensor_distance_readings_cm[sensor] >= SAFE_DISTANCE_SMALL_TURN;
}

boolean is_greater(enum_t sensor_a, enum_t sensor_b) {
  return sensor_distance_readings_cm[sensor_a] > sensor_distance_readings_cm[sensor_b];
}

/*****************************************************************************
 * STATE INITS AND HANDLERS
 *****************************************************************************/
/*
 */

/*****************************************************************************
 STANDSTILL DECISION
 Find out where we get the best distance range and go towards that
 If all the distances in front are unsafe, return REVERSE
 *****************************************************************************/
void init_standstill_decision() {
  full_stop();
  current_state = STANDSTILL_DECISION;
}

enum_t standstill_decision() {
  // FORWARD
  if(is_safe_large_turn(SENSOR_FRONT)) { // we can do a turn if we want by going forward
    if(is_greater(SENSOR_FRONT, SENSOR_LEFT) && is_greater(SENSOR_FRONT, SENSOR_RIGHT)) {
      return FORWARD_UNIT;
    }
    else if(is_safe_large_turn(SENSOR_LEFT) && is_greater(SENSOR_LEFT, SENSOR_RIGHT)) {
      // left side is most promising
      return FORWARD_LEFT_UNIT;  
    }
    else if(is_safe_large_turn(SENSOR_RIGHT) &&  is_greater(SENSOR_RIGHT, SENSOR_LEFT)) {
      // right side is most promising
      return FORWARD_RIGHT_UNIT;  
    }
    else {
      // not greater but still safe...
      return FORWARD_UNIT;
    }
  }

  // Can't turn around safely, try small turns
  if(is_safe_small_turn(SENSOR_LEFT) && is_safe_small_turn(SENSOR_BACK_RIGHT)) {
    return SMALL_TURN_CCW;
  } 
  else if(is_safe_small_turn(SENSOR_RIGHT) && is_safe_small_turn(SENSOR_BACK_LEFT)) {
    return SMALL_TURN_CW;
  }

  // REVERSE
  // forward isn't working out, let us see if reverse shows more promise so we can turn to be towards the most promising side...
  // or keep turning to follow through on a previous turn
  if(is_safe_large_turn(SENSOR_BACK)) {
    // favor to help in a previous turn
    if(is_safe_large_turn(SENSOR_LEFT) && previous_state == FORWARD_LEFT_UNIT) {
      return REVERSE_LEFT_UNIT;
    }
    if(is_safe_large_turn(SENSOR_RIGHT) && previous_state == FORWARD_RIGHT_UNIT) {
      return REVERSE_RIGHT_UNIT;
    }
    // ... other, select side with best potential
    if(is_safe_large_turn(SENSOR_LEFT) && is_greater(SENSOR_LEFT_SIDE, SENSOR_RIGHT_SIDE)) {
      // left side is most promising
      return REVERSE_LEFT_UNIT;  
    }
    else if(is_safe_large_turn(SENSOR_RIGHT) && is_greater(SENSOR_RIGHT_SIDE, SENSOR_LEFT_SIDE)) {
      // right side is most promising
      return REVERSE_RIGHT_UNIT;  
    }
  } 

  // forward/reverse choice ...
  if(is_safe_large_turn(SENSOR_FRONT)) {
    if(is_greater(SENSOR_FRONT, SENSOR_BACK)) {
      return FORWARD_UNIT;
    } 
    else {
      // otherwise, readings_reverse is safe and longest
      return REVERSE_UNIT;
    }
  }

  if(is_safe_large_turn(SENSOR_BACK)) {
    return REVERSE_UNIT;
  }

  return NO_READING; // we're stuck, nothing safe!
}

/*****************************************************************************
 * SENSOR FULL SWEEP
 *****************************************************************************/
void init_full_sweep() {
  full_stop();
  sensor_array_read_next = SENSOR_FRONT;
  update_servo_position(sensor_position_to_servo_angle[SENSOR_FRONT]);
  current_state = FULL_SWEEP;
}

boolean full_sweep() {
  // we check if we have an updated value here
  distance_cm_t read_value = NO_READING;
  switch(sensor_array_read_next) {
  case SENSOR_LEFT:
  case SENSOR_FRONT:
  case SENSOR_RIGHT:
  case SENSOR_RIGHT_SIDE:
    read_value = read_sensor(sensor_array_read_next, sensor_forward);
    break;
  case SENSOR_BACK_RIGHT:
  case SENSOR_BACK_LEFT:
  case SENSOR_BACK:
  case SENSOR_LEFT_SIDE:
    read_value = read_sensor(sensor_array_read_next, sensor_reverse);
    break;
  default:
    LOG_BAD_STATE(sensor_array_read_next);
    break;
  }

  if(read_value != NO_READING) {
    switch(sensor_array_read_next) {
    case SENSOR_FRONT:
      sensor_array_read_next = SENSOR_BACK;
      break;
    case SENSOR_BACK:
      sensor_array_read_next = SENSOR_LEFT;       
      break;
    case SENSOR_LEFT:
      sensor_array_read_next = SENSOR_BACK_RIGHT;
      break;
    case SENSOR_BACK_RIGHT:
      sensor_array_read_next = SENSOR_RIGHT;
      break;
    case SENSOR_RIGHT:
      sensor_array_read_next = SENSOR_BACK_LEFT;
      break;
    case SENSOR_BACK_LEFT:
      sensor_array_read_next = SENSOR_RIGHT_SIDE;         
      break;
    case SENSOR_RIGHT_SIDE:
      sensor_array_read_next = SENSOR_LEFT_SIDE;
      break;
    case SENSOR_LEFT_SIDE:
      sensor_array_read_next = SENSOR_FRONT;
      return true; // completed sweep!
      break;
    default:
      LOG_BAD_STATE(sensor_array_read_next);
      break;
    }
    update_servo_position(sensor_position_to_servo_angle[sensor_array_read_next]);
    if(sensor_array_read_next == SENSOR_FRONT) {
      return true;
    }
  }
  return false;
}

/*****************************************************************************
 * STUCK
 *****************************************************************************/

void init_stuck() {
  full_stop();
  current_state = STUCK;
}

/*****************************************************************************
 * SMALL RADIUS TURN
 *****************************************************************************/
distance_cm_t target_distance_cm = SAFE_DISTANCE_LARGE_TURN;
enum_t small_turn_state;
void init_small_turn(enum_t small_turn_type) {
  full_stop();
  update_servo_position(sensor_position_to_servo_angle[SENSOR_FRONT]);  
  target_distance_cm = current_max_distance_cm();
  current_state = small_turn_type;
  if(small_turn_type == SMALL_TURN_CCW) { 
    small_turn_state = FORWARD_LEFT; 
  } else {
    small_turn_state = FORWARD_RIGHT; 
  }
}

boolean handle_small_turn(enum_t small_turn_type) {
  if(read_sensor(SENSOR_FRONT, sensor_forward) > (target_distance_cm - CAR_LENGTH/2) || !is_safe_small_turn(SENSOR_FRONT)) {
    full_stop();
    return true;
  }

  if(!timed_operation_expired(WAIT_FOR_ROBOT_TO_MOVE)) {
    return false;
  }

  switch(small_turn_state) {
  case FORWARD_LEFT:
    go(FORWARD);
    go(LEFT);
    small_turn_state = REVERSE_RIGHT;
    break;
  case REVERSE_RIGHT:
    go(REVERSE);
    go(RIGHT);
    small_turn_state = FORWARD_LEFT;
    break;
  case FORWARD_RIGHT:
    go(FORWARD);
    go(RIGHT);
    small_turn_state = REVERSE_LEFT;
    break;
  case REVERSE_LEFT:
    go(REVERSE);
    go(LEFT);
    small_turn_state = FORWARD_RIGHT;
    break;      
  default:
    LOG_BAD_STATE(small_turn_state);
    break;
  }
  start_timed_operation(WAIT_FOR_ROBOT_TO_MOVE, MIN_TIME_UNIT_MILLIS);
  return false;
}

/*****************************************************************************
 * SMALL STEPS (UNIT) MOVEMENTS WITH TIMER
 *****************************************************************************/
void init_direction_unit(enum_t decision) {
  full_stop();
  update_servo_position(sensor_position_to_servo_angle[SENSOR_FRONT]);  

  switch(decision) {
  case FORWARD_LEFT_UNIT:
    go(LEFT);
    break;
  case FORWARD_RIGHT_UNIT:
    go(RIGHT);
    break;
  case REVERSE_LEFT_UNIT:
    go(RIGHT);
    break;
  case REVERSE_RIGHT_UNIT:
    go(LEFT);
    break;
  case REVERSE_UNIT:
  case FORWARD_UNIT:
    // do nothing, we will decide below what to do
    break;
  default:
    LOG_BAD_STATE(decision);
    break;
  }
  previous_state = current_state;
  current_state = decision;
  enum_t dir;
  duration_ms_t time_millis;
  switch(decision) {
  case FORWARD_LEFT_UNIT:
  case FORWARD_RIGHT_UNIT:
  case FORWARD_UNIT:
    time_millis = get_forward_time_millis();
    dir = FORWARD;
    break;
  case REVERSE_LEFT_UNIT:
  case REVERSE_RIGHT_UNIT:
  case REVERSE_UNIT:
    time_millis = get_backward_time_millis();
    dir = REVERSE;
    break;
  default:
    LOG_BAD_STATE(decision);
    break;
  }
  LOG_TRACE2("Will move for (ms): ", time_millis);
  start_timed_operation(WAIT_FOR_ROBOT_TO_MOVE, time_millis);
  go(dir);
}


void handle_unit(enum_t sensor, Ultrasonic& sensor_object) {
  if(timed_operation_expired(WAIT_FOR_ROBOT_TO_MOVE)) {
    init_full_sweep();
  }
  if(read_sensor(sensor, sensor_object) != NO_READING) {
    if(!is_safe_large_turn(SENSOR_FRONT)) {
      init_full_sweep();
    }
  }
}

/*****************************************************************************
 * STOP BUTTON
 *****************************************************************************/
void check_button() {
  // read the state of the pushbutton value:
  if(!timed_operation_expired(WAIT_FOR_BUTTON_REREAD)) {
    return;
  }
  boolean buttonState = digitalRead(PUSHBUTTON_PIN) == HIGH?true:false;
  // check if the pushbutton is pressed.
  // if it is, the buttonState is HIGH:
  if (buttonState) {     
    DEBUG_PRINT("Button pressed!");
    if(current_state == STOP) {
      current_state = INITIAL;
    } 
    else {
      full_stop();
      current_state = STOP;
      update_servo_position(sensor_position_to_servo_angle[SENSOR_FRONT]); 
    }
    start_timed_operation(WAIT_FOR_BUTTON_REREAD, 1000);
  } 
}

/*****************************************************************************
 * MAIN STATE MACHINE LOOP
 *****************************************************************************/
void loop(){
  enum_t initial_state = current_state;
  enum_t decision;
  check_button();
  switch(current_state) {
    // initial; this initiates what type of sub-state-machine we want to use
    // unit: move one unit, scan, decide, move one unit, scan, decide, move one unit...
  case INITIAL:
    init_full_sweep(); // change this to change sub-state-machine
    break;
  case FULL_SWEEP:
    if(full_sweep()) {
      // one sweep completed
      init_standstill_decision();
    }
    break;
  case STANDSTILL_DECISION:
    decision = standstill_decision();
    if(decision != NO_READING) {
      if(decision == SMALL_TURN_CW || decision == SMALL_TURN_CCW) {
        init_small_turn(decision);
      } 
      else {
        init_direction_unit(decision);
      }
    } 
    else {
      init_stuck();
    }
    break;
  case FORWARD_UNIT:
  case FORWARD_LEFT_UNIT:
  case FORWARD_RIGHT_UNIT:
    handle_unit(SENSOR_FRONT, sensor_forward);
    break;
  case REVERSE_UNIT:
  case REVERSE_LEFT_UNIT:
  case REVERSE_RIGHT_UNIT:
    handle_unit(SENSOR_BACK, sensor_reverse);
    break;
  case SMALL_TURN_CW:
  case SMALL_TURN_CCW:
    if(handle_small_turn(current_state)) {
      // small turn completed with target max distance
      init_full_sweep();  
    }
    break;
  case STOP:
    // do nothing...
    if(millis() % 1000 == 0) {
      Serial.print('.');
    }
    break;
  case STUCK:
    init_full_sweep();
    break;

  default:
    LOG_BAD_STATE(current_state);
    break;
  }

  if(initial_state != current_state) {
    LOG_TELEMETRY(STATE_CHANGE, initial_state, current_state);
  }
}




