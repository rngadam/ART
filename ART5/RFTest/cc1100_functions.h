#ifndef cc1100_functions_h
#define cc1100_functions_h

#include "cc1100_rf_settings.h"

char* state_names[] = {
  "SLEEP (ERROR)", 
  "IDLE",
  "XOFF (ERROR)",
  "VCOON_MC",
  "REGON_MC",
  "MANCAL",
  "VCOON",
  "REGON",
  "STARTCAL",
  "BWBOOST",
  "FS_LOCK",
  "IFADCON",
  "ENDCAL",
  "RX",
  "RX_END",
  "RX_RST",
  "TXRX_SWITCH",
  "RXFIFO_OVERFLOW",
  "FSTXON",
  "TX",
  "TX_END",
  "RXTX_SWITCH",
  "TXFIFO_UNDERFLOW"
};

enum states {
  SLEEP, 
  IDLE,
  XOFF,
  VCOON_MC,
  REGON_MC,
  MANCAL,
  VCOON,
  REGON,
  STARTCAL,
  BWBOOST,
  FS_LOCK,
  IFADCON,
  ENDCAL,
  RX,
  RX_END,
  RX_RST,
  TXRX_SWITCH,
  RXFIFO_OVERFLOW,
  FSTXON,
  TX,
  TX_END,
  RXTX_SWITCH,
  TXFIFO_UNDERFLOW  
};

const char* getStateName(const byte state) {
  // state names from SWRS061F page 91
  if(state & 0xF >= 22) {
    return "ERROR";
  }
  return state_names[state & 0xF];
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

// Strobe registers are accessed by register address OR register address | READ_SINGLE
// see page 68
byte strobe(byte thisRegister) {
  digitalWrite(SS_PIN, LOW);
  byte state = SPI.transfer(thisRegister); //Send register location
  digitalWrite(SS_PIN, HIGH);
  return state;
}

// Status register are accessed by register address | READ_BURST
// Multibytes are read by consecutive transfers
// see page 68
byte readRegister(byte thisRegister) {
  byte result = 0;
  digitalWrite(SS_PIN, LOW);
  SPI.transfer(thisRegister|READ_SINGLE); //Send register location + single read
  result = SPI.transfer(0x00);
  digitalWrite(SS_PIN, HIGH);  
  return result;
}

// Status register are accessed by register address | READ_BURST
// see page 68
byte readRegisterStatus(byte thisRegister) {
  byte result = 0;
  digitalWrite(SS_PIN, LOW);
  
  SPI.transfer(thisRegister|READ_BURST); //Send register location + single read

  result = SPI.transfer(0x00);
  digitalWrite(SS_PIN, HIGH);  
  return result;
}

// Status register are accessed by register address | READ_BURST
// Multibytes are read by consecutive transfers
// see page 68
void readRegisterBurst(byte thisRegister, byte* buffer, byte len) {
  byte result = 0;
  digitalWrite(SS_PIN, LOW);
  SPI.transfer(thisRegister|READ_BURST); //Send register location + single read with burst bit
  for(int i=0; i<len; i++) {
    buffer[i] = SPI.transfer(0x00);
  }
  digitalWrite(SS_PIN, HIGH);  
}

byte readState() {
  byte result;
  digitalWrite(SS_PIN, LOW);
  SPI.transfer(CCxxx0_MARCSTATE|READ_BURST); //Send register location + single read
  result = SPI.transfer(0x00);
  digitalWrite(SS_PIN, HIGH);  
  return result;
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

void reset() {
  // RESET  
  strobe(CCxxx0_SRES);
}

void idle() {
  // go to idle
  strobe(CCxxx0_SIDLE);
  do {
    delay(100);
  } while(readState() != IDLE);
}

void rx() {
  // go to idle
  strobe(CCxxx0_SRX);
  do {
    delay(100);
  } while(readState() != RX);
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

void writeConfig(const settings_t& settings, const byte* pa_table) {
  idle();
  //write registers
  for(byte i=0; i<ADDR_RCCTRL0+1; i++) {
    writeRegister(i, settings.registers[i]);
  }
  // skip a few registers we're not supposed to write to
  writeRegister(ADDR_PTEST, settings.rfSettings.ptest);
  writeRegister(ADDR_TEST2, settings.rfSettings.test2);
  writeRegister(ADDR_TEST1, settings.rfSettings.test1);
  writeRegister(ADDR_TEST0, settings.rfSettings.test0);
  
  // strobe configuration
  writeRegisterBurst(CCxxx0_PATABLE, pa_table, 8);

  digitalWrite(PAC_PIN, LOW);
  digitalWrite(PAC_PIN, HIGH);
}
#endif
