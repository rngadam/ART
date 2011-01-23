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

#include "cc1100_functions.h"

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
}

enum desired_function {
  INIT_TEMPERATURE,
  TEMPERATURE,
  INIT_CONTINUOUS_SEND,
  CONTINUOUS_SEND,
  INIT_CONTINUOUS_RECV,
  CONTINUOUS_RECV,
  INIT_SNIFFER,
  SNIFFER, 
  WAITING_SYNC_WORD,
  WAITING_PACKET_END,
};

byte desired_function = INIT_SNIFFER;
byte substate = 0;
byte current_chan = 0;

const byte TX_BUF_LEN = 33;
const byte TX_BUF[TX_BUF_LEN]=
    { 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,
      0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28, 0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39
    };	 
    
byte rx_buff[64];

void outputSignalStatus() {
  byte rssi = readRegisterStatus(CCxxx0_RSSI);
  Serial.print("RSSI:");
  Serial.println(rssi, DEC);
}

void outputPacketStatus() {
  pktstatus_t pktstatus;
  pktstatus.value = readRegisterStatus(CCxxx0_PKTSTATUS);
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

byte outputFifoStatus() {
  rxtxbytes_t xbytes;
  
  xbytes.value = readRegisterStatus(CCxxx0_TXBYTES);
  Serial.print("txbytes:");
  Serial.print(xbytes.bytes_num, DEC);   
  if(xbytes.overflow) {
    Serial.print("(overflow)");
  }

  xbytes.value = readRegisterStatus(CCxxx0_RXBYTES);
  Serial.print(" rxbytes: ");
  Serial.print(xbytes.bytes_num, DEC);
  if(xbytes.overflow) {
    Serial.print("(overflow)");
  }
  Serial.println("");
  return xbytes.bytes_num;
}


// see state diagram from SWRS061F pg 48
byte outputState() {
  byte state = readState();
  Serial.print("state:");
  Serial.print(state, DEC);
  Serial.print(":");
  Serial.println(getStateName(state));
  return state;
}

byte outputTemperature() {
  int value = analogRead(GDO0_PIN);
  int millivolts = map(value, 0, 1023, 0, 5000); // analog read is 10-bit value for range 0-5V
  int temperature = map(millivolts, 747, 847, 0, 40); // SWRS061F pg 18
  Serial.print("mV:");
  Serial.println(millivolts);
  Serial.print("temp: ");
  Serial.println(temperature);
  return temperature;
}

// pass a copy of settings, modify it and use that
void init_sniffer(settings_t& settings) {
  // disable address filtering
  settings.values.adr_chk = 0;
  // disable CRC filtering
  settings.values.crc_autoflush = 0;
  // disable forward error correction
  settings.values.fec_en = 0;
  // disable preamble/sync
  settings.values.sync_mode = 0;
  // disable appending status
  settings.values.append_status = 0;
  // disable CRC calculation
  settings.values.crc_en = 0;
  // infinite packet length mode
  settings.values.length_config = 2;
  // broadcast
  settings.values.device_addr = 0;
  // stay in rx
  settings.values.rxoff_mode = 3; 
  
  writeConfig(settings, PA_TABLE);
}

int last_millis = 0;
boolean update = true;

void loop() {
  switch(desired_function) {
    case INIT_SNIFFER:
      init_sniffer(rfSettings);
      strobe(CCxxx0_SFTX);
      strobe(CCxxx0_SRX);
      desired_function = SNIFFER;
      current_chan = 0;
      update = false;
      break;
    case SNIFFER:
    {
      if(readRegisterStatus(CCxxx0_RXBYTES)) {
        update = true;
        outputFifoStatus();
        Serial.print("CHANNEL ");
        Serial.println(current_chan, DEC);
        byte packet_len = readRegister(CCxxx0_RXFIFO);
        if(packet_len>0) {
          readRegisterBurst(CCxxx0_RXFIFO, rx_buff, packet_len);  
          Serial.print("data ");
          Serial.print(packet_len, DEC);
          for(byte i=0; i<packet_len; i++) {
            Serial.print(" ");
            Serial.print(rx_buff[i], DEC);
          }
          Serial.println("");
        }
      } else {
        current_chan++;
        idle();
        writeRegister(ADDR_CHANNR, current_chan);
        rx();
      }
      break;     
    }
      
    case INIT_CONTINUOUS_SEND:
      writeConfig(rfSettings, PA_TABLE);
      strobe(CCxxx0_SFSTXON);
      desired_function = CONTINUOUS_SEND;
      break;
      
    case CONTINUOUS_SEND:
      if(substate == WAITING_SYNC_WORD) {
        if(!digitalRead(GDO2_PIN)) {
          Serial.println("Waiting for sync word...");
        } else {
          substate = WAITING_PACKET_END;
        }
      } else if(substate == WAITING_PACKET_END) {
        if(digitalRead(GDO2_PIN)) {
          Serial.println("Waiting for packet end...");          
        } else {
          substate = 0;
          strobe(CCxxx0_SFTX);
        }
      } else {
        writeRegister(CCxxx0_TXFIFO, TX_BUF_LEN);
        writeRegisterBurst(CCxxx0_TXFIFO, TX_BUF, TX_BUF_LEN);
        strobe(CCxxx0_STX);
        substate = WAITING_SYNC_WORD;
      }
      break;
    case INIT_CONTINUOUS_RECV:
      writeConfig(rfSettings, PA_TABLE);
      strobe(CCxxx0_SFRX);
      strobe(CCxxx0_SRX);
      desired_function = CONTINUOUS_RECV;
      break;
    case CONTINUOUS_RECV:
      strobe(CCxxx0_SFRX);
      break;  
    case INIT_TEMPERATURE:
      writeConfig(rfSettings, PA_TABLE);
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
  // if we get a valid byte, switch state
  if (Serial.available() > 0) {
    byte inByte = Serial.read();
    switch(inByte) {
      case 't':
        Serial.println("Temperature mode");
        desired_function = INIT_TEMPERATURE;
        break;
      case 'r':
        Serial.println("recv mode");
        desired_function = INIT_CONTINUOUS_RECV;
        break;
      case 's':
        Serial.println("send mode");
        desired_function = INIT_CONTINUOUS_SEND;
        break;
      case 'f':
        Serial.println("sniffer mode");
        desired_function = INIT_SNIFFER;
        break;
      case 'o':
        update = true;
        break;
      default:
        Serial.println("t Temperature");
        Serial.println("r Receive");
        Serial.println("s Send");
        Serial.println("f Sniffer");
        break;
    }
  } else {
    if((last_millis - millis()) > 1000 && update) {
      update = false;
      last_millis = millis();
      outputSignalStatus();
      outputPacketStatus();
      outputState();
      Serial.print("CHANNEL ");
      Serial.println(current_chan, DEC);      
    }
  }
}



