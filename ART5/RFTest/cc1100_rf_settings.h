/*****************************************************************************
 * Instantiate settings
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
#ifndef cc1100_rf_settings_h
#define cc1100_rf_settings_h

#ifndef ARDUINO
typedef unsigned char byte;
#endif

#include "cc1100_rf.h"

// these are from the NetUSB cc1100.h
settings_t rfSettings_netusb = {
    0x29,  // IOCFG2              GDO2 Output Pin Configuration
    0x46,  // IOCFG1              GDO1 Output Pin Configuration
    0x47,  // IOCFG0              GDO0 Output Pin Configuration
    0x07,  // FIFOTHR             RX FIFO and TX FIFO Thresholds
    0xD3,  // SYNC1               Sync Word, High Byte
    0x91,  // SYNC0               Sync Word, Low Byte
    0x21,  // PKTLEN              Packet Length
    0x0e,  // PKTCTRL1            Packet Automation Control
    0x44,  // PKTCTRL0            Packet Automation Control
    0xcc,  // ADDR                Device Address
    0x61,  // CHANNR              Channel Number
    0x08,  // FSCTRL1             Frequency Synthesizer Control
    0x00,  // FSCTRL0             Frequency Synthesizer Control
    0x0f,  // FREQ2               Frequency Control Word, High Byte
    0xc4,  // FREQ1               Frequency Control Word, Middle Byte
    0xec,  // FREQ0               Frequency Control Word, Low Byte
    0x2d,  // MDMCFG4             Modem Configuration
    0x3b,  // MDMCFG3             Modem Configuration
    0x73,  // MDMCFG2             Modem Configuration
    0xa2,  // MDMCFG1             Modem Configuration
    0xf8,  // MDMCFG0             Modem Configuration
    0x00,  // DEVIATN             Modem Deviation Setting
    0x07,  // MCSM2               Main Radio Control State Machine Configuration
    0x3f,  // MCSM1               Main Radio Control State Machine Configuration
    0x18,  // MCSM0               Main Radio Control State Machine Configuration
    0x1d,  // FOCCFG              Frequency Offset Compensation Configuration
    0x1c,  // BSCFG               Bit Synchronization Configuration
    0xc7,  // AGCCTRL2            AGC Control
    0x00,  // AGCCTRL1            AGC Control
    0xb2,  // AGCCTRL0            AGC Control
    0x87,  // WOREVT1             High Byte Event0 Timeout
    0x6b,  // WOREVT0             Low Byte Event0 Timeout
    0x71,  // WORCTRL             Wake On Radio Control
    0xb6,  // FREND1              Front End RX Configuration
    0x10,  // FREND0              Front End TX Configuration
    0xea,  // FSCAL3              Frequency Synthesizer Calibration
    0x2a,  // FSCAL2              Frequency Synthesizer Calibration
    0x00,  // FSCAL1              Frequency Synthesizer Calibration
    0x1f,  // FSCAL0              Frequency Synthesizer Calibration
    0x41,  // RCCTRL1             RC Oscillator Configuration
    0x00,  // RCCTRL0             RC Oscillator Configuration
    0x59,  // FSTEST              Frequency Synthesizer Calibration Control
    0x7F,  // PTEST               Production Test
    0x3F,  // AGCTEST             AGC Test
    0x81,  // TEST2               Various Test Settings
    0x35,  // TEST1               Various Test Settings
    0x0b,  // TEST0               Various Test Settings
};

// these are from the RFC-1100A RFC1100A-fasong.c
settings_t rfSettings_rfc1100a = {
    0x0B,  // IOCFG2              GDO2 Output Pin Configuration
    0x46,  // IOCFG1              GDO1 Output Pin Configuration
    0x06,  // IOCFG0              GDO0 Output Pin Configuration
    0x07,  // FIFOTHR             RX FIFO and TX FIFO Thresholds // default
    0xD3,  // SYNC1               Sync Word, High Byte // default
    0x91,  // SYNC0               Sync Word, Low Byte // default
    0xff,  // PKTLEN              Packet Length
    0x04,  // PKTCTRL1            Packet Automation Control
    0x05,  // PKTCTRL0            Packet Automation Control
    0x00,  // ADDR                Device Address
    0x00,  // CHANNR              Channel Number
    0x08,  // FSCTRL1             Frequency Synthesizer Control
    0x00,  // FSCTRL0             Frequency Synthesizer Control
    0x10,  // FREQ2               Frequency Control Word, High Byte
    0xa7,  // FREQ1               Frequency Control Word, Middle Byte
    0x62,  // FREQ0               Frequency Control Word, Low Byte
    0x5b,  // MDMCFG4             Modem Configuration
    0xf8,  // MDMCFG3             Modem Configuration
    0x03,  // MDMCFG2             Modem Configuration
    0x22,  // MDMCFG1             Modem Configuration
    0xf8,  // MDMCFG0             Modem Configuration
    0x47,  // DEVIATN             Modem Deviation Setting
    0x07,  // MCSM2               Main Radio Control State Machine Configuration // default
    0x30,  // MCSM1               Main Radio Control State Machine Configuration // default
    0x18,  // MCSM0               Main Radio Control State Machine Configuration
    0x1d,  // FOCCFG              Frequency Offset Compensation Configuration
    0x1c,  // BSCFG               Bit Synchronization Configuration
    0xc7,  // AGCCTRL2            AGC Control
    0x00,  // AGCCTRL1            AGC Control
    0xb2,  // AGCCTRL0            AGC Control
    0x87,  // WOREVT1             High Byte Event0 Timeout // default
    0x6b,  // WOREVT0             Low Byte Event0 Timeout // default
    0xf8,  // WORCTRL             Wake On Radio Control // default
    0xb6,  // FREND1              Front End RX Configuration
    0x10,  // FREND0              Front End TX Configuration
    0xea,  // FSCAL3              Frequency Synthesizer Calibration
    0x2a,  // FSCAL2              Frequency Synthesizer Calibration
    0x00,  // FSCAL1              Frequency Synthesizer Calibration
    0x11,  // FSCAL0              Frequency Synthesizer Calibration
    0x41,  // RCCTRL1             RC Oscillator Configuration // default
    0x00,  // RCCTRL0             RC Oscillator Configuration // default
    0x59,  // FSTEST              Frequency Synthesizer Calibration Control
    0x7F,  // PTEST               Production Test // default
    0x3F,  // AGCTEST             AGC Test
    0x81,  // TEST2               Various Test Settings
    0x35,  // TEST1               Various Test Settings
    0x09,  // TEST0               Various Test Settings
};


const byte PA_TABLE[8] = {0xC0 ,0xC0 ,0xC0 ,0xC0 ,0xC0 ,0xC0 ,0xC0 ,0xC0};   //10dBm

settings_t& rfSettings = rfSettings_netusb;

void make_compatible(settings_t& rfSettingsA, const settings_t& rfSettingsB) {
   //Configure relevant registers of A to match B
  rfSettingsA.values.chan = rfSettingsB.values.chan;
  rfSettingsA.values.mod_format = rfSettingsB.values.mod_format;
  rfSettingsA.values.length_config = rfSettingsB.values.length_config;
  rfSettingsA.values.packet_length = rfSettingsB.values.packet_length;
  rfSettingsA.values.deviation_e = rfSettingsB.values.deviation_e ;
  rfSettingsA.values.deviation_m = rfSettingsB.values.deviation_m; 
  rfSettingsA.values.freq_high = rfSettingsB.values.freq_high ;
  rfSettingsA.values.freq_middle = rfSettingsB.values.freq_middle; 
  rfSettingsA.values.freq_low = rfSettingsB.values.freq_low; 
  rfSettingsA.values.device_addr = rfSettingsB.values.device_addr;   
  rfSettingsA.values.adr_chk = rfSettingsB.values.adr_chk;     
}
#endif
