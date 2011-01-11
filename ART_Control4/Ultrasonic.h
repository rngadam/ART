/*
  Ultrasonic.h - Library for HR-SC04 Ultrasonic Ranging Module.
 Created by ITead studio. Alex, Apr 20, 2010.
 iteadstudio.com
 
 Modified by Ricky Ng-Adam, January 2011  
 */


#ifndef Ultrasonic_h
#define Ultrasonic_h

#include "WProgram.h"

class Ultrasonic
{
public:
  Ultrasonic(int TP, int EP);
  long Timing();
  long Ranging();

private:
  int Trig_pin;
  int Echo_pin;
};

#endif

