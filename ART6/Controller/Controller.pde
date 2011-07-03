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
#include <limits.h>

/*****************************************************************************
 * NY LIBS
 *****************************************************************************/
#include "types.h"

/*****************************************************************************
 * LOGGING
 *****************************************************************************/
enum telemetry_types {
  INFRARED_SENSORS,
  STATE_CHANGE,
  SENSOR_SERVO_POSITION_CHANGE,
  CAR_GO_COMMAND,
  CAR_SUSPEND_COMMAND,
  MAX_TELEMETRY_TYPE,
};

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
// INFRARED
pin_t INFRARED_LEFT = A5;
pin_t INFRARED_RIGHT = A4;
pin_t INFRARED_LEFT_SIDE = A3;
pin_t INFRARED_RIGHT_SIDE = A2;
pin_t INFRARED_BACK = A1;

// various directions we can go to
pin_t FORWARD_COLLISION_PIN = 2;
pin_t REVERSE_COLLISION_PIN = 3;

pin_t FORWARD_PIN =  4;      // the number of the LED pin
pin_t REVERSE_PIN =  5;  
pin_t LEFT_PIN = 6;  
pin_t RIGHT_PIN =  7;  
//pin_t PUSHBUTTON_PIN = 10;
// servo


/*****************************************************************************
 * SENSORS
 *****************************************************************************/
enum sensor_position {
  SENSOR_LEFT, 
  SENSOR_FRONT, // unused 
  SENSOR_RIGHT,
  SENSOR_LEFT_SIDE,
  SENSOR_RIGHT_SIDE,
  SENSOR_BACK_LEFT, // unused
  SENSOR_BACK, 
  SENSOR_BACK_RIGHT, // unused
  NUMBER_READINGS,
};

boolean sensor_readings[NUMBER_READINGS]; 
pin_t sensor_to_pin[] = { INFRARED_LEFT, 0, INFRARED_RIGHT, INFRARED_LEFT_SIDE, INFRARED_RIGHT_SIDE, 0, INFRARED_BACK, 0};
/*****************************************************************************
 * RC CAR RELATED
 *****************************************************************************/
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
void go(enum_t dir) {
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

void suspend(enum_t dir) {
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
void _go(enum_t dir) {
  bitmask8_t dir_bitmask = 1 << dir;
  if(!(current_command & dir_bitmask)) {
    _go(dir);
    current_command = current_command | dir_bitmask;
    LOG_TELEMETRY(CAR_GO_COMMAND, current_command, dir);
  }
}

void _suspend(enum_t dir) {
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
  INITIAL,
  FULL_SWEEP,
  // units advancement
  FORWARD_LEFT_UNIT,
  FORWARD_UNIT,
  FORWARD_RIGHT_UNIT,
  REVERSE_LEFT_UNIT,
  REVERSE_UNIT,
  REVERSE_RIGHT_UNIT,
  // decision making
  STANDSTILL_DECISION,
  // end state
  STUCK,
  STOP,
  SMALL_TURN_CCW,
  SMALL_TURN_CW,
};

/*****************************************************************************
 * SETUP
 *****************************************************************************/
 
void analogPullUp(pin_t pin) {
  pinMode(pin, INPUT);
  analogWrite(pin, HIGH);
}

void analogPullDown(pin_t pin) {
  pinMode(pin, INPUT);
  analogWrite(pin, LOW);
}

void digitalPullUp(pin_t pin) {
  pinMode(pin, INPUT);
  digitalWrite(pin, HIGH);
}

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
  
  digitalPullUp(FORWARD_COLLISION_PIN);
  digitalPullUp(REVERSE_COLLISION_PIN);
  
  /*analogPullUp(INFRARED_LEFT);
  analogPullUp(INFRARED_RIGHT);
  analogPullUp(INFRARED_LEFT_SIDE);
  analogPullUp(INFRARED_RIGHT_SIDE);
  analogPullUp(INFRARED_BACK);*/
    
  Serial.println("Full stop");
  full_stop();
  Serial.print("ART SETUP COMPLETED ");
  Serial.println(millis());
  
  attachInterrupt(0, forward_collision_detected, FALLING);
  attachInterrupt(1, reverse_collision_detected, FALLING);
}


boolean obstacle(enum_t sensor) {
  boolean value = analogRead(sensor_to_pin[sensor]) < 500;
  if(sensor_readings[sensor] != value) {
    sensor_readings[sensor] = value;
    LOG_TELEMETRY(INFRARED_SENSORS, sensor, value);
  }
  return sensor_readings[sensor];
}

/*****************************************************************************
 * MAIN STATE MACHINE LOOP
 *****************************************************************************/
boolean left, right, back, left_side, right_side;
boolean going_forward;
boolean stopped;

int go_right = 0;
int go_left = 0;
volatile int go_forward = 0;
volatile int go_reverse = 0;
volatile int collisions = 0;

void forward_collision_detected() {
  digitalWrite(FORWARD_PIN, LOW);   
  go_forward = 0;
}

void reverse_collision_detected() {
  digitalWrite(REVERSE_PIN, LOW);   
  go_reverse = 0;
}

void loop(){  
  left = obstacle(SENSOR_LEFT);
  right = obstacle(SENSOR_RIGHT);
  left_side = obstacle(SENSOR_LEFT_SIDE);
  right_side = obstacle(SENSOR_RIGHT_SIDE);
  back = obstacle(SENSOR_BACK);
  if(left) {
    go_right++; 
    go_reverse++;            
  } else {
    go_left++;
    go_forward++;
  }
  
  if(right) {
    go_left++; 
    go_reverse++;
  } else {
    go_right++;
    go_forward++;
  }
  
  if(back) {
    go_reverse = 0;
  } 
  
  if(right_side) {
    go_left++;
  } else {
    go_right++;
  }
 
  if(left_side) {
    go_right++;
  } else {
    go_left++;
  }
  
  if(go_right > 1000 || go_right < -1000) {
    go_right = 0;
  }
  if(go_left > 1000 || go_left < -1000) {
    go_left = 0;
  }
  if(go_forward > 1000 || go_forward < -1000) {
    go_forward = 0;
  }
  if(go_reverse > 1000 || go_reverse < -1000) {
    go_reverse = 0;
  }
  
  // decision time! 
  if(go_forward <= 0 && go_reverse <= 0) {
    full_stop();
    stopped = true;
  }
 
  if(go_forward > 0 && go_forward > go_reverse) {
    go(FORWARD);
    go_forward--;
    going_forward = true;
    stopped = false;
  } else if(go_reverse > 0) {
    go(REVERSE);
    go_reverse--;
    going_forward = false;
    stopped = false;
  } 
  
  if(!stopped) {
    if(go_left > 0 && go_left > go_right) {
      if(going_forward) {
        go(LEFT);
      } else {
        go(RIGHT);
      }
      go_left--;
    } else if(go_right > 0 && go_right > go_left) {
      if(going_forward) {
        go(RIGHT);
      } else {
        go(LEFT);
      }
      go_right--;
    }
  }
}
