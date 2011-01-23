/*****************************************************************************
 * RF Test Bench
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

#include <SPI.h>
#include "cc1100_rf_settings.h"

/* 

Reference http://klk64.com/arduino-spi/

SPI (RF communication transceiver) uses these pins:

http://www.arduino.cc/playground/Code/Spi

pin 8 -> to transceiver GDO2 (yellow, pin 28)
pin 9 -> to transceiver PAC (orange, pin 05)  
pin 10	SS	SPI slave select ---> to transceiver CSn (white, pin 06)
pin 11	MOSI	SPI master out, slave in ---> to transceiver SI (green, pin 30)
pin 12	MISO	SPI master in, slave out ---> to transceiver SO (blue, 04)
pin 13	SCK	SPI clock ---> to transceiver SLCK  (yellow, 29)
pin A0 -> to transceiver GD0 (orange, 27)

Transceiver pinout (femelle header -> ribbon cable -> 32 pins IC. Red line is #1):

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

const byte GDO2_PIN = 8;
const byte PAC_PIN = 9;
const byte SS_PIN = 10;
const byte MOSI_PIN = 11;
const byte MISO_PIN = 12;
const byte SCK_PIN = 13;
const byte GDO0_PIN = A0;

void setup() {
  Serial.begin(9600);
  pinMode(SS_PIN, OUTPUT);
  pinMode(PAC_PIN, OUTPUT);
  pinMode(GDO0_PIN, INPUT);
  pinMode(GDO2_PIN, INPUT);

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
  
  make_compatible(rfSettings, rfSettings_netusb);
   
  // use GDO2 instead of GD00
  rfSettings.rfSettings.iocfg2 =  rfSettings.rfSettings.iocfg0;
  
  powerUpReset();

  //write registers
  for(byte i=0; i<ADDR_RCCTRL0+1; i++) {
    writeRegister(i, rfSettings.registers[i]);
  }
  // skip a few registers we're not supposed to write to
  writeRegister(ADDR_PTEST, rfSettings.rfSettings.ptest);
  writeRegister(ADDR_TEST2, rfSettings.rfSettings.test2);
  writeRegister(ADDR_TEST1, rfSettings.rfSettings.test1);
  writeRegister(ADDR_TEST0, rfSettings.rfSettings.test0);
  
  // strobe configuration
  writeRegisterBurst(CCxxx0_PATABLE, PA_TABLE, 8);
  
  digitalWrite(PAC_PIN, LOW);
  digitalWrite(PAC_PIN, HIGH);
  // give the device time to set up:
  delay(100);
}

enum desired_function {
  INIT_TEMPERATURE,
  TEMPERATURE,
  INIT_CONTINUOUS_SEND,
  CONTINUOUS_SEND,
  INIT_CONTINUOUS_RECV,
  CONTINUOUS_RECV,
};

byte desired_function = INIT_CONTINUOUS_RECV;
const byte TX_BUF_LEN = 33;
const byte TX_BUF[TX_BUF_LEN]=
    { 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,
      0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28, 0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39
    };	 

void loop() {
  switch(desired_function) {
    case INIT_CONTINUOUS_SEND:
      strobe(CCxxx0_SFSTXON);
      desired_function = CONTINUOUS_SEND;
      break;
    case CONTINUOUS_SEND:
      writeRegister(CCxxx0_TXFIFO, TX_BUF_LEN);
      writeRegisterBurst(CCxxx0_TXFIFO, TX_BUF, TX_BUF_LEN);
      strobe(CCxxx0_STX);
      while(!digitalRead(GDO2_PIN)) {
        Serial.println("Waiting for sync word...");
        outputState();
        delay(1000);
      }
     while(digitalRead(GDO2_PIN)) {
        Serial.println("Waiting for packet end...");
        outputState();
        delay(1000);
      }     
      strobe(CCxxx0_SFTX);
      outputState();
      break;
    case INIT_CONTINUOUS_RECV:
      outputFifoStatus();
      outputSignalStatus();
      outputPacketStatus();
      strobe(CCxxx0_SFRX);
      strobe(CCxxx0_SRX);
      desired_function = CONTINUOUS_RECV;
      break;
    case CONTINUOUS_RECV:
      strobe(CCxxx0_SFRX);
      outputFifoStatus();
      outputSignalStatus();
      outputPacketStatus();
      outputState();
      break;  
    case INIT_TEMPERATURE:
      rfSettings.rfSettings.iocfg0 = 0;
      rfSettings.values.temp_sensor_enable = 1;
      writeRegister(ADDR_IOCFG0, rfSettings.rfSettings.iocfg0);    
      desired_function = TEMPERATURE;
      break;
    case TEMPERATURE:
      if(outputState() == 1) {
        // necessary in the idle state to get temperature output
        writeRegister(ADDR_PTEST, 0xBF); 
      }
      byte temperature = outputTemperature();
      if(outputState() == 1) {
        // we're leaving the idle state
        writeRegister(ADDR_PTEST, 0x7F); 
      }
      sendPacket(&temperature, 1);
      outputState();
      break;  
  }
  delay(1000);
}

typedef union {
  byte value;
struct {
  unsigned GDO0:1;
  unsigned unused:1;
  unsigned GDO2:1;
  unsigned SFD:1;
  unsigned CCA:1;
  unsigned PQT_REACHED:1;
  unsigned CS:1;
  unsigned LAST_CRC_OK:1;
};
} pktstatus_t;

void outputSignalStatus() {
  byte rssi = readRegister(CCxxx0_RSSI);
  Serial.print("RSSI:");
  Serial.println(rssi, DEC);
}

void outputPacketStatus() {
  pktstatus_t pktstatus;
  pktstatus.value = readRegister(CCxxx0_PKTSTATUS);
  Serial.print("GDO0:");
  Serial.print(pktstatus.GDO0);
  Serial.print(" GDO2:");
  Serial.print(pktstatus.GDO2);
  Serial.print(" SFD:");
  Serial.print(pktstatus.SFD);
  Serial.print(" CCA:");
  Serial.print(pktstatus.CCA);
  Serial.print(" PQT_REACHED:");
  Serial.print(pktstatus.PQT_REACHED);
  Serial.print(" CS:");
  Serial.print(pktstatus.CS);
  Serial.print(" CRC_OK:");
  Serial.println(pktstatus.LAST_CRC_OK);
}

typedef union {
  byte value;
  struct {
    unsigned bytes_num:7;
    unsigned overflow:1;
  };
} rxtxbytes_t;

void outputFifoStatus() {
  rxtxbytes_t xbytes;
  
  xbytes.value = readRegister(CCxxx0_RXBYTES);
  Serial.print("rxbytes = ");
  if(xbytes.overflow) {
    Serial.print("overflow ");
  }
  Serial.println(xbytes.bytes_num, DEC);
  
  xbytes.value = readRegister(CCxxx0_TXBYTES);
  if(xbytes.overflow) {
    Serial.print("overflow ");
  }
  Serial.print("txbytes = ");
  Serial.println(xbytes.bytes_num, DEC);   
}

// Write values to on-chip transfer buffer
void sendPacket(const byte* buffer, byte len) {
  writeRegister(CCxxx0_TXFIFO, len);
  writeRegisterBurst(CCxxx0_TXFIFO, buffer, len);
  strobe(CCxxx0_STX); // go to transfer mode
  while(outputState() != 20) {
    delay(1000);
  }
}

// see state diagram from SWRS061F pg 48
byte outputState() {
  int state = readState();
  Serial.print("state: ");
  // state names from SWRS061F page 91
  switch(state & 0xF) {
    case 0:
      Serial.println("SLEEP (ERROR)");
      break;
    case 1:
      Serial.println("IDLE");
      break;
    case 2:
      Serial.println("XOFF (ERROR)");
      break;
    case 3:
      Serial.println("VCOON_MC");
      break;
    case 4:
      Serial.println("REGON_MC");
      break;
    case 5:
      Serial.println("MANCAL");
      break;
    case 6:
      Serial.println("VCOON");
      break;
    case 7:
      Serial.println("REGON");
      break;
    case 8:
      Serial.println("STARTCAL");
      break;
    case 9:
      Serial.println("BWBOOST");
      break;
    case 10:
      Serial.println("FS_LOCK");
      break;
    case 11:
      Serial.println("IFADCON");
      break;
    case 12:
      Serial.println("ENDCAL");
      break;
    case 13:
      Serial.println("RX");
      break;
    case 14:
      Serial.println("RX_END");
      break;
    case 15:
      Serial.println("RX_RST");
      break;
    case 16:
      Serial.println("TXRX_SWITCH");
      break;
    case 17:
      Serial.println("RXFIFO_OVERFLOW");
      break;
    case 18:
      Serial.println("FSTXON");
      break;
    case 19:
      Serial.println("TX");
      break;
    case 20:
      Serial.println("TX_END");
      break;
    case 21:
      Serial.println("RXTX_SWITCH");
      break;
    case 22:
      Serial.println("TXFIFO_UNDERFLOW");
      break;
    default:
      Serial.println("UNKNOWN (ERROR)");
      break;
  }
  return state;
}

byte outputTemperature() {
  int value = analogRead(GDO0_PIN);
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
  byte result = 0;
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
