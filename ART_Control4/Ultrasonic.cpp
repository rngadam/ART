/*
  Ultrasonic.cpp - Library for HC-SR04 Ultrasonic Ranging Module.library
 
 Created by ITead studio. Apr 20, 2010.
 iteadstudio.com
 
 Modified by Ricky Ng-Adam, January 2011
 */

#include "WProgram.h"
#include "Ultrasonic.h"

Ultrasonic::Ultrasonic(int TP, int EP)
{
  pinMode(TP, OUTPUT);
  pinMode(EP,INPUT);
  Trig_pin=TP;
  Echo_pin=EP;
}

long Ultrasonic::Timing()
{
  digitalWrite(Trig_pin, LOW);
  delayMicroseconds(2);
  digitalWrite(Trig_pin, HIGH);
  delayMicroseconds(10);
  digitalWrite(Trig_pin, LOW);
  return pulseIn(Echo_pin,HIGH);
}

long Ultrasonic::Ranging()
{
  return Timing()/29 / 2;
}

