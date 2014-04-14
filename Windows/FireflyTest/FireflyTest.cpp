// FireflyTest.cpp : Defines the entry point for the application.
//

#include "stdafx.h"
#include "FireflyTest.h"

#include "../FireflyDevice/FDFireflyIceChannelUSB.h"
#include "../FireflyDevice/FDFireflyIceCoder.h"
#include "../FireflyDevice/FDUsb.h"

#include <iostream>

using namespace fireflydesign;

class Device : public FDUSBHIDDevice {
public:
	Device(FDUsb *usb) {
		_usb = usb;
	}
	virtual ~Device() {
	}

	virtual void setDelegate(std::shared_ptr<FDUSBHIDDeviceDelegate> delegate) { _delegate = delegate; }
	virtual std::shared_ptr<FDUSBHIDDeviceDelegate> getDelegate() { return _delegate;  }

	virtual void open() {}
	virtual void close() {}

	virtual void setReport(std::vector<uint8_t> data) {
		data.resize(64);
		_usb->writeOutputReport(data);
	}

private:
	FDUsb *_usb;
	std::shared_ptr<FDUSBHIDDeviceDelegate> _delegate;
};

void test() {
	std::vector<std::wstring> paths = FDUsb::allDevicePaths();
	for (std::wstring path : paths) {
		std::cout << path.c_str() << "\n";
		DWORD result;
		FDUsb usb(path);
		usb.open();

		std::shared_ptr<Device> device = std::make_shared<Device>(&usb);
		std::shared_ptr<FDFireflyIceChannelUSB> channel = std::make_shared<FDFireflyIceChannelUSB>(device);
		std::shared_ptr<FDFireflyIce> fireflyIce = std::make_shared<FDFireflyIce>();
		fireflyIce->observable.addObserver(fireflyIce);
		fireflyIce->addChannel(channel, channel->getName());

		result = WaitForSingleObject(usb.getWriteEvent(), INFINITE);
		/*
		// little endian
		// uint8 sequence number
		// uint16 data length
		// uint8 command ping 1
		// uint16 ping data length
		// uint8[] ping data
		uint8_t data[] = { 0, 4, 0, 1, 1, 0, 0x5a };
		std::vector<uint8_t> outputReport(data, data + sizeof(data));
		outputReport.resize(64);
		usb.writeOutputReport(outputReport);
		*/

		std::vector<uint8_t> pingData;
		pingData.push_back(0x5a);
		fireflyIce->coder->sendPing(channel, pingData);

		usb.startAsynchronousRead();
		result = WaitForSingleObject(usb.getReadEvent(), INFINITE);
		std::vector<uint8_t> inputReport = usb.readInputReport();
		channel->usbHidDeviceReport(device, inputReport);

		usb.close();
	}
}




#define MAX_LOADSTRING 100

// Global Variables:
HINSTANCE hInst;								// current instance
TCHAR szTitle[MAX_LOADSTRING];					// The title bar text
TCHAR szWindowClass[MAX_LOADSTRING];			// the main window class name

// Forward declarations of functions included in this code module:
ATOM				MyRegisterClass(HINSTANCE hInstance);
BOOL				InitInstance(HINSTANCE, int);
LRESULT CALLBACK	WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK	About(HWND, UINT, WPARAM, LPARAM);

int APIENTRY _tWinMain(_In_ HINSTANCE hInstance,
                     _In_opt_ HINSTANCE hPrevInstance,
                     _In_ LPTSTR    lpCmdLine,
                     _In_ int       nCmdShow)
{
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);

 	// TODO: Place code here.
	MSG msg;
	HACCEL hAccelTable;

	// Initialize global strings
	LoadString(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
	LoadString(hInstance, IDC_FIREFLYTEST, szWindowClass, MAX_LOADSTRING);
	MyRegisterClass(hInstance);

	// Perform application initialization:
	if (!InitInstance (hInstance, nCmdShow))
	{
		return FALSE;
	}

	hAccelTable = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDC_FIREFLYTEST));

	// Main message loop:
	while (GetMessage(&msg, NULL, 0, 0))
	{
		if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}

	return (int) msg.wParam;
}



//
//  FUNCTION: MyRegisterClass()
//
//  PURPOSE: Registers the window class.
//
ATOM MyRegisterClass(HINSTANCE hInstance)
{
	WNDCLASSEX wcex;

	wcex.cbSize = sizeof(WNDCLASSEX);

	wcex.style			= CS_HREDRAW | CS_VREDRAW;
	wcex.lpfnWndProc	= WndProc;
	wcex.cbClsExtra		= 0;
	wcex.cbWndExtra		= 0;
	wcex.hInstance		= hInstance;
	wcex.hIcon			= LoadIcon(hInstance, MAKEINTRESOURCE(IDI_FIREFLYTEST));
	wcex.hCursor		= LoadCursor(NULL, IDC_ARROW);
	wcex.hbrBackground	= (HBRUSH)(COLOR_WINDOW+1);
	wcex.lpszMenuName	= MAKEINTRESOURCE(IDC_FIREFLYTEST);
	wcex.lpszClassName	= szWindowClass;
	wcex.hIconSm		= LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_SMALL));

	return RegisterClassEx(&wcex);
}

//
//   FUNCTION: InitInstance(HINSTANCE, int)
//
//   PURPOSE: Saves instance handle and creates main window
//
//   COMMENTS:
//
//        In this function, we save the instance handle in a global variable and
//        create and display the main program window.
//
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
   HWND hWnd;

   hInst = hInstance; // Store instance handle in our global variable

   hWnd = CreateWindow(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW,
      CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, NULL, NULL, hInstance, NULL);

   if (!hWnd)
   {
      return FALSE;
   }

   ShowWindow(hWnd, nCmdShow);
   UpdateWindow(hWnd);

   test();

   return TRUE;
}

//
//  FUNCTION: WndProc(HWND, UINT, WPARAM, LPARAM)
//
//  PURPOSE:  Processes messages for the main window.
//
//  WM_COMMAND	- process the application menu
//  WM_PAINT	- Paint the main window
//  WM_DESTROY	- post a quit message and return
//
//
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	int wmId, wmEvent;
	PAINTSTRUCT ps;
	HDC hdc;

	switch (message)
	{
	case WM_COMMAND:
		wmId    = LOWORD(wParam);
		wmEvent = HIWORD(wParam);
		// Parse the menu selections:
		switch (wmId)
		{
		case IDM_ABOUT:
			DialogBox(hInst, MAKEINTRESOURCE(IDD_ABOUTBOX), hWnd, About);
			break;
		case IDM_EXIT:
			DestroyWindow(hWnd);
			break;
		default:
			return DefWindowProc(hWnd, message, wParam, lParam);
		}
		break;
	case WM_PAINT:
		hdc = BeginPaint(hWnd, &ps);
		// TODO: Add any drawing code here...
		EndPaint(hWnd, &ps);
		break;
	case WM_DESTROY:
		PostQuitMessage(0);
		break;
	default:
		return DefWindowProc(hWnd, message, wParam, lParam);
	}
	return 0;
}

// Message handler for about box.
INT_PTR CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);
	switch (message)
	{
	case WM_INITDIALOG:
		return (INT_PTR)TRUE;

	case WM_COMMAND:
		if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
		{
			EndDialog(hDlg, LOWORD(wParam));
			return (INT_PTR)TRUE;
		}
		break;
	}
	return (INT_PTR)FALSE;
}
