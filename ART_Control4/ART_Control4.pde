#include <Ultrasonic.h>
#include <Servo.h> 
#include <limits.h>

/*****************************************************************************
 * LOGGING
 *****************************************************************************/
enum LOG_LEVELS {
  ERROR,
  TELEMETRY,
  INFO,
  DEBUG,
  TRACE,
};

enum telemetry_types {
  ULTRASONIC_SENSORS,
  STATE_CHANGE,
  SENSOR_SERVO_POSITION_CHANGE,
  CAR_GO_COMMAND,
  CAR_SUSPEND_COMMAND,
  MAX_TELEMETRY_TYPE,
};

char* telemetry_types_names[] = {
  "ULTRASONIC_SENSORS",
  "STATE_CHANGE",
  "SENSOR_SERVO_POSITION_CHANGE",
  "CAR_GO_COMMAND",
  "CAR_SUSPEND_COMMAND",
};

const int LOG_LEVEL = TRACE;

void log_bad_state(char* str, int value) {
  if(LOG_LEVEL >= ERROR) {
    Serial.print("ERROR: Bad state in: ");
    Serial.print(str);
    Serial.print(" value:");
    Serial.println(value);
    Serial.flush();
  }
}

void log_telemetry(int type, int source, int value) {
  if(type < 0 || type >= MAX_TELEMETRY_TYPE) {
    log_bad_state("log_telemetry: Incorrect log telemetry type", type);
  }
  unsigned long event_time = millis();
  if(LOG_LEVEL >= TELEMETRY) {
    log_telemetry_serial_print(event_time, type, source, value);
  }  
  if(LOG_LEVEL >= INFO) {
    //log_telemetry_serial_user_print(event_time, type, source, value);
  }
}

void log_telemetry_serial_print(unsigned long time, int type, int source, int value) {
  Serial.print("|");
  Serial.print(time);
  Serial.print(",");
  Serial.print(type);
  Serial.print(",");
  Serial.print(source);
  Serial.print(",");
  Serial.println(value);  
  Serial.flush();
}

void log_telemetry_serial_user_print(unsigned long time, int type, int source, int value) {
  Serial.print(time);
  Serial.print(",");
  Serial.print(telemetry_types_names[type]);
  Serial.print(",");
  if(type == STATE_CHANGE) {
    Serial.print((char)source);
    Serial.print(",");
    Serial.println((char)value);
  } else {
    Serial.print(source);
    Serial.print(",");
    Serial.println(value);
  }  
  Serial.flush();
}
/*****************************************************************************
 * ARDUINO PINS MAPPING
 *****************************************************************************/
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

/*****************************************************************************
 * TIMING RELATED
 *****************************************************************************/
enum waits_types {
  WAIT_FOR_SERVO_TO_TURN,
  WAIT_FOR_ROBOT_TO_TURN,
  WAIT_FOR_ECHO,
  WAIT_FOR_ROBOT_TO_MOVE,
  WAIT_FOR_ROBOT_TO_ADVANCE_UNIT,
  WAIT_FOR_BUTTON_REREAD,
  WAIT_ARRAY_SIZE, // always last...
};

unsigned long timed_operation_initiated_millis[WAIT_ARRAY_SIZE];
unsigned int timed_operation_desired_wait_millis[WAIT_ARRAY_SIZE];

/*
record current time to compare to
 */
void start_timed_operation(int index, unsigned int duration) {
  timed_operation_initiated_millis[index] = millis();
  timed_operation_desired_wait_millis[index] = duration;
  if(LOG_LEVEL >= TRACE) {
    Serial.print("Timer added type ");
    Serial.print(index);
    Serial.print(" wait in millis:");
    Serial.println(duration);
    Serial.flush();
  }
}

/*
Check whether the timer has expired
 if expired, returns true else returns false
 */
boolean timed_operation_expired(int index) {
  unsigned long current_time = millis();
  if((current_time - timed_operation_initiated_millis[index]) < timed_operation_desired_wait_millis[index]) {
    return false;
  }
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
const int SERVO_TURN_RATE_PER_SECOND = 100; // 100 = 60/(0.2*3) where 3 is caused by load?
Servo sensor_servo;   

unsigned int expected_wait_millis(int turn_rate, int initial_angle, int desired_angle) {
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

void update_servo_position(int desired_sensor_servo_angle) {  
  switch(desired_sensor_servo_angle) {
    case 0:
    case 45:
    case 90:
    case 135:
      // OK!
      break;
     default:
       log_bad_state("Bad servo position update", desired_sensor_servo_angle);
       return;
       break;
  }
  if(sensor_servo.read() != desired_sensor_servo_angle) {
    sensor_servo.write(desired_sensor_servo_angle);              // tell servo to go to position in variable 'pos' 

    unsigned int wait_millis = expected_wait_millis(SERVO_TURN_RATE_PER_SECOND, sensor_servo.read(), desired_sensor_servo_angle);
    start_timed_operation(WAIT_FOR_SERVO_TO_TURN, wait_millis);

    log_telemetry(SENSOR_SERVO_POSITION_CHANGE, sensor_servo.read(), desired_sensor_servo_angle);
  } else if (LOG_LEVEL >= TRACE) {
    Serial.println("Requesting sensor servo position already set");
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
const int SENSOR_ARC_DEGREES = 15; // 180, 90, 15 all divisible by 15
const int SENSOR_PRECISION_CM = 1;
const int SENSOR_MAX_RANGE_CM = 500;
// speed of sound at sea level = 340.29 m / s
// spec range is 5m * 2 (return) = 10m
// 10 / 341 = ~0.029
const int SPEED_OF_SOUND_CM_PER_S = 34000;
const int SENSOR_MINIMAL_WAIT_ECHO_MILLIS = (SENSOR_MAX_RANGE_CM*2*1000)/SPEED_OF_SOUND_CM_PER_S;

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

const int sensor_position_to_servo_angle[] = {
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

int sensor_array_read_next;
int sensor_distance_readings_cm[NUMBER_READINGS];
const int NO_READING = -1;

Ultrasonic sensor_forward = Ultrasonic(ULTRASONIC_FORWARD_TRIG, ULTRASONIC_FORWARD_ECHO);
Ultrasonic sensor_reverse = Ultrasonic(ULTRASONIC_REVERSE_TRIG, ULTRASONIC_REVERSE_ECHO);

int current_max_sensor() {
  int max_sensor = SENSOR_LEFT;
  for(int i=1;i<NUMBER_READINGS; i++) {
    if(sensor_distance_readings_cm[i] >= sensor_distance_readings_cm[max_sensor]) {
      max_sensor = i;
    }
  }
  return max_sensor;
}

int current_max_distance_cm() {
  return sensor_distance_readings_cm[current_max_sensor()];
}

int update_sensor_value(int sensor, int measured_value) {
  // only update if the value is different beyond precision of sensor
  if(abs(measured_value - sensor_distance_readings_cm[sensor]) > SENSOR_PRECISION_CM) {
    sensor_distance_readings_cm[sensor] = measured_value;
  }
  return sensor_distance_readings_cm[sensor];
}

int read_sensor(int sensor, Ultrasonic& sensor_object) {
  if(!timed_operation_expired(WAIT_FOR_SERVO_TO_TURN)) {
    return NO_READING;
  }

  if(!timed_operation_expired(WAIT_FOR_ECHO)) {
    return NO_READING;
  }

  if(sensor_servo.read() != sensor_position_to_servo_angle[sensor]) {
    if(LOG_LEVEL >= ERROR) {
      Serial.print("ERROR: read_sensor() servo current_position does not match sensor desired angle:");
      Serial.print(" current servo position:");
      Serial.print(sensor_servo.read());
      Serial.print(" expected:");
      Serial.print(sensor_position_to_servo_angle[sensor]);
      Serial.print(" from sensor:");
      Serial.println(sensor);
    }
    return NO_READING;
  }
  
  int return_value = update_sensor_value(sensor, sensor_object.Ranging(CM));
  log_telemetry(ULTRASONIC_SENSORS, sensor, return_value); 
  start_timed_operation(WAIT_FOR_ECHO, SENSOR_MINIMAL_WAIT_ECHO_MILLIS);
  return return_value;
}

/*****************************************************************************
 * RC CAR RELATED
 *****************************************************************************/
const int ROBOT_TURN_RATE_PER_SECOND = 90;
//const int SAFE_DISTANCE_LARGE_TURN = 116; // the distance at which we can safely complete a 90 degrees turn
const int SAFE_DISTANCE_LARGE_TURN = 50; // distance between table and wall and minus size of robot (when robot is stuck...)
const int SAFE_DISTANCE_SMALL_TURN = 25; // one car length...
const int MAX_TIME_UNIT_MILLIS = 3000;
const int MIN_TIME_UNIT_MILLIS = 500;
const int CAR_LENGTH = 25;
const int CAR_WIDTH = 15;

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

int current_command = 0;

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
  default:
    log_bad_state("go", dir);
    break;  
  }
}

void suspend(int dir) {
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
    log_bad_state("suspend", dir);
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
void go2(int dir) {
  int dir_bitmask = 1 << dir;
  if(!(current_command & dir_bitmask)) {
    go(dir);
    current_command = current_command | dir_bitmask;
    log_telemetry(CAR_GO_COMMAND, current_command, dir);
  }
}

void suspend2(int dir) {
  int dir_bitmask = 1 << dir;
  if(current_command & dir_bitmask) {
    suspend(dir);
    current_command = current_command ^ dir_bitmask;
    log_telemetry(CAR_SUSPEND_COMMAND, current_command, dir);    
  }
}

void full_stop() {
  suspend2(FORWARD);
  suspend2(REVERSE);
  suspend2(LEFT);
  suspend2(RIGHT);
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

char current_state = STOP;
int previous_state = FORWARD_UNIT;

/*****************************************************************************
 * SETUP
 *****************************************************************************/
void setup() { 
  // make sure we get all error message output
  Serial.begin(9600);
  Serial.println("ART STARTED");
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
  for(int i=0; i<WAIT_ARRAY_SIZE; i++) {
    timed_operation_initiated_millis[i] = 0;  
    timed_operation_desired_wait_millis[i] = 0;
  }
  Serial.println("ART SETUP COMPLETED");
}

/*****************************************************************************
 * DECISION HELPERS
 *****************************************************************************/
int get_forward_time_millis() {
  int max_time = map(analogRead(FORWARD_POT_PIN), 0, 1024, MIN_TIME_UNIT_MILLIS, MAX_TIME_UNIT_MILLIS);
  int time = map(current_max_distance_cm(), 0, SENSOR_MAX_RANGE_CM, MIN_TIME_UNIT_MILLIS, max_time);
  return time;
}

int get_backward_time_millis() {
  // same logic because we don't have a front sensor...
  int max_time = map(analogRead(REVERSE_POT_PIN), 0, 1024, MIN_TIME_UNIT_MILLIS, MAX_TIME_UNIT_MILLIS);
  int time = map(current_max_distance_cm(), 0, SENSOR_MAX_RANGE_CM, MIN_TIME_UNIT_MILLIS, max_time);
  return time;
}

boolean is_safe_large_turn(int sensor) {
  return sensor_distance_readings_cm[sensor] >= SAFE_DISTANCE_LARGE_TURN;
}

boolean is_safe_small_turn(int sensor) {
  return sensor_distance_readings_cm[sensor] >= SAFE_DISTANCE_SMALL_TURN;
}

boolean is_greater(int sensor_a, int sensor_b) {
  return sensor_distance_readings_cm[sensor_a] > sensor_distance_readings_cm[sensor_b];
}

boolean approximate_equal(int current, int target) {
  return current > (target - CAR_LENGTH/2) && current < (target + CAR_LENGTH/2);
}

/*****************************************************************************
 * STATE INITS AND HANDLERS
 *****************************************************************************/
/*
Find out where we get the best distance range and go towards that
 If all the distances in front are unsafe, return REVERSE
 */
 
 /*****************************************************************************
 * STANDSTILL DECISION
 *****************************************************************************/
void init_standstill_decision() {
  full_stop();
  current_state = STANDSTILL_DECISION;
}

int standstill_decision() {
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
  } else if(is_safe_small_turn(SENSOR_RIGHT) && is_safe_small_turn(SENSOR_BACK_LEFT)) {
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
    } else {
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
  int read_value = NO_READING;
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
      log_bad_state("full_sweep (reading value)", sensor_array_read_next);
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
      sensor_array_read_next = SENSOR_BACK_LEFT;
      break;
    case SENSOR_BACK_LEFT:
      sensor_array_read_next = SENSOR_RIGHT;         
      break;
    case SENSOR_RIGHT:
      sensor_array_read_next = SENSOR_BACK_RIGHT;
      break;
    case SENSOR_BACK_RIGHT:
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
      log_bad_state("full_sweep (figuring where to go next)", sensor_array_read_next);
      break;
    }
    update_servo_position(sensor_position_to_servo_angle[sensor_array_read_next]);
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
int target_distance_cm = SAFE_DISTANCE_LARGE_TURN;
int small_turn_state;
void init_small_turn(int small_turn_type) {
  full_stop();
  update_servo_position(sensor_position_to_servo_angle[SENSOR_FRONT]);  
  target_distance_cm = current_max_distance_cm();
  if(small_turn_type == SMALL_TURN_CCW) {
    small_turn_state = REVERSE_RIGHT;
  } else {
    small_turn_state = REVERSE_LEFT;
  }
}

boolean handle_small_turn() {
  if(!timed_operation_expired(WAIT_FOR_ROBOT_TO_MOVE)) {
    // there's a pending timer...
    return false;
  }
  
  if(approximate_equal(target_distance_cm, read_sensor(SENSOR_FRONT, sensor_forward))) {
    full_stop();
    return true;
  }
  
  switch(small_turn_state) {
    case FORWARD_LEFT:
      go2(FORWARD);
      go2(LEFT);
      small_turn_state = REVERSE_RIGHT;
      break;
    case REVERSE_RIGHT:
      go2(REVERSE);
      go2(RIGHT);
      small_turn_state = FORWARD_LEFT;
      break;
    case FORWARD_RIGHT:
      go2(FORWARD);
      go2(RIGHT);
      small_turn_state = REVERSE_LEFT;
      break;
    case REVERSE_LEFT:
      go2(REVERSE);
      go2(LEFT);
      small_turn_state = FORWARD_RIGHT;
      break;      
    default:
      log_bad_state("handle_small_turn", small_turn_state);
      break;
  }
  start_timed_operation(WAIT_FOR_ROBOT_TO_MOVE, MIN_TIME_UNIT_MILLIS);
  return false;
}

 /*****************************************************************************
 * SMALL STEPS (UNIT) MOVEMENTS WITH TIMER
 *****************************************************************************/
void init_direction_unit(int decision) {
  full_stop();
  update_servo_position(sensor_position_to_servo_angle[SENSOR_FRONT]);  

  switch(decision) {
  case FORWARD_LEFT_UNIT:
    go2(LEFT);
    break;
  case FORWARD_RIGHT_UNIT:
    go2(RIGHT);
    break;
  case REVERSE_LEFT_UNIT:
    go2(RIGHT);
    break;
  case REVERSE_RIGHT_UNIT:
    go2(LEFT);
    break;
  case REVERSE_UNIT:
  case FORWARD_UNIT:
    // do nothing, we will decide below what to do
    break;
  default:
    log_bad_state("full_sweep init_direction_unit (converting to wheel direction)", decision);
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
    log_bad_state("init_direction_unit (converting to forward or backward motion)", decision);
    break;
  }
  if(LOG_LEVEL >= INFO) {
    Serial.print("Will move for (ms): ");
    Serial.println(time_millis);
  }
  start_timed_operation(WAIT_FOR_ROBOT_TO_ADVANCE_UNIT, time_millis);
  go(dir);
}


void handle_unit(int sensor, Ultrasonic& sensor_object) {
  if(timed_operation_expired(WAIT_FOR_ROBOT_TO_ADVANCE_UNIT)) {
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
      update_servo_position(sensor_position_to_servo_angle[SENSOR_FRONT]); 
    }
    start_timed_operation(WAIT_FOR_BUTTON_REREAD, 1000);
  } 
}

 /*****************************************************************************
 * MAIN STATE MACHINE LOOP
 *****************************************************************************/
void loop(){
  int initial_state = current_state;
  int decision;
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
      } else {
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
    handle_unit(ULTRASONIC_FORWARD, sensor_forward);
    break;
  case REVERSE_UNIT:
  case REVERSE_LEFT_UNIT:
  case REVERSE_RIGHT_UNIT:
    handle_unit(ULTRASONIC_REVERSE, sensor_reverse);
    break;
  case SMALL_TURN_CW:
  case SMALL_TURN_CCW:
    if(handle_small_turn()) {
      // small turn completed with target max distance
      init_direction_unit(FORWARD_UNIT);   
    }
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
    init_full_sweep();
    break;

  default:
    log_bad_state("init_direction_unit (converting to forward or backward motion)", current_state);
    break;
  }

  if(initial_state != current_state) {
    if(LOG_LEVEL >= INFO) {
      log_telemetry(STATE_CHANGE, initial_state, current_state);
    }
  }
}


