/***************************************************************************
 **    @file netusb.h
 **
 **    netusb.h,v 1.0 2009/04/14 19:07:02 
 **
 **    This file defines the Special Function for Netusb905/1100
 **
 **    (c) Copyright@NEWMSG 2009
 **
 **    @author misswhile  <hziee_liu@hotmail.com>
 **
 **    Note:  Basic Windows Type Definitions reference  to windef.h  
 ***************************************************************************/
#ifndef __NET_USB_H__
#define __NET_USB_H__


#define VID_NETUSB     0x10C4 
#define PID_NETUSB903  0x8768
#define PID_NETUSB905  0x8568
#define PID_NETUSB1100 0x8668
#define PID_NETUSB2401 0x8968


#define HID_DEVICE_SUCCESS				0x00
#define HID_DEVICE_NOT_FOUND			0x01
#define HID_DEVICE_NOT_OPENED			0x02
#define HID_DEVICE_ALREADY_OPENED		0x03
#define	HID_DEVICE_TRANSFER_TIMEOUT		0x04
#define HID_DEVICE_TRANSFER_FAILED		0x05
#define HID_DEVICE_CANNOT_GET_HID_INFO	0x06
#define HID_DEVICE_HANDLE_ERROR			0x07
#define HID_DEVICE_INVALID_BUFFER_SIZE	0x08
#define HID_DEVICE_SYSTEM_CODE			0x09
#define HID_DEVICE_UNKNOWN_ERROR		0xFF


#ifdef  NETUSB_EXPORTS
#define NETBASES_API	__declspec(dllexport)
#else
#define NETBASES_API	__declspec(dllimport)
#endif //

#define DLL_CALLCONV  __stdcall

#ifdef __cplusplus
extern "C" {
#endif //


typedef  void (DLL_CALLCONV * NETUSB_PFUNC) (unsigned char* buff, size_t n);


NETBASES_API  
DWORD  DLL_CALLCONV NetusbGetNumDevices(WORD vid, WORD pid);

NETBASES_API 
BYTE   DLL_CALLCONV NetusbOpen(DWORD deviceIndex, WORD vid, WORD pid);
NETBASES_API 
BYTE   DLL_CALLCONV NetusbClose();

NETBASES_API
BYTE DLL_CALLCONV NetusbSendData(BYTE* buffer, DWORD bufferSize);

NETBASES_API
BYTE DLL_CALLCONV NetusbGetData(BYTE* buffer,BYTE* bytesReturned);

NETBASES_API
void DLL_CALLCONV NetusbSetCallback(NETUSB_PFUNC pFunc);

NETBASES_API
int DLL_CALLCONV NetusbStopListen();

NETBASES_API
int DLL_CALLCONV NetusbStartListen();

NETBASES_API 
BYTE DLL_CALLCONV NetusbRegisterNotification(HWND handle);
NETBASES_API
void DLL_CALLCONV NetusbUnregisterNotification();

//905专用
NETBASES_API
BYTE DLL_CALLCONV NetusbSetTxaddr(BYTE addr0,BYTE addr1,BYTE addr2,BYTE addr3);
NETBASES_API
BYTE DLL_CALLCONV NetusbSetRxaddr(BYTE addr0,BYTE addr1,BYTE addr2,BYTE addr3);

NETBASES_API  // fre 为9个bit位，具体看datasheet(freq=422.4+fre/10  MHz)
BYTE DLL_CALLCONV NetusbSetFrequence(unsigned short fre);
	
#ifdef __cplusplus
}
#endif //

#endif //__NET_USB_H__


