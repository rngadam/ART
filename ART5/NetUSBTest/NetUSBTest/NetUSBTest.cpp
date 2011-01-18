// NetUSBTest.cpp : Defines the entry point for the console application.
//
#define WIN32_LEAN_AND_MEAN   
#include "stdafx.h"
#include <windows.h>
#include <tchar.h>
#include <iostream>
#include <signal.h>

#include "netusb.h"

void EnableLed() {
	unsigned char buf[32];
	memset(buf,0,32);
	buf[0]=0xaa;
	buf[30]=1;
	buf[31]=0;

	DWORD r = NetusbSendData(buf, 32);
	if(r) {
		printf("LED enabled...");
	}
}

void EnableLed2() {
	unsigned char buf[32];
	memset(buf,0,32);
    buf[0]=0xcc; //Ä¿±êµØÖ·cc
	buf[30]=0;
	buf[31]=1;

	DWORD r = NetusbSendData(buf, 32);
}

static void  __stdcall callback(unsigned char* buff, size_t n) {
	printf("Got a callback!");
}

BOOL WINAPI ConsoleHandler(
    DWORD dwCtrlType   //  control signal type
);

bool running = true;

int main(int argc, _TCHAR* argv[])
{

    if (SetConsoleCtrlHandler( (PHANDLER_ROUTINE)ConsoleHandler,TRUE)==FALSE)
    {
        // unable to install handler... 
        // display message to the user
        printf("Unable to install handler!\n");
        return -1;
    }

	DWORD results = NetusbGetNumDevices(VID_NETUSB, PID_NETUSB1100);
	if(results == 1) {
		printf("yeah!");
		// Open connection to device
		results = NetusbOpen(0,VID_NETUSB, PID_NETUSB1100);
		// If device connection not established, output failure
		if (results != HID_DEVICE_SUCCESS)
		{
			printf("Error in connecting to device.\n");
		}
		else
		{
			printf("Successfully opened device!\n");
			EnableLed2();
			//NetusbRegisterNotification(HWND handle);
			NetusbSetCallback(callback);
			NetusbStartListen();
				
		}
	} else {
		printf("no!");
	}
	BYTE buf[1];
	BYTE result;
	int i = 0;
	while(running) {
		i++;
		if(i>255) {
			i = 0;
		}
		buf[0] = i;
		printf("Sending %d\n", i);
		result = NetusbSendData(buf, 1);
		if(result != 0) {
			printf("Error %d", result);
		}
		Sleep(100);
	}
	//NetusbUnregisterNotification();
	NetusbStopListen();
	NetusbClose();
	printf("Exit completed!");
	Sleep(1000);
	return 0;
}

BOOL WINAPI ConsoleHandler(DWORD CEvent)
{
    char mesg[128];

    switch(CEvent)
    {
    case CTRL_C_EVENT:
        printf("CTRL+C received!");
        break;
    case CTRL_BREAK_EVENT:
        printf("CTRL+BREAK received!");
        break;
    case CTRL_CLOSE_EVENT:
        printf("Program being closed!");
        break;
    case CTRL_LOGOFF_EVENT:
        printf("User is logging off!");
        break;
    case CTRL_SHUTDOWN_EVENT:
        printf("User is logging off!");
        break;

    }
	running = false;
    return TRUE;
}