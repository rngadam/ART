/****************************************************************************
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
#include <Max3421e.h>
#include <Usb.h>
#include <AndroidAccessory.h>
#include "types.h"
#include "logging.h"

AndroidAccessory acc(
  "XinCheJian",
  "ART",
  "Autonomous Robot Toy",
  "7.0",
  "http://www.xinchejian.com",
  "0000000013371337");

pin_t RIGHT_PIN = 6;
pin_t LEFT_PIN = 5;
pin_t BACKWARD_PIN = 4;
pin_t FORWARD_PIN = 3;

// 6 interrupts for 5 infrared sensors + AND gate for forward
interrupt_t LEFT_INTERRUPT = 0; // digital pin 2
pin_t SENSOR_LEFT_PIN = 2;
interrupt_t RIGHT_INTERRUPT = 1; // digital pin 3
pin_t SENSOR_RIGHT_PIN = 3;
interrupt_t BACKWARD_INTERRUPT = 5; // pin 18
pin_t SENSOR_BACKWARD_PIN = 18;
interrupt_t FORWARD_RIGHT_INTERRUPT = 4; // pin 19
pin_t SENSOR_FORWARD_RIGHT_PIN = 19;
interrupt_t FORWARD_LEFT_INTERRUPT = 3; // pin 20
pin_t SENSOR_FORWARD_LEFT_PIN = 20;
const byte FORWARD_INTERRUPT = 2; // pin 21
pin_t SENSOR_FORWARD_PIN = 21;

typedef union {
  boolean obstacles[8];
  byte data;
} 
obstacle_detected_t;

obstacle_detected_t collisions;

void forward_left() {
  Serial.println("forward_left");
  collisions.obstacles[FORWARD_LEFT_INTERRUPT] = digitalRead(SENSOR_FORWARD_LEFT_PIN);
}

void forward_right() {
  Serial.println("forward_right");
  collisions.obstacles[FORWARD_RIGHT_INTERRUPT] = digitalRead(SENSOR_FORWARD_RIGHT_PIN);
}

void left() {
  Serial.println("left");
  collisions.obstacles[LEFT_INTERRUPT] = digitalRead(SENSOR_LEFT_PIN);
}

void right() {
  Serial.println("right");
  collisions.obstacles[RIGHT_INTERRUPT] = digitalRead(SENSOR_RIGHT_PIN);
}

void backward() {
  Serial.println("backward");
  collisions.obstacles[BACKWARD_INTERRUPT] = digitalRead(SENSOR_BACKWARD_PIN);
}

void forward() {
  Serial.println("forward");
  collisions.obstacles[FORWARD_INTERRUPT] = digitalRead(SENSOR_FORWARD_PIN);
}

void sink(byte pin) {
  pinMode(pin, OUTPUT);
  digitalWrite(pin, HIGH);
}

void input(byte pin) {
  pinMode(pin, INPUT);
  digitalWrite(pin, HIGH); // pullup
}

void setup() {
  Serial.begin(115200);
  sink(FORWARD_PIN);
  sink(BACKWARD_PIN);
  sink(LEFT_PIN);
  sink(RIGHT_PIN);  

  input(FORWARD_LEFT_INTERRUPT);
  input(FORWARD_RIGHT_INTERRUPT);
  input(LEFT_INTERRUPT);
  input(RIGHT_INTERRUPT);
  input(BACKWARD_INTERRUPT);
  //input(FORWARD_INTERRUPT);

  attachInterrupt(FORWARD_LEFT_INTERRUPT, forward_left, FALLING);
  attachInterrupt(FORWARD_RIGHT_INTERRUPT, forward_right, FALLING);
  attachInterrupt(LEFT_INTERRUPT, left, FALLING);
  attachInterrupt(RIGHT_INTERRUPT, right, FALLING);
  attachInterrupt(BACKWARD_INTERRUPT, backward, FALLING);
  //attachInterrupt(FORWARD_INTERRUPT, forward, LOW);
  acc.powerOn();
}

/*****************************************************************************
 * RC CAR RELATED
 *****************************************************************************/
enum commands {
  FORWARD,
  BACKWARD,
  LEFT,
  RIGHT,
  // COMBINED
  FORWARD_LEFT,
  FORWARD_RIGHT,
  REVERSE_LEFT,
  REVERSE_RIGHT,
}; 

/*
Makes sure that exclusive directions are prohibited
 */
void go(enum_t dir) {
  switch(dir) {
  case FORWARD:
    digitalWrite(BACKWARD_PIN, LOW);
    digitalWrite(FORWARD_PIN, HIGH);   
    break;
  case BACKWARD:
    digitalWrite(FORWARD_PIN, LOW);   
    digitalWrite(BACKWARD_PIN, HIGH);   
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

void go_duration(enum_t dir, duration_ms_t duration) {
  go(dir);
}

void suspend(enum_t dir) {
  switch(dir) {
  case FORWARD:
    digitalWrite(FORWARD_PIN, LOW);   
    break;
  case BACKWARD:
    digitalWrite(BACKWARD_PIN, LOW);   
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

void full_stop() {
  suspend(FORWARD);
  suspend(BACKWARD);
  suspend(LEFT);
  suspend(RIGHT);
}

void loop() {
  byte err;
  byte idle;
  static byte count = 0;
  byte msg[3];
  long touchcount;

  if (acc.isConnected()) {  
    int len = acc.read(msg, sizeof(msg), 1);    
    if(len > 0) {
      /**
       * 0x1  0x2  0x3
       *
       *      0x0
       *
       * 0x4  0x5  0x6
       */
      switch(msg[0]) {
      case 0x0: // full stop
        full_stop();
        break;
      case 0x1:
        go_duration(LEFT, msg[1]);
        go_duration(FORWARD, msg[1]);
        break;
      case 0x2:
        suspend(LEFT);
        suspend(RIGHT);
        go_duration(FORWARD, msg[1]);
        break;
      case 0x3:
        go_duration(RIGHT, msg[1]);
        go_duration(FORWARD, msg[1]);
        break;
      case 0x4:
        go_duration(RIGHT, msg[1]);
        go_duration(BACKWARD, msg[1]);
        break;
      case 0x5:
        suspend(LEFT);
        suspend(RIGHT);
        go_duration(BACKWARD, msg[1]);
        break;
      case 0x6:
        go_duration(LEFT, msg[1]);
        go_duration(BACKWARD, msg[1]);
        break;
      default:
        Serial.println("Invalid command sent");
      }
    }
    msg[0] = 0x1;
    msg[1] = collisions.data;
    acc.write(msg, 2);
  }
}


