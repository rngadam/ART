#ifndef cc1100_rf_h
#define cc1100_rf_h

#include "cc1100.h"

// CHIP 1101
typedef struct {
    byte iocfg2;           // 0000 GDO2 Output Pin Configuration 
    byte iocfg1;           // 0001 GDO1 Output Pin Configuration 
    byte iocfg0;           // 0002 GDO0 Output Pin Configuration 
    byte fifothr;          // 0003 RX FIFO and TX FIFO Thresholds 
    byte sync1;            // 0004 Sync Word, High Byte 
    byte sync0;            // 0005 Sync Word, Low Byte 
    byte pktlen;           // 0006 Packet Length 
    byte pktctrl1;         // 0007 Packet Automation Control 
    byte pktctrl0;         // 0008 Packet Automation Control 
    byte addr;             // 0009 Device Address 
    byte channr;           // 000a Channel Number 
    byte fsctrl1;          // 000b Frequency Synthesizer Control 
    byte fsctrl0;          // 000c Frequency Synthesizer Control 
    byte freq2;            // 000d Frequency Control Word, High Byte 
    byte freq1;            // 000e Frequency Control Word, Middle Byte 
    byte freq0;            // 000f Frequency Control Word, Low Byte 
    byte mdmcfg4;          // 0010 Modem Configuration 
    byte mdmcfg3;          // 0011 Modem Configuration 
    byte mdmcfg2;          // 0012 Modem Configuration 
    byte mdmcfg1;          // 0013 Modem Configuration 
    byte mdmcfg0;          // 0014 Modem Configuration 
    byte deviatn;          // 0015 Modem Deviation Setting 
    byte mcsm2;            // 0016 Main Radio Control State Machine Configuration 
    byte mcsm1;            // 0017 Main Radio Control State Machine Configuration 
    byte mcsm0;            // 0018 Main Radio Control State Machine Configuration 
    byte foccfg;           // 0019 Frequency Offset Compensation Configuration 
    byte bscfg;            // 001a Bit Synchronization Configuration 
    byte agcctrl2;         // 001b AGC Control 
    byte agcctrl1;         // 001c AGC Control 
    byte agcctrl0;         // 001d AGC Control 
    byte worevt1;          // 001e High Byte Event0 Timeout 
    byte worevt0;          // 001f Low Byte Event0 Timeout 
    byte worctrl;          // 0020 Wake On Radio Control 
    byte frend1;           // 0021 Front End RX Configuration 
    byte frend0;           // 0022 Front End TX Configuration 
    byte fscal3;           // 0023 Frequency Synthesizer Calibration 
    byte fscal2;           // 0024 Frequency Synthesizer Calibration 
    byte fscal1;           // 0025 Frequency Synthesizer Calibration 
    byte fscal0;           // 0026 Frequency Synthesizer Calibration 
    byte rcctrl1;          // 0027 RC Oscillator Configuration 
    byte rcctrl0;          // 0028 RC Oscillator Configuration 
    // Some of the registers below should not be written...
    byte fstest;           // 0029 Frequency Synthesizer Calibration Control 
    byte ptest;            // 002a Production Test 
    byte agctest;          // 002b AGC Test 
    byte test2;            // 002c Various Test Settings 
    byte test1;            // 002d Various Test Settings 
    byte test0;            // 002e Various Test Settings 
    // further registers (from partnum) are readable only
    //byte partnum;          // 0030 Chip ID 
    //byte version;          // 0031 Chip ID 
    //byte freqest;          // 0032 Frequency Offset Estimate from Demodulator 
    //byte lqi;              // 0033 Demodulator Estimate for Link Quality 
    //byte rssi;             // 0034 Received Signal Strength Indication 
    //byte marcstate;        // 0035 Main Radio Control State Machine State 
    //byte wortime1;         // 0036 High Byte of WOR Time 
    //byte wortime0;         // 0037 Low Byte of WOR Time 
    //byte pktstatus;        // 0038 Current GDOx Status and Packet Status 
    //byte vco_vc_dac;       // 0039 Current Setting from PLL Calibration Module 
    //byte txbytes;          // 003a Underflow and Number of Bytes 
    //byte rxbytes;          // 003b Overflow and Number of Bytes 
    //byte rcctrl1_status;   // 003c Last RC Oscillator Calibration Result 
    //byte rcctrl0_status;   // 003d Last RC Oscillator Calibration Result 
} RF_SETTINGS;

const byte CHP_RDY = 0x29;
const byte THREE_STATES = 0x2e;

// Most significant fields at the bottom!
typedef struct {
    //byte iocfg2;           // 0000 GDO2 Output Pin Configuration 
    unsigned gdo2_cfg:6;
    unsigned gdo2_inv:1;
    unsigned iocfg2_unused:1;
    //byte iocfg1;           // 0001 GDO1 Output Pin Configuration 
    unsigned gdo1_cfg:6;
    unsigned gdo1_inv:1;
    unsigned gdo_ds:1;
    //byte iocfg0;           // 0002 GDO0 Output Pin Configuration 
    unsigned gdo0_cfg:6;
    unsigned gdo0_inv:1;
    unsigned temp_sensor_enable:1;
    //byte fifothr;          // 0003 RX FIFO and TX FIFO Thresholds    
    unsigned fifo_thr:3;
    unsigned close_in_rx:2;
    unsigned adc_retention:1;
    unsigned fifothr_reserved:1;
    //byte sync1;            // 0004 Sync Word, High Byte 
    unsigned sync_word_high:8;
    //byte sync0;            // 0005 Sync Word, Low Byte 
    unsigned sync_word_low:8;
    //byte pktlen;           // 0006 Packet Length 
    unsigned packet_length:8;
    //byte pktctrl1;         // 0007 Packet Automation Control 
    unsigned adr_chk:2;
    unsigned append_status:1;
    unsigned crc_autoflush:1;
    unsigned pktctrl1_unused:1;
    unsigned pqt:3;
    //byte pktctrl0;         // 0008 Packet Automation Control 
    unsigned length_config:2;
    unsigned crc_en:1;
    unsigned pktctrl0_unused_3:1;
    unsigned pkt_format:2;
    unsigned white_data:1;
    unsigned pktctrl0_unused_0:1;
    //byte addr;             // 0009 Device Address 
    unsigned device_addr:8;
    //byte channr;           // 000a Channel Number 
    unsigned chan:8;
    //byte fsctrl1;          // 000b Frequency Synthesizer Control 
    unsigned freq_if:5;
    unsigned fsctrl1_reserved:1;
    unsigned fsctrl1_unused:2;
    //byte fsctrl0;          // 000c Frequency Synthesizer Control 
    unsigned freqoff:8;
    //byte freq2;            // 000d Frequency Control Word, High Byte 
    unsigned freq_high:6;
    unsigned freq_high_zero:2;
    //byte freq1;            // 000e Frequency Control Word, Middle Byte 
    unsigned freq_middle:8;
    //byte freq0;            // 000f Frequency Control Word, Low Byte 
    unsigned freq_low:8;
    //byte mdmcfg4;          // 0010 Modem Configuration 
    unsigned drate_e:4;
    unsigned chanbw_m:2;
    unsigned chanbw_e:2;
    //byte mdmcfg3;          // 0011 Modem Configuration 
    unsigned drate_m:8;
    //byte mdmcfg2;          // 0012 Modem Configuration 
    unsigned sync_mode:3;
    unsigned manchester_en:1;
    unsigned mod_format:3;
    unsigned dem_dcfilt_off:1;
    //byte mdmcfg1;          // 0013 Modem Configuration 
    unsigned chanspc_e:2;
    unsigned mdmcfg1_unused:2;
    unsigned num_preamble:3;
    unsigned fec_en:1;
    //byte mdmcfg0;          // 0014 Modem Configuration 
    unsigned chanspc_m:8;
    //byte deviatn;          // 0015 Modem Deviation Setting 
    unsigned deviation_m:3;
    unsigned deviatn_unused_3:1;
    unsigned deviation_e:3;
    unsigned deviation_unused_7:1;
    //byte mcsm2;            // 0016 Main Radio Control State Machine Configuration
    unsigned rx_time:3;
    unsigned rx_time_qual:1;
    unsigned rx_time_rssi:1;
    unsigned mcsm2_unused:1;
    //byte mcsm1;            // 0017 Main Radio Control State Machine Configuration 
    unsigned txoff_mode:2;
    unsigned rxoff_mode:2;
    unsigned cca_mode:2;
    unsigned mcsm1_unused:1;
    //byte mcsm0;            // 0018 Main Radio Control State Machine Configuration 
    unsigned xosc_force_on:1;
    unsigned pin_ctrl_en:1;
    unsigned po_timeout:2;
    unsigned fs_autocal:2;
    unsigned mcsm0_unused:2;
    //byte foccfg;           // 0019 Frequency Offset Compensation Configuration
    unsigned foc_limit:2;
    unsigned foc_post_k:1;
    unsigned foc_pre_k:2;
    unsigned foc_bs_cs_gate:1;
    unsigned foccfg_unused:2;
    //byte bscfg;            // 001a Bit Synchronization Configuration 
    unsigned bs_limit:2;
    unsigned bs_post_kp:1;
    unsigned bs_post_ki:1;
    unsigned bs_pre_kp:2;
    unsigned bs_pre_ki:2;
    //byte agcctrl2;         // 001b AGC Control 
    unsigned magn_target:3;
    unsigned max_lna_gain:3;
    unsigned max_dvga_gain:2;
    //byte agcctrl1;         // 001c AGC Control 
    unsigned carrier_sense_abs_thr:4;
    unsigned carrier_sense_rel_thr:2;
    unsigned agc_lna_priority:1;
    unsigned agcctrl1_unused:1;
    //byte agcctrl0;         // 001d AGC Control 
    unsigned filter_length:2;
    unsigned agc_freeze:2;
    unsigned wait_time:2;
    unsigned hyst_level:2;
    //byte worevt1;          // 001e High Byte Event0 Timeout 
    unsigned event0_high:8;
    //byte worevt0;          // 001f Low Byte Event0 Timeout 
    unsigned event0_low:8;
    //byte worctrl;          // 0020 Wake On Radio Control 
    unsigned wor_res:2;
    unsigned worctrl_unused:2;
    unsigned rc_cal:1;
    unsigned event1:3;
    unsigned rc_pd:1;
    //byte frend1;           // 0021 Front End RX Configuration 
    unsigned mix_current:2;
    unsigned lodiv_buf_current_rx:2;
    unsigned lna2mix_current:2;
    unsigned lna_current:2;
    //byte frend0;           // 0022 Front End TX Configuration 
    unsigned pa_power:3;
    unsigned frend0_unused_3:1;
    unsigned lodiv_buf_current_tx:2;
    unsigned frend0_unused_67:2;
    //byte fscal3;           // 0023 Frequency Synthesizer Calibration 
    unsigned fscal3:4;
    unsigned chp_curr_cal_en:2;
    unsigned fscal3_configuration:2;
    //byte fscal2;           // 0024 Frequency Synthesizer Calibration 
    unsigned fscal2:5;
    unsigned vco_core_h_en:1;
    unsigned fscal2_unused:2;
    //byte fscal1;           // 0025 Frequency Synthesizer Calibration 
    unsigned fscal1:6;
    //byte fscal0;           // 0026 Frequency Synthesizer Calibration 
    unsigned fscal0:7;
    unsigned fscal0_unused:1;
    //byte rcctrl1;          // 0027 RC Oscillator Configuration 
    unsigned rcctrl1:7;
    unsigned rcctrl1_unused:1;
    //byte rcctrl0;          // 0028 RC Oscillator Configuration 
    unsigned rcctrl0:7;
    unsigned rcctrl0_unused:1;   
    //byte fstest;           // 0029 Frequency Synthesizer Calibration Control 
    unsigned fstest_do_not_write:8;
    //byte ptest;            // 002a Production Test 
    unsigned ptest:8;
    //byte agctest;          // 002b AGC Test 
    unsigned agctest_do_not_write:8;
    //byte test2;            // 002c Various Test Settings 
    unsigned test2:8;
    //byte test1;            // 002d Various Test Settings 
    unsigned test1:8;
    //byte test0;            // 002e Various Test 
    unsigned test0_1:1;
    unsigned vco_sel_cal_en:1;
    unsigned test0_2:6;
    // from partnum, these are all read-only registers
} RF_SETTINGS_VALUES;
#endif
