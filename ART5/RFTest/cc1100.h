// Ripped out from the NetUSB 8051 uC source.

#ifndef cc1100_driver_h
#define cc1100_driver_h

//--------------------------------------------------------------
//<RF-Configuration-Register values (ordered by register number)
#define IOCFG2        0x29//0x07       
#define IOCFG1        0x46       
#define IOCFG0        0x47//0x29       
#define FIFOTHR       0x07       
#define SYNC1         0xd3       
#define SYNC0         0x91       
#define PKTLEN        0x21      
#define PKTCTRL1      0x0e//0x0d      
#define PKTCTRL0      0x44       
#define ADDR          0xcc            
#define CHANNR        0x61//0x00      
#define FSCTRL1       0x08       
#define FSCTRL0       0x00       
#define FREQ2         0x0f       
#define FREQ1         0xc4       
#define FREQ0         0xec   
#define MDMCFG4       0x2d//0x7b       
#define MDMCFG3       0x3b//0x83  
#define MDMCFG2       0x73       
#define MDMCFG1       0xa2       
#define MDMCFG0       0xf8       
#define DEVIATN       0x00       
#define MCSM2         0x07       
#define MCSM1         0x3f       
#define MCSM0         0x18       
#define FOCCFG        0x1d       
#define BSCFG         0x1c       
#define AGCCTRL2      0xc7    
#define AGCCTRL1      0x00     
#define AGCCTRL0      0xb2      
#define WOREVT1       0x87    
#define WOREVT0       0x6b   
#define WORCTRL       0x71      
#define FREND1        0xb6      
#define FREND0        0x10       
#define FSCAL3        0xea    
#define FSCAL2        0x2a      
#define FSCAL1        0x00       
#define FSCAL0        0x1f     

#define FSTEST        0x59    

#define TEST2         0x81      
#define TEST1         0x35       
#define TEST0         0x0b    

byte cc1100regcfg[39]={
IOCFG2,IOCFG1,IOCFG0,FIFOTHR,SYNC1,SYNC0,PKTLEN,PKTCTRL1,PKTCTRL0,ADDR,CHANNR,FSCTRL1,FSCTRL0,
FREQ2,FREQ1,FREQ0,MDMCFG4,MDMCFG3,MDMCFG2,MDMCFG1,MDMCFG0,DEVIATN,MCSM2,MCSM1,MCSM0,FOCCFG,BSCFG,
AGCCTRL2,AGCCTRL1,AGCCTRL0,WOREVT1,WOREVT0,WORCTRL,FREND1,FREND0,FSCAL3,FSCAL2,FSCAL1,FSCAL0};

//-----------------------------------------------------------
// Register addresses
#define ADDR_IOCFG2      0x00         
#define ADDR_IOCFG1      0x01         
#define ADDR_IOCFG0      0x02         
#define ADDR_FIFOTHR     0x03         
#define ADDR_SYNC1       0x04         
#define ADDR_SYNC0       0x05         
#define ADDR_PKTLEN      0x06         
#define ADDR_PKTCTRL1    0x07         
#define ADDR_PKTCTRL0    0x08         
#define ADDR_ADDR        0x09         
#define ADDR_CHANNR      0x0a         
#define ADDR_FSCTRL1     0x0b         
#define ADDR_FSCTRL0     0x0c         
#define ADDR_FREQ2       0x0d         
#define ADDR_FREQ1       0x0e         
#define ADDR_FREQ0       0x0f         
#define ADDR_MDMCFG4     0x10         
#define ADDR_MDMCFG3     0x11         
#define ADDR_MDMCFG2     0x12        
#define ADDR_MDMCFG1     0x13        
#define ADDR_MDMCFG0     0x14       
#define ADDR_DEVIATN     0x15       
#define ADDR_MCSM2       0x16        
#define ADDR_MCSM1       0x17         
#define ADDR_MCSM0       0x18        
#define ADDR_FOCCFG      0x19         
#define ADDR_BSCFG       0x1a        
#define ADDR_AGCCTRL2    0x1b        
#define ADDR_AGCCTRL1    0x1c         
#define ADDR_AGCCTRL0    0x1d        
#define ADDR_WOREVT1     0x1e        
#define ADDR_WOREVT0     0x1f         
#define ADDR_WORCTRL     0x20       
#define ADDR_FREND1      0x21       
#define ADDR_FREND0      0x22        
#define ADDR_FSCAL3      0x23        
#define ADDR_FSCAL2      0x24         
#define ADDR_FSCAL1      0x25         
#define ADDR_FSCAL0      0x26         

#define ADDR_FSTEST      0x29         

#define ADDR_TEST2       0x2c        
#define ADDR_TEST1       0x2d         
#define ADDR_TEST0       0x2e   
#endif  //cc1100_driver_h
