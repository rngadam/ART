#include <SPI.h>
#include "cc1100.h"

/* 

Reference http://klk64.com/arduino-spi/

SPI (RF communication transceiver) uses these pins:

http://www.arduino.cc/playground/Code/Spi
      
pin 10	SS	SPI slave select ---> to transceiver CSn (yellow)
pin 11	MOSI	SPI master out, slave in ---> to transceiver SI (blue)
pin 12	MISO	SPI master in, slave out ---> to transceiver SO (orange)
pin 13	SCK	SPI clock ---> to transceiver SLCK  (white)
*/

const byte SS_PIN = 10;
const byte MOSI_PIN = 11;
const byte MISO_PIN = 12;
const byte SCK_PIN = 13;
const byte TEMP_PIN = A0;

void setup() {
  Serial.begin(9600);
  pinMode(SS_PIN, OUTPUT);
  pinMode(TEMP_PIN, INPUT);

  // start the SPI library:
  SPI.begin();

  // RESET  
  readRegister(0x30);
  // go to idle
  readRegister(0x36);

  writeRegister(ADDR_IOCFG0, 0x80); // enable temperature on GDO0
  writeRegister(ADDR_PTEST, 0x7F); // necessary in the idle state
  
  // Default SPI settings according to http://www.arduino.cc/playground/Code/Spi
  // SPI Master enabled
  // MSB of the data byte transmitted first
  // SPI mode 0 (CPOL = 0, CPHA = 0)
  // SPI clock frequency = system clock / 4  
  //SPI.setBitOrder();
  //SPI.setDataMode();
  //SPI.setClockDivider();
  
  //Configure registers to match NetUSB
  for(byte i=0;i<39; i++) {
    writeRegister(i, cc1100regcfg[i]);
  }

  // additional configuration
  //writeRegister(ADDR_FSTEST, FSTEST);
  //writeRegister(ADDR_TEST2, TEST2);
  //writeRegister(ADDR_TEST1, TEST1);
  //writeRegister(ADDR_TEST0, TEST0);
  // strobe configuration
  //cc1100WriteTatab("\xc0\xc8\x85\x60",4);
  //cc1100Strobecommand(cc1100_STROBE_SFSTXON(0));
  //cc1100Strobecommand(cc1100_STROBE_SFRX(0));
  //cc1100Strobecommand(cc1100_STROBE_SRX(0));
  // give the device time to set up:
  delay(100);
}

void loop() {
  int value = analogRead(TEMP_PIN);
  int state = readRegister(0x35);

  Serial.print("temp: ");
  Serial.println(value);
  Serial.print("state: ");
  Serial.println(state & 0xF);
  delay(1000);
}

void writeRegister(byte thisRegister, byte thisValue) {
  digitalWrite(SS_PIN, LOW);
  SPI.transfer(thisRegister); //Send register location
  SPI.transfer(thisValue);  //Send value to record into register
  digitalWrite(SS_PIN, HIGH);
}

byte readRegister(byte thisRegister) {
  byte result;
  digitalWrite(SS_PIN, LOW);
  SPI.transfer(thisRegister|0x80); //Send register location + single read
  result = SPI.transfer(0x00);
  digitalWrite(SS_PIN, HIGH);  
  return result;
}
