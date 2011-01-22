/*****************************************************************************
 * RF Test Settings sanity check
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
#ifndef ARDUINO
#include <stdio.h>
typedef unsigned char byte;

#include "cc1100_rf_settings.h"

void outputConfig(const settings_t& rfSettings) {
  if(rfSettings.rfSettingsValues.gdo2_cfg & CHP_RDY) {
    printf("GDO2 output CHP_RDY\n");
  }
  if(rfSettings.rfSettingsValues.gdo2_inv) {
    printf("GDO2 inverted output\n");  
  }
// Base frequency = 433.999969 
// Carrier frequency = 433.999969 
// Channel number = 0 
  printf("Channel number = ");
  printf("%d\n", rfSettings.rfSettingsValues.chan);
// Carrier frequency = 433.999969 
// Modulated = true 
// Modulation format = GFSK 
  printf("Modulation format = ");
  switch(rfSettings.rfSettingsValues.mod_format) {
    case 0:
      printf("2-FSK\n");
      break;
    case 1:
      printf("GFSK\n");
      break;
    case 3:
      printf("ASK/OOK\n");
      break;
    case 7:
      printf("MSK\n");
      break;
    default:
      printf("None\n");
      break;
      
  }
// Manchester enable = false 
  printf("Manchester enable = %s\n", rfSettings.rfSettingsValues.manchester_en?"true":"false");
// Sync word qualifier mode = 30/32 sync word bits detected 
  printf("Sync word qualifier mode = ");
  switch(rfSettings.rfSettingsValues.sync_mode) {
    case 0:
      printf("No preamble/sync\n");
      break;
    case 1:
      printf("15/16 sync word bits detected\n");
      break;
    case 2:
      printf("16/16 sync word bits detected\n");
      break;
    case 3:
      printf("30/32 sync word bits detected\n");
      break;
    case 4:
      printf("No preamble/sync, carrier-sence above threshold\n");
      break;
    case 5:
      printf("15/16 + carrier-sense above threshold\n");
      break;
    case 6:
      printf("16/16 + carrier-sense above threshold\n");
      break;
    case 7:
      printf("30/32 + carrier-sense above threshold\n");
      break;
    default:
      printf("Unsupported value!\n");
      break; 
  }
// Preamble count = 4 
  printf("Preamble count = ");
  switch(rfSettings.rfSettingsValues.num_preamble) {
    case 0:
      printf("2\n");
      break;
    case 1:
      printf("3\n");
      break;
    case 2:
      printf("4\n");
      break;
    case 3:
      printf("6\n");
      break;
    case 4:
      printf("8\n");
      break;
    case 5:
      printf("12\n");
      break;
    case 6:
      printf("16\n");
      break;
    case 7:
      printf("24\n");
      break;
    default:
      printf("Unsupported value!\n");
      break; 
  }
// Channel spacing = 199.951172 
// Carrier frequency = 433.999969 
// Data rate = 2.39897 
// RX filter BW = 58.035714 
// Data format = Normal mode 
  printf("Data format = ");
  switch(rfSettings.rfSettingsValues.pkt_format) {
    case 0:
      printf("Normal mode, use FIFOs for RX and TX\n");
      break;
    case 1:
      printf("Synchronous serial mode.\n");
      break;
    case 2:
      printf("Random TX mode\n");
      break;
    case 3:
      printf("Asynchronous mode\n");
      break;
    default:
      printf("Unsupported value!\n");
      break; 
  }

// Length config = Variable packet length mode. Packet length configured by the first byte after sync word 
  printf("Length config = ");
  switch(rfSettings.rfSettingsValues.length_config) {
    case 0:
      printf("Fixed packet length mode.  Length configured in PKTLEN register\n");
      break;
    case 1:
      printf("Variable packet length mode. Length configured by the first byte after sync word\n");
      break;
    case 2:
      printf("Infinite packet length mode\n");
      break;
    case 3:
      printf("Reserved!\n");
      break;
    default:
      printf("Unsupported value!\n");
      break; 
  }
// CRC enable = true 
  printf("CRC enable = %s\n", rfSettings.rfSettingsValues.crc_en?"true":"false");
// Packet length = 255 
  printf("Packet length = ");
  printf("%d\n", rfSettings.rfSettingsValues.packet_length);
// Device address = 0 
  printf("Device address = ");
  printf("%d\n", rfSettings.rfSettingsValues.device_addr);
// Address config = No address check 
  printf("Address config = ");
  switch(rfSettings.rfSettingsValues.adr_chk) {
    case 0:
      printf("No address check\n");
      break;
    case 1:
      printf("Address check, no broadcast\n");
      break;
    case 2:
      printf("Address check and 0 (0x00) broadcast\n");
      break;
    case 3:
      printf("Address check and 0 (0x00) and 255 (0xFF) broadcast\n");
      break;
    default:
      printf("Unsupported value!\n");
      break; 
  }
// CRC autoflush = false 
  printf("CRC autoflush = %s\n", rfSettings.rfSettingsValues.crc_autoflush?"true":"false");
// PA ramping = false 
// TX power = 0   
}

int main(void) {
   outputConfig(rfSettings); 
}
#endif
