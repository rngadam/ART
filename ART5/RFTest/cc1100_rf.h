#ifndef cc1100_rf_h
#define cc1100_rf_h

#include "cc1100.h"

// CHIP 1101
typedef struct {
    BYTE iocfg2;           // 29 -> 0000 GDO2 Output Pin Configuration 
    BYTE iocfg1;           // 2e -> 0001 GDO1 Output Pin Configuration 
    BYTE iocfg0;           // 06 -> 0002 GDO0 Output Pin Configuration 
    BYTE fifothr;          // 07 -> 0003 RX FIFO and TX FIFO Thresholds 
    BYTE sync1;            // d3 -> 0004 Sync Word, High Byte 
    BYTE sync0;            // 91 -> 0005 Sync Word, Low Byte 
    BYTE pktlen;           // ff -> 0006 Packet Length 
    BYTE pktctrl1;         // 04 -> 0007 Packet Automation Control 
    BYTE pktctrl0;         // 05 -> 0008 Packet Automation Control 
    BYTE addr;             // 00 -> 0009 Device Address 
    BYTE channr;           // 00 -> 000a Channel Number 
    BYTE fsctrl1;          // 06 -> 000b Frequency Synthesizer Control 
    BYTE fsctrl0;          // 00 -> 000c Frequency Synthesizer Control 
    BYTE freq2;            // 10 -> 000d Frequency Control Word, High Byte 
    BYTE freq1;            // b1 -> 000e Frequency Control Word, Middle Byte 
    BYTE freq0;            // 3b -> 000f Frequency Control Word, Low Byte 
    BYTE mdmcfg4;          // f6 -> 0010 Modem Configuration 
    BYTE mdmcfg3;          // 83 -> 0011 Modem Configuration 
    BYTE mdmcfg2;          // 13 -> 0012 Modem Configuration 
    BYTE mdmcfg1;          // 22 -> 0013 Modem Configuration 
    BYTE mdmcfg0;          // f8 -> 0014 Modem Configuration 
    BYTE deviatn;          // 15 -> 0015 Modem Deviation Setting 
    BYTE mcsm2;            // 07 -> 0016 Main Radio Control State Machine Configuration 
    BYTE mcsm1;            // 30 -> 0017 Main Radio Control State Machine Configuration 
    BYTE mcsm0;            // 18 -> 0018 Main Radio Control State Machine Configuration 
    BYTE foccfg;           // 16 -> 0019 Frequency Offset Compensation Configuration 
    BYTE bscfg;            // 6c -> 001a Bit Synchronization Configuration 
    BYTE agcctrl2;         // 03 -> 001b AGC Control 
    BYTE agcctrl1;         // 40 -> 001c AGC Control 
    BYTE agcctrl0;         // 91 -> 001d AGC Control 
    BYTE worevt1;          // 87 -> 001e High Byte Event0 Timeout 
    BYTE worevt0;          // 6b -> 001f Low Byte Event0 Timeout 
    BYTE worctrl;          // fb -> 0020 Wake On Radio Control 
    BYTE frend1;           // 56 -> 0021 Front End RX Configuration 
    BYTE frend0;           // 10 -> 0022 Front End TX Configuration 
    BYTE fscal3;           // e9 -> 0023 Frequency Synthesizer Calibration 
    BYTE fscal2;           // 2a -> 0024 Frequency Synthesizer Calibration 
    BYTE fscal1;           // 00 -> 0025 Frequency Synthesizer Calibration 
    BYTE fscal0;           // 1f -> 0026 Frequency Synthesizer Calibration 
    BYTE rcctrl1;          // 41 -> 0027 RC Oscillator Configuration 
    BYTE rcctrl0;          // 00 -> 0028 RC Oscillator Configuration 
    BYTE fstest;           // 59 -> 0029 Frequency Synthesizer Calibration Control 
    BYTE ptest;            // 7f -> 002a Production Test 
    BYTE agctest;          // 3f -> 002b AGC Test 
    BYTE test2;            // 81 -> 002c Various Test Settings 
    BYTE test1;            // 35 -> 002d Various Test Settings 
    BYTE test0;            // 09 -> 002e Various Test Settings 
    BYTE partnum;          // 00 -> 0030 Chip ID 
    BYTE version;          // 04 -> 0031 Chip ID 
    BYTE freqest;          // 00 -> 0032 Frequency Offset Estimate from Demodulator 
    BYTE lqi;              // 00 -> 0033 Demodulator Estimate for Link Quality 
    BYTE rssi;             // 00 -> 0034 Received Signal Strength Indication 
    BYTE marcstate;        // 00 -> 0035 Main Radio Control State Machine State 
    BYTE wortime1;         // 00 -> 0036 High Byte of WOR Time 
    BYTE wortime0;         // 00 -> 0037 Low Byte of WOR Time 
    BYTE pktstatus;        // 00 -> 0038 Current GDOx Status and Packet Status 
    BYTE vco_vc_dac;       // 00 -> 0039 Current Setting from PLL Calibration Module 
    BYTE txbytes;          // 00 -> 003a Underflow and Number of Bytes 
    BYTE rxbytes;          // 00 -> 003b Overflow and Number of Bytes 
    BYTE rcctrl1_status;   // 00 -> 003c Last RC Oscillator Calibration Result 
    BYTE rcctrl0_status;   // 00 -> 003d Last RC Oscillator Calibration Result 
} RF_SETTINGS;

#endif
