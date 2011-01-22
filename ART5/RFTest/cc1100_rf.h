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
    // Some of the registers below should not be written...
    BYTE fstest;           // 59 -> 0029 Frequency Synthesizer Calibration Control 
    BYTE ptest;            // 7f -> 002a Production Test 
    BYTE agctest;          // 3f -> 002b AGC Test 
    BYTE test2;            // 81 -> 002c Various Test Settings 
    BYTE test1;            // 35 -> 002d Various Test Settings 
    BYTE test0;            // 09 -> 002e Various Test Settings 
    // further registers (from partnum) are readable only
    //BYTE partnum;          // 00 -> 0030 Chip ID 
    //BYTE version;          // 04 -> 0031 Chip ID 
    //BYTE freqest;          // 00 -> 0032 Frequency Offset Estimate from Demodulator 
    //BYTE lqi;              // 00 -> 0033 Demodulator Estimate for Link Quality 
    //BYTE rssi;             // 00 -> 0034 Received Signal Strength Indication 
    //BYTE marcstate;        // 00 -> 0035 Main Radio Control State Machine State 
    //BYTE wortime1;         // 00 -> 0036 High Byte of WOR Time 
    //BYTE wortime0;         // 00 -> 0037 Low Byte of WOR Time 
    //BYTE pktstatus;        // 00 -> 0038 Current GDOx Status and Packet Status 
    //BYTE vco_vc_dac;       // 00 -> 0039 Current Setting from PLL Calibration Module 
    //BYTE txbytes;          // 00 -> 003a Underflow and Number of Bytes 
    //BYTE rxbytes;          // 00 -> 003b Overflow and Number of Bytes 
    //BYTE rcctrl1_status;   // 00 -> 003c Last RC Oscillator Calibration Result 
    //BYTE rcctrl0_status;   // 00 -> 003d Last RC Oscillator Calibration Result 
} RF_SETTINGS;

const byte CHP_RDY = 0x29;
const byte THREE_STATES = 0x2e;

// Most significant fields at the bottom!
typedef struct {
    //BYTE iocfg2;           // 29 -> 0000 GDO2 Output Pin Configuration 
    unsigned gdo2_cfg:6;
    unsigned gdo2_inv:1;
    unsigned iocfg2_unused:1;
    //BYTE iocfg1;           // 2e -> 0001 GDO1 Output Pin Configuration 
    unsigned gdo1_cfg:6;
    unsigned gdo1_inv:1;
    unsigned gdo_ds:1;
    //BYTE iocfg0;           // 06 -> 0002 GDO0 Output Pin Configuration 
    unsigned gdo0_cfg:6;
    unsigned gdo0_inv:1;
    unsigned temp_sensor_enable:1;
    //BYTE fifothr;          // 07 -> 0003 RX FIFO and TX FIFO Thresholds    
    unsigned fifo_thr:3;
    unsigned close_in_rx:2;
    unsigned adc_retention:1;
    unsigned fifothr_reserved:1;
    //BYTE sync1;            // d3 -> 0004 Sync Word, High Byte 
    unsigned sync_word_high:8;
    //BYTE sync0;            // 91 -> 0005 Sync Word, Low Byte 
    unsigned sync_word_low:8;
    //BYTE pktlen;           // ff -> 0006 Packet Length 
    unsigned packet_length:8;
    //BYTE pktctrl1;         // 04 -> 0007 Packet Automation Control 
    unsigned adr_chk:2;
    unsigned append_status:1;
    unsigned crc_autoflush:1;
    unsigned pktctrl1_unused:1;
    unsigned pqt:3;
    //BYTE pktctrl0;         // 05 -> 0008 Packet Automation Control 
    unsigned length_config:2;
    unsigned crc_en:1;
    unsigned pktctrl0_unused_3:1;
    unsigned pkt_format:2;
    unsigned white_data:1;
    unsigned pktctrl0_unused_0:1;
    //BYTE addr;             // 00 -> 0009 Device Address 
    unsigned device_addr:8;
    //BYTE channr;           // 00 -> 000a Channel Number 
    unsigned chan:8;
    //BYTE fsctrl1;          // 06 -> 000b Frequency Synthesizer Control 
    unsigned freq_if:5;
    unsigned fsctrl1_reserved:1;
    unsigned fsctrl1_unused:2;
    //BYTE fsctrl0;          // 00 -> 000c Frequency Synthesizer Control 
    unsigned freqoff:8;
    //BYTE freq2;            // 10 -> 000d Frequency Control Word, High Byte 
    unsigned freq_high:6;
    unsigned freq_high_zero:2;
    //BYTE freq1;            // b1 -> 000e Frequency Control Word, Middle Byte 
    unsigned freq_middle:8;
    //BYTE freq0;            // 3b -> 000f Frequency Control Word, Low Byte 
    unsigned freq_low:8;
    //BYTE mdmcfg4;          // f6 -> 0010 Modem Configuration 
    unsigned drate_e:4;
    unsigned chanbw_m:2;
    unsigned chanbw_e:2;
    //BYTE mdmcfg3;          // 83 -> 0011 Modem Configuration 
    unsigned drate_m:8;
    //BYTE mdmcfg2;          // 13 -> 0012 Modem Configuration 
    unsigned sync_mode:3;
    unsigned manchester_en:1;
    unsigned mod_format:3;
    unsigned dem_dcfilt_off:1;
    //BYTE mdmcfg1;          // 22 -> 0013 Modem Configuration 
    unsigned chanspc_e:2;
    unsigned mdmcfg1_unused:2;
    unsigned num_preamble:3;
    unsigned fec_en:1;
    //BYTE mdmcfg0;          // f8 -> 0014 Modem Configuration 
    unsigned chanspc_m:8;
    //BYTE deviatn;          // 15 -> 0015 Modem Deviation Setting 
    unsigned deviation_m:3;
    unsigned deviatn_unused_3:1;
    unsigned deviation_e:3;
    unsigned deviation_unused_7:1;
    //BYTE mcsm2;            // 07 -> 0016 Main Radio Control State Machine Configuration
    unsigned rx_time:3;
    unsigned rx_time_qual:1;
    unsigned rx_time_rssi:1;
    unsigned mcsm2_unused:1;
    //BYTE mcsm1;            // 30 -> 0017 Main Radio Control State Machine Configuration 
    unsigned txoff_mode:2;
    unsigned rxoff_mode:2;
    unsigned cca_mode:2;
    unsigned mcsm1_unused:1;
    //BYTE mcsm0;            // 18 -> 0018 Main Radio Control State Machine Configuration 
    unsigned xosc_force_on:1;
    unsigned pin_ctrl_en:1;
    unsigned po_timeout:2;
    unsigned fs_autocal:2;
    unsigned mcsm0_unused:2;
    //BYTE foccfg;           // 16 -> 0019 Frequency Offset Compensation Configuration
    unsigned foc_limit:2;
    unsigned foc_post_k:1;
    unsigned foc_pre_k:2;
    unsigned foc_bs_cs_gate:1;
    unsigned foccfg_unused:2;
    //BYTE bscfg;            // 6c -> 001a Bit Synchronization Configuration 
    unsigned bs_limit:2;
    unsigned bs_post_kp:1;
    unsigned bs_post_ki:1;
    unsigned bs_pre_kp:2;
    unsigned bs_pre_ki:2;
    //BYTE agcctrl2;         // 03 -> 001b AGC Control 
    unsigned magn_target:3;
    unsigned max_lna_gain:3;
    unsigned max_dvga_gain:2;
    //BYTE agcctrl1;         // 40 -> 001c AGC Control 
    unsigned carrier_sense_abs_thr:4;
    unsigned carrier_sense_rel_thr:2;
    unsigned agc_lna_priority:1;
    unsigned agcctrl1_unused:1;
    //BYTE agcctrl0;         // 91 -> 001d AGC Control 
    unsigned filter_length:2;
    unsigned agc_freeze:2;
    unsigned wait_time:2;
    unsigned hyst_level:2;
    //BYTE worevt1;          // 87 -> 001e High Byte Event0 Timeout 
    unsigned event0_high:8;
    //BYTE worevt0;          // 6b -> 001f Low Byte Event0 Timeout 
    unsigned event0_low:8;
    //BYTE worctrl;          // fb -> 0020 Wake On Radio Control 
    unsigned wor_res:2;
    unsigned worctrl_unused:2;
    unsigned rc_cal:1;
    unsigned event1:3;
    unsigned rc_pd:1;
    //BYTE frend1;           // 56 -> 0021 Front End RX Configuration 
    unsigned mix_current:2;
    unsigned lodiv_buf_current_rx:2;
    unsigned lna2mix_current:2;
    unsigned lna_current:2;
    //BYTE frend0;           // 10 -> 0022 Front End TX Configuration 
    unsigned pa_power:3;
    unsigned frend0_unused_3:1;
    unsigned lodiv_buf_current_tx:2;
    unsigned frend0_unused_67:2;
    //BYTE fscal3;           // e9 -> 0023 Frequency Synthesizer Calibration 
    unsigned fscal3:4;
    unsigned chp_curr_cal_en:2;
    unsigned fscal3_configuration:2;
    //BYTE fscal2;           // 2a -> 0024 Frequency Synthesizer Calibration 
    unsigned fscal2:5;
    unsigned vco_core_h_en:1;
    unsigned fscal2_unused:2;
    //BYTE fscal1;           // 00 -> 0025 Frequency Synthesizer Calibration 
    unsigned fscal1:6;
    //BYTE fscal0;           // 1f -> 0026 Frequency Synthesizer Calibration 
    unsigned fscal0:7;
    unsigned fscal0_unused:1;
    //BYTE rcctrl1;          // 41 -> 0027 RC Oscillator Configuration 
    unsigned rcctrl1:7;
    unsigned rcctrl1_unused:1;
    //BYTE rcctrl0;          // 00 -> 0028 RC Oscillator Configuration 
    unsigned rcctrl0:7;
    unsigned rcctrl0_unused:1;   
    //BYTE fstest;           // 59 -> 0029 Frequency Synthesizer Calibration Control 
    unsigned fstest_do_not_write:8;
    //BYTE ptest;            // 7f -> 002a Production Test 
    unsigned ptest:8;
    //BYTE agctest;          // 3f -> 002b AGC Test 
    unsigned agctest_do_not_write:8;
    //BYTE test2;            // 81 -> 002c Various Test Settings 
    unsigned test2:8;
    //BYTE test1;            // 35 -> 002d Various Test Settings 
    unsigned test1:8;
    //BYTE test0;            // 09 -> 002e Various Test 
    unsigned test0_1:1;
    unsigned vco_sel_cal_en:1;
    unsigned test0_2:6;
    // from partnum, these are all read-only registers
} RF_SETTINGS_VALUES;
#endif
