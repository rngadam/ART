#include <Ultrasonic.h>
#include <Servo.h> 
#include <limits.h>

enum LOG_LEVELS {
  ERROR,
  INFO,
  DEBUG,
  TRACE,
};
int LOG_LEVEL = DEBUG;

// Arduino pins mapping

// ultrasonic
const int ULTRASONIC_REVERSE_TRIG = 2;
const int ULTRASONIC_REVERSE_ECHO = 3;
const int ULTRASONIC_FORWARD_TRIG = 4;
const int ULTRASONIC_FORWARD_ECHO = 5;
// various directions we can go to
const int FORWARD_PIN =  6;      // the number of the LED pin
const int REVERSE_PIN =  7;  
const int LEFT_PIN = 8;  
const int RIGHT_PIN =  9;  
const int PUSHBUTTON_PIN = 10;
// servo
const int SENSOR_SERVO_PIN = 12;

// analog adjustments
const int FORWARD_POT_PIN = A5;
const int REVERSE_POT_PIN = A4;
// buttons


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
const int SENSOR_MAX_RANGE_CM = 500;
// speed of sound at sea level = 340.29 m / s
// spec range is 5m * 2 (return) = 10m
// 10 / 341 = ~0.029
const int SPEED_OF_SOUND_CM_PER_S = 34000;
const int SENSOR_MINIMAL_WAIT_ECHO_MILLIS = (SENSOR_MAX_RANGE_CM*2*1000)/SPEED_OF_SOUND_CM_PER_S;

/*
Robot related information
 */
const int ROBOT_TURN_RATE_PER_SECOND = 90;
const int SAFE_DISTANCE = 75;
const int CRITICAL_DISTANCE = 30;
const int MAX_TIME_UNIT_MILLIS = 3000;
const int MIN_TIME_UNIT_MILLIS = 500;
enum states {
  // start state
  INITIAL = 'I',
  QUICK_SWEEP = 'Q',
  // units advancement
  FORWARD_LEFT_UNIT = '1',
  FORWARD_UNIT = '2',
  FORWARD_RIGHT_UNIT = '3',
  REVERSE_LEFT_UNIT = '4',
  REVERSE_UNIT = '5',
  REVERSE_RIGHT_UNIT = '6',
  // decision making
  QUICK_DECISION = '?',
  // end state
  STUCK = 'K',
  STOP = '.'
};

enum directions {
  FORWARD_LEFT_DIR = '1',
  FORWARD_DIR = '2',
  FORWARD_RIGHT_DIR = '3',
  REVERSE_LEFT_DIR = '4',
  REVERSE_DIR = '5',
  REVERSE_RIGHT_DIR = '6',
};

enum commands {
  FORWARD,
  REVERSE,
  LEFT,
  RIGHT
};

enum ultrasonics {
  ULTRASONIC_FORWARD,
  ULTRASONIC_REVERSE,
  ULTRASONIC_DIRECTION_ARRAY_SIZE,
};


enum {
  WAIT_FOR_SERVO_TO_TURN,
  WAIT_FOR_ROBOT_TO_TURN,
  WAIT_FOR_ECHO,
  WAIT_FOR_ROBOT_TO_MOVE,
  WAIT_FOR_ROBOT_TO_ADVANCE_UNIT,
  WAIT_FOR_BUTTON_REREAD,
  WAIT_ARRAY_SIZE, // always last...
};

class TripleReadings {
public:
  int left;
  int right;
  int forward;
  int dir;
  int current_max_distance;
};

// Global variable
// this contains readings from a sweep
int sensor_distance_readings_cm[ULTRASONIC_DIRECTION_ARRAY_SIZE][NUMBER_READINGS];
const int NO_READING = -1;
char current_state = STOP;
// contains target angle
int turn_towards;
int current_max_distance = SAFE_DISTANCE; // needs a value for backward
int previous_state = FORWARD_UNIT;
int timed_operation_initiated_millis[WAIT_ARRAY_SIZE];
int timed_operation_desired_wait_millis[WAIT_ARRAY_SIZE];

// variables to store the servo current and desired angle 
int current_sensor_servo_angle = 0;

// Two useful objects...
Servo sensor_servo;  // create servo object to control a servo 
Ultrasonic sensor_forward = Ultrasonic(ULTRASONIC_FORWARD_TRIG, ULTRASONIC_FORWARD_ECHO);
Ultrasonic sensor_reverse = Ultrasonic(ULTRASONIC_REVERSE_TRIG, ULTRASONIC_REVERSE_ECHO);

void setup() { 
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

  full_stop();
  sensor_servo.attach(SENSOR_SERVO_PIN);
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
  }
}

void suspend(int dir) {
  digitalWrite(dir, LOW);
}

void full_stop() {
  digitalWrite(FORWARD_PIN, LOW);
  digitalWrite(REVERSE_PIN, LOW);
  digitalWrite(LEFT_PIN, LOW);
  digitalWrite(RIGHT_PIN, LOW);
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
  } 
  else if(initial_angle == desired_angle) {
    return 0;
  } 
  else if(initial_angle > desired_angle) {
    delta = initial_angle - desired_angle;
  } 
  else {
    delta = desired_angle - initial_angle;
  }
  return (float(delta)/float(turn_rate))*1000.0;
}

int convert_reading_index(int angle) {
  return angle/SENSOR_ARC_DEGREES;
}

int update_sensor_value(int sensor, int measured_value) {
  int index = convert_reading_index(current_sensor_servo_angle);
  // only update if the value is different beyond precision of sensor
  if(abs(measured_value - sensor_distance_readings_cm[sensor][index]) > SENSOR_PRECISION_CM) {
    sensor_distance_readings_cm[sensor][index] = measured_value;
  }
  if(LOG_LEVEL >= INFO) {
    Serial.print("Sensor reading:");
    Serial.print(sensor);
    Serial.print(":");
    Serial.print(current_sensor_servo_angle);
    Serial.print(":");
    Serial.println(sensor_distance_readings_cm[sensor][index]);
  }
  return sensor_distance_readings_cm[sensor][index];
}

int read_sensor(int sensor, Ultrasonic& sensor_object) {
  if(!timed_operation_expired(WAIT_FOR_SERVO_TO_TURN)) {
    return NO_READING;
  }

  if(!timed_operation_expired(WAIT_FOR_ECHO)) {
    return NO_READING;
  }

  int return_value = update_sensor_value(sensor, sensor_object.Ranging(CM));
  start_timed_operation(WAIT_FOR_ECHO, SENSOR_MINIMAL_WAIT_ECHO_MILLIS);
  return return_value;
}

int get_last_reading_for_angle(int sensor, int angle) {
  return sensor_distance_readings_cm[sensor][convert_reading_index(angle)];
}

int get_forward_time_millis() {
  int max_time = map(analogRead(FORWARD_POT_PIN), 0, 1024, MIN_TIME_UNIT_MILLIS, MAX_TIME_UNIT_MILLIS);
  int time = map(current_max_distance, 0, SENSOR_MAX_RANGE_CM, MIN_TIME_UNIT_MILLIS, max_time);
  return time;
}

int get_backward_time_millis() {
  // same logic because we don't have a front sensor...
  int max_time = map(analogRead(REVERSE_POT_PIN), 0, 1024, MIN_TIME_UNIT_MILLIS, MAX_TIME_UNIT_MILLIS);
  int time = map(current_max_distance, 0, SENSOR_MAX_RANGE_CM, MIN_TIME_UNIT_MILLIS, max_time);
  return time;
}

/*
make sure that the servo is at target position before returning
 if you don't use this, you need to check yourself that the timer has expired...
 */
void safe_update_servo_position(int desired_sensor_servo_angle) {  
  update_servo_position(desired_sensor_servo_angle);
  while(!timed_operation_expired(WAIT_FOR_SERVO_TO_TURN)) {
    check_button();
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

boolean potential_collision(int sensor) {
  return sensor_distance_readings_cm[sensor][SENSOR_LOOKING_FORWARD_READING_INDEX] <= SAFE_DISTANCE;
}

boolean imminent_collision(int sensor) {
  return sensor_distance_readings_cm[sensor][SENSOR_LOOKING_FORWARD_READING_INDEX] <= CRITICAL_DISTANCE;
}

int find_best_direction_degrees(int sensor) {
  int longest_value = -1;
  int longest_index = -1;
  for(int i=0; i<NUMBER_READINGS; i++) {
    if(sensor_distance_readings_cm[sensor][i] > longest_value && sensor_distance_readings_cm[sensor][i] >= SAFE_DISTANCE) {
      longest_value = sensor_distance_readings_cm[sensor][i];
      longest_index = i;
    }
  }
  if(longest_index != -1) {
    return longest_index * SENSOR_ARC_DEGREES;
  }
  return NO_READING;
}

int fill_data(int sensor, TripleReadings& readings) {
  readings.left = get_last_reading_for_angle(sensor, SENSOR_LOOKING_LEFT_ANGLE);
  readings.right = get_last_reading_for_angle(sensor, SENSOR_LOOKING_RIGHT_ANGLE);
  readings.forward = get_last_reading_for_angle(sensor, SENSOR_LOOKING_FORWARD_ANGLE);
  if(readings.left > readings.forward && readings.left > readings.right) {
    readings.current_max_distance = readings.left;
    readings.dir = LEFT;
  } 
  else if(readings.right > readings.forward && readings.right > readings.left) {
    readings.current_max_distance = readings.right;
    readings.dir = RIGHT;
  } 
  else {
    readings.current_max_distance = readings.forward;
    readings.dir = FORWARD;
  }
}

boolean all_safe(TripleReadings& readings) {
  if(readings.left >= SAFE_DISTANCE && readings.left >= SAFE_DISTANCE && readings.left >= SAFE_DISTANCE) {
    return true;
  }
  return false;
}
/*
Find out where we get the best distance range and go towards that
 If all the distances in front are unsafe, return REVERSE
 */
int quick_decision() {
  // one of the value has been updated, check to see if we should go left or right 
  // or just keep going forward
  TripleReadings readings_forward;
  TripleReadings readings_reverse;
  fill_data(ULTRASONIC_REVERSE, readings_forward);
  fill_data(ULTRASONIC_FORWARD, readings_reverse);
  if(readings_forward.current_max_distance < CRITICAL_DISTANCE || (readings_forward.current_max_distance < SAFE_DISTANCE && readings_forward.current_max_distance < readings_reverse.current_max_distance)) {
    if(readings_reverse.current_max_distance < CRITICAL_DISTANCE) {
      return NO_READING;
    }
    if(all_safe(readings_reverse)) {
      if(previous_state == FORWARD_LEFT_UNIT) {
        return REVERSE_LEFT_UNIT;
      } else if(previous_state == FORWARD_RIGHT_UNIT) {
        return REVERSE_RIGHT_UNIT;
      }
    }
    
    switch(readings_reverse.dir) {
    case LEFT:
      return REVERSE_RIGHT_UNIT;
      break;
    case RIGHT:
      return REVERSE_LEFT_UNIT;
      break;
    case FORWARD:
      return REVERSE_UNIT;
      break;
    }
  }
  
  switch(readings_forward.dir) {
  case LEFT:
    return FORWARD_LEFT_UNIT;
    break;
  case RIGHT:
    return FORWARD_RIGHT_UNIT;
    break;
  case FORWARD:
    return FORWARD_UNIT;
    break;
  }
}

/*
completes once the sensor has readings left, right and center
 */
boolean check_left;
int quick_sweep_number_readings = 0; // use modulo 4 to get every three readings
int sensor_array_read_next;
void init_quick_sweep() {
  full_stop();
  sensor_array_read_next = FORWARD_DIR;
  update_servo_position(SENSOR_LOOKING_FORWARD_ANGLE);
  current_state = QUICK_SWEEP;
}

boolean quick_sweep() {
  // we check if we have an updated value here
  int read_value;
  switch(sensor_array_read_next) {
  case FORWARD_DIR:
  case FORWARD_LEFT_DIR:
  case FORWARD_RIGHT_DIR:
    read_value = read_sensor(ULTRASONIC_FORWARD, sensor_forward);
    break;
  case REVERSE_LEFT_DIR:
  case REVERSE_DIR:
  case REVERSE_RIGHT_DIR:
    read_value = read_sensor(ULTRASONIC_REVERSE, sensor_reverse);
    break;
  }
  if(read_value != NO_READING) {
    switch(sensor_array_read_next) {
    case FORWARD_DIR:
      sensor_array_read_next = REVERSE_DIR;
      break;
    case REVERSE_DIR:
      sensor_array_read_next = FORWARD_LEFT_DIR;       
      update_servo_position(SENSOR_LOOKING_LEFT_ANGLE);
      break;
    case FORWARD_LEFT_DIR:
      sensor_array_read_next = REVERSE_LEFT_DIR;
      break;
    case REVERSE_LEFT_DIR:
      sensor_array_read_next = FORWARD_RIGHT_DIR;         
      update_servo_position(SENSOR_LOOKING_RIGHT_ANGLE);
      break;
    case FORWARD_RIGHT_DIR:
      sensor_array_read_next = REVERSE_RIGHT_DIR;
      break;
    case REVERSE_RIGHT_DIR:
      sensor_array_read_next = FORWARD_DIR;
      update_servo_position(SENSOR_LOOKING_FORWARD_ANGLE);
      return true; // completed sweep!
      break;
    }
  }
  return false;
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
  update_servo_position(SENSOR_LOOKING_FORWARD_ANGLE);  
  switch(decision) {
  case FORWARD_LEFT_UNIT:
    go(LEFT);
    break;
  case FORWARD_RIGHT_UNIT:
    go(RIGHT);
    break;
  case FORWARD_UNIT:
    break;
  case REVERSE_LEFT_UNIT:
    go(RIGHT);
    break;
  case REVERSE_RIGHT_UNIT:
    go(LEFT);
    break;
  case REVERSE_UNIT:
    break;
  default:
    if(LOG_LEVEL >= ERROR) {
      Serial.print("BAD STATE IN init_direction_unit:");
      Serial.println(decision);
    }
    break;
  }
  previous_state = current_state;
  current_state = decision;
  int dir;
  int time_millis;
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
    if(LOG_LEVEL >= ERROR) {
      Serial.print("BAD STATE IN init_direction_unit:");
      Serial.println(decision);
    }
    break;
  }
  int forward_time_millis = get_forward_time_millis();
  if(LOG_LEVEL>=INFO) {
    Serial.print("Will move for (ms): ");
    Serial.println(forward_time_millis);
  }
  start_timed_operation(WAIT_FOR_ROBOT_TO_ADVANCE_UNIT, time_millis);
  go(dir);
}

void check_button() {
  // read the state of the pushbutton value:
  if(!timed_operation_expired(WAIT_FOR_BUTTON_REREAD)) {
    return;
  }
  int buttonState = digitalRead(PUSHBUTTON_PIN);
  // check if the pushbutton is pressed.
  // if it is, the buttonState is HIGH:
  if (buttonState == HIGH) {     
    if(LOG_LEVEL >= INFO) {
      Serial.println("Button pressed!");
    }
    if(current_state == STOP) {
      current_state = INITIAL;
    } 
    else {
      full_stop();
      current_state = STOP;
    }
    start_timed_operation(WAIT_FOR_BUTTON_REREAD, 1000);
  } 
}

void handle_unit(int sensor, Ultrasonic& sensor_object) {
  if(timed_operation_expired(WAIT_FOR_ROBOT_TO_ADVANCE_UNIT)) {
    init_quick_sweep();
  }
  if(read_sensor(sensor, sensor_object) != NO_READING) {
    if(potential_collision(sensor)) {
      init_quick_sweep();
    }
  }
}

void loop(){
  int initial_state = current_state;
  int decision;
  check_button();
  switch(current_state) {
    // initial; this initiates what type of sub-state-machine we want to use
    // unit: move one unit, scan, decide, move one unit, scan, decide, move one unit...
  case INITIAL:
    init_quick_sweep(); // change this to change sub-state-machine
    break;
  case QUICK_SWEEP:
    if(quick_sweep()) {
      // one sweep completed
      init_quick_decision();
    }
    break;
  case QUICK_DECISION:
    decision = quick_decision();
    if(decision != NO_READING) {
      init_direction_unit(decision);
    } 
    else {
      init_stuck();
    }
    break;
  case FORWARD_UNIT:
  case FORWARD_LEFT_UNIT:
  case FORWARD_RIGHT_UNIT:
    handle_unit(ULTRASONIC_FORWARD, sensor_forward);
    break;
  case REVERSE_UNIT:
  case REVERSE_LEFT_UNIT:
  case REVERSE_RIGHT_UNIT:
    handle_unit(ULTRASONIC_REVERSE, sensor_reverse);
    break;
  case STOP:
    // do nothing...
    if(LOG_LEVEL >= INFO) {
      if(millis() % 1000 == 0) {
        Serial.print('.');
      }
    }
    break;
  case STUCK:
    init_quick_sweep();
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


