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

/* Serial uses theses pins:
pin 0: RX
pin 1: TX
*/
const byte USERFUNCTION0_PIN = 2; //DIP11
const byte USERFUNCTION1_PIN = 3; //DIP12
const byte TRIGGERSONAR_PIN = 4; //DIP13
const byte SONARSEL0_PIN = 5; //DIP14
const byte SONARSEL1_PIN = 6; //DIP15
const byte DIRSEL0_PIN = 7; //DIP16
const byte DIRSEL1_PIN = 8; //DIP17
const byte DIRSEL2_PIN = 9; //DIP18
const byte ECHOSONAR_PIN = A0; //DIP36

/* SPI (RF communication transceiver) uses these pins:

http://www.arduino.cc/playground/Code/Spi

pin 10	SS	SPI slave select ---> to transceiver CSn (yellow)
pin 11	MOSI	SPI master out, slave in ---> to transceiver SI (blue)
pin 12	MISO	SPI master in, slave out ---> to transceiver SO (orange)
pin 13	SCK	SPI clock ---> to transceiver SLCK  (white)
*/
void setup() {

}

void loop() {
  digitalWrite(Trig_pin, LOW);
  delayMicroseconds(2);
  digitalWrite(Trig_pin, HIGH);
  delayMicroseconds(10);
  digitalWrite(Trig_pin, LOW);
  return pulseIn(Echo_pin,HIGH);
}
