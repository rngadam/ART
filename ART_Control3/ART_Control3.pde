#include <Servo.h> 
#include <limits.h>

Servo sensor_servo;  // create servo object to control a servo 

const int FORWARD =  2;      // the number of the LED pin
const int REVERSE =  3;  
const int LEFT = 4;  
const int RIGHT =  5;  
const int SENSOR_SERVO = 11;
const int SWEEPER_ULTRASONIC_SENSOR = A0;
const int MINIMUM_SENSOR_READ_MILLIS = 50;
const boolean SENSOR_DIR_LEFT = true;
const boolean SENSOR_DIR_RIGHT = false;
const int NO_READING = -1;
const byte SENSOR_LOOKING_FORWARD = 90; 
const byte SERVO_MAX_RANGE = 180;
const byte SENSOR_ARC_DEGREES = 30; // 180, 90, 30 all divisible by 30
const int NUMBER_READINGS = SERVO_MAX_RANGE/SENSOR_ARC_DEGREES;
boolean sensor_dir = SENSOR_DIR_LEFT;
const int MAXIMUM_SENSOR_SERVO_POS = 180;
const int MINIMUM_SENSOR_SERVO_POS = 1;
const int MINIMUM_DISTANCE = 50;

enum states {
  SWEEPING,
  GO,
  DECISION,
  STUCK,
  TURN
};

int sensor_servo_pos = SENSOR_LOOKING_FORWARD;    // variable to store the servo position 
int sensor_distance_readings_cm[NUMBER_READINGS];
char current_state = SWEEPING;
int timed_operation_initiated = 0;
int turn_towards;

void setup() { 
  // initialize the pushbutton pin as an input:
  pinMode(FORWARD, OUTPUT);     
  pinMode(REVERSE, OUTPUT);    
  pinMode(LEFT, OUTPUT);  
  pinMode(RIGHT, OUTPUT);  
  pinMode(SWEEPER_ULTRASONIC_SENSOR, INPUT);
  sensor_servo.attach(SENSOR_SERVO);
  Serial.begin(9600);
}

char update_state(char state, int reason) {
  char previous_state = current_state;
  if(state != current_state) {
    current_state = state;
    Serial.print(current_state);  
    Serial.println(reason);
  }
  return previous_state;
}

void go(int dir) {
  switch(dir) {
  case FORWARD:
    digitalWrite(REVERSE, LOW);
    // lets not go too fast...   
    go(FORWARD);
    break;
  case REVERSE:
    digitalWrite(FORWARD, LOW);   
    go(REVERSE);
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
  suspend(FORWARD);
  suspend(REVERSE);
  suspend(LEFT);
  suspend(RIGHT);
}


boolean timed_operation_expired(int duration) {
  int current_time = millis();
  if((timed_operation_initiated - current_time) < duration) {
    return false;
  }

  return true;
}

void start_timed_operation() {
  timed_operation_initiated = millis();
}

boolean sensor_sweep() {
  if(!timed_operation_expired(MINIMUM_SENSOR_READ_MILLIS)) {
    return false;
  }

  sensor_servo_pos += (sensor_dir == SENSOR_DIR_LEFT ? 1 : -1) * SENSOR_ARC_DEGREES;
  if(sensor_servo_pos >= 180) {
    sensor_dir = !sensor_dir;
    sensor_servo_pos = MAXIMUM_SENSOR_SERVO_POS;
    return true;
  } 
  else if(sensor_servo_pos <= 0) {
    sensor_dir = !sensor_dir;
    sensor_servo_pos = MINIMUM_SENSOR_SERVO_POS;    
    return true;
  }
  sensor_distance_readings_cm[sensor_servo_pos/SENSOR_ARC_DEGREES] = analogRead(SWEEPER_ULTRASONIC_SENSOR);

  sensor_servo.write(sensor_servo_pos-1);              // tell servo to go to position in variable 'pos' 
  start_timed_operation();
  Serial.print(sensor_dir);
  Serial.println(sensor_servo_pos);
  return false;
}

void start_sweep() {
  current_state = SWEEPING;
  for(int i=0; i<NUMBER_READINGS; i++) {
    sensor_distance_readings_cm[i] = NO_READING;
  }
  sensor_servo_pos = MINIMUM_SENSOR_SERVO_POS;
}

boolean potential_collision() {
  return sensor_distance_readings_cm[SENSOR_LOOKING_FORWARD/SENSOR_ARC_DEGREES] <= MINIMUM_DISTANCE;
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
}

void start_turn() {
  current_state = TURN;
  sensor_servo_pos = SENSOR_LOOKING_FORWARD;
  if(turn_towards < SENSOR_LOOKING_FORWARD) {
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
  switch(current_state) {
  case SWEEPING:
    if(sensor_sweep()) {
      // sweep completed, decision time!
      current_state = DECISION;
      sensor_servo_pos = SENSOR_LOOKING_FORWARD;
    }
    break;
  case GO: 
    if(potential_collision()) {
      full_stop();
      start_sweep();
    } 
    else {
      go(FORWARD);
    }
    break;
  case DECISION:
    turn_towards = find_best_direction_degrees();
    if(turn_towards != NO_READING) {
      start_turn();
    } 
    else {
      current_state = STUCK;
    }
    break;
  case STUCK:
    // check if we can reverse...
    // for now... don't move
    break;
  case TURN:
    if(potential_collision()) {
      full_stop();
    }
    if(handle_turn()) {
      current_state = GO;
    }
    break;
  }
}

