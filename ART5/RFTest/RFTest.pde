#include <SPI.h>
#include "cc1100_rf_settings.h"

/* 

Reference http://klk64.com/arduino-spi/

SPI (RF communication transceiver) uses these pins:

http://www.arduino.cc/playground/Code/Spi

pin 9 -> to transceiver PAC (orange, pin 05)  
pin 10	SS	SPI slave select ---> to transceiver CSn (white, pin 06)
pin 11	MOSI	SPI master out, slave in ---> to transceiver SI (green, pin 30)
pin 12	MISO	SPI master in, slave out ---> to transceiver SO (blue, 04)
pin 13	SCK	SPI clock ---> to transceiver SLCK  (yellow, 29)
pin A0 -> to transceiver GD0 (orange, 27)

Transceiver pinout (femelle header -> ribbon cable -> 32 pins IC):

01)5V    32)GND
02)5V    31)GND
03)3.3V  30)SI
04)SO    29)SCLK
05)PAC   28)GDO2
06)CSn   27)GDO0
07)NC    26)NC
08)NC    25)NC
09)GND   24)GND

*/

const byte PAC_PIN = 9;
const byte SS_PIN = 10;
const byte MOSI_PIN = 11;
const byte MISO_PIN = 12;
const byte SCK_PIN = 13;
const byte TEMP_PIN = A0;

void setup() {
  Serial.begin(9600);
  pinMode(SS_PIN, OUTPUT);
  pinMode(PAC_PIN, OUTPUT);
  pinMode(TEMP_PIN, INPUT);
  

  // start the SPI library:
  SPI.begin();
  /* from CC1101 SWRA112B SPI access
  
  The SPI interface on the MCU must be configured to operate in master mode. The Clock
  phase should be configured so that data is centered on the first positive going edge of 
  SCLK period and the polarity should be chosen so that the SCLK line is low in idle state. 
  
  Please see the chip’s data sheet for details  on the SPI Interface timing requirements. Pay 
  special attention to how the max SCLK frequency (fsclk) changes, depending on how the SPI 
  interface is used. The SPI clock can run at max 10 MHz, given that there is a minimum delay 
  of 100 ns inserted between address byte and data byte (single access), or between address 
  and data, and between each data byte (burst access). See Figure 3. 
   
  If no delay is inserted between bytes, max clock speed is 9 MHz for single access (see Figure 
  4) and 6.5 MHz for burst access (Figure 5). 
  
  NDLR: Arduino clock is 16Mhz
  
  http://en.wikipedia.org/wiki/Serial_Peripheral_Interface_Bus#Mode_Numbers
  
  At CPOL=0 the base value of the clock is zero
    For CPHA=0, data is captured on the clock's rising edge (low→high transition) and data is propagated on a falling edge (high→low clock transition).
    For CPHA=1, data is captured on the clock's falling edge and data is propagated on a rising edge.
  At CPOL=1 the base value of the clock is one (inversion of CPOL=0)
    For CPHA=0, data is captured on clock's falling edge and data is propagated on a rising edge.
    For CPHA=1, data is captured on clock's rising edge and data is propagated on a falling edge.
  
  http://arduino.cc/en/Reference/SPI
  
  Mode	Clock Polarity (CPOL)	Clock Phase (CPHA)
  0	0	                0
  1	0	                1
  2	1	                0
  3	1	                1
  
  ...so mode 0 since the datasheet matches the diagram for CPOL=0, CPHA=0
  */
  SPI.setBitOrder(MSBFIRST);
  SPI.setDataMode(SPI_MODE0);
  SPI.setClockDivider(SPI_CLOCK_DIV4); // 16Mhz/4 = 4Mhz
  
  outputConfig(rfSettings);
  powerUpReset();
  
  //Configure registers to match NetUSB
  for(byte i=0; i<ADDR_RCCTRL0+1; i++) {
    writeRegister(i, rfSettings.registers[i]);
  }
  
  // strobe configuration
  writeRegisterBurst(CCxxx0_PATABLE, PA_TABLE, 8);
  
  digitalWrite(PAC_PIN, LOW);
  digitalWrite(PAC_PIN, HIGH);
  // give the device time to set up:
  delay(100);
  idle();
}

enum desired_function {
  TEMPERATURE,
};

int desired_function = TEMPERATURE;

void loop() {
  switch(desired_function) {
    case TEMPERATURE:
      outputState();
      byte temperature = outputTemperature();
      sendPacket(&temperature, 1);
      outputState();
      break;
  }
  delay(1000);
}

void outputConfig(const settings_u& rfSettings) {
  if(rfSettings.rfSettingsValues.gdo2_cfg & CHP_RDY) {
    Serial.println("GDO2 output CHP_RDY");
  }
  if(rfSettings.rfSettingsValues.gdo2_inv) {
    Serial.println("GDO2 inverted output");  
  }
}

// Write values to on-chip transfer buffer
void sendPacket(const byte* buffer, byte len) {
  writeRegister(CCxxx0_TXFIFO, len);
  writeRegisterBurst(CCxxx0_TXFIFO, buffer, len);
  strobe(CCxxx0_STX); // go to transfer mode
}

// see state diagram pg 48
byte outputState() {
  int state = readState();
  Serial.print("state: ");
  Serial.println(state & 0xF);
  return state;
}

byte outputTemperature() {
  int value = analogRead(TEMP_PIN);
  int millivolts = map(value, 0, 1023, 0, 5000); // analog read is 10-bit value for range 0-5V
  int temperature = map(millivolts, 747, 847, 0, 40); // SWRS061F pg 18
  Serial.print("millivolts:");
  Serial.println(millivolts);
  Serial.print("temp: ");
  Serial.println(temperature);
  return temperature;
}

void powerUpReset() {
  digitalWrite(SS_PIN, HIGH);
  delay(1); 
  digitalWrite(SS_PIN, LOW);
  delay(1); 
  digitalWrite(SS_PIN, HIGH);
  delay(41);
  reset(); 
}

void reset() {
  // RESET  
  strobe(CCxxx0_SRES);
}

void idle() {
  // go to idle
  strobe(CCxxx0_SIDLE);
  writeRegister(ADDR_PTEST, 0xBF); // necessary in the idle state to get temperature output
}

void writeRegister(byte thisRegister, byte thisValue) {
  digitalWrite(SS_PIN, LOW);
  SPI.transfer(thisRegister); //Send register location
  SPI.transfer(thisValue);  //Send value to record into register
  digitalWrite(SS_PIN, HIGH);
}

void writeRegisterBurst(byte thisRegister, const byte* thisValue, byte count) {
  digitalWrite(SS_PIN, LOW);
  SPI.transfer(thisRegister|WRITE_BURST); //Send register location
  for(int i=0; i<count; i++) {
    SPI.transfer(thisValue[i]);  //Send value to record into register
  }
  digitalWrite(SS_PIN, HIGH);
}

void strobe(byte thisRegister) {
  digitalWrite(SS_PIN, LOW);
  SPI.transfer(thisRegister); //Send register location
  digitalWrite(SS_PIN, HIGH);
}

byte readRegister(byte thisRegister) {
  byte result;
  digitalWrite(SS_PIN, LOW);
  SPI.transfer(thisRegister|READ_SINGLE); //Send register location + single read
  result = SPI.transfer(0x00);
  digitalWrite(SS_PIN, HIGH);  
  return result;
}

byte readState() {
  byte result;
  digitalWrite(SS_PIN, LOW);
  SPI.transfer(CCxxx0_MARCSTATE|READ_BURST); //Send register location + single read
  result = SPI.transfer(0x00);
  digitalWrite(SS_PIN, HIGH);  
  return result;
}
