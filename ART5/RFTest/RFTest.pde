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

void setup() {
  Serial.begin(9600);

  // start the SPI library:
  SPI.begin();

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
  writeRegister(ADDR_FSTEST, FSTEST);
  writeRegister(ADDR_TEST2, TEST2);
  writeRegister(ADDR_TEST1, TEST1);
  writeRegister(ADDR_TEST0, TEST0);
  // strobe configuration
  //cc1100WriteTatab("\xc0\xc8\x85\x60",4);
  //cc1100Strobecommand(cc1100_STROBE_SFSTXON(0));
  //cc1100Strobecommand(cc1100_STROBE_SFRX(0));
  //cc1100Strobecommand(cc1100_STROBE_SRX(0));
  // give the sensor time to set up:
  delay(100);
}

void loop() {
}

void writeRegister(byte thisRegister, byte thisValue) {
  SPI.transfer(thisRegister); //Send register location
  SPI.transfer(thisValue);  //Send value to record into register

  // take the chip select high to de-select:
  //digitalWrite(chipSelectPin, HIGH);
}
