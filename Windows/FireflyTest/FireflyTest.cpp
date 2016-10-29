// FireflyTest.cpp : Defines the entry point for the application.
//

#include "stdafx.h"
#include "FireflyTest.h"

#include "../FireflyDevice/FDFireflyIce.h"
#include "../FireflyDevice/FDFireflyIceChannelUSB.h"
#include "../FireflyDevice/FDFireflyIceCoder.h"
#include "../FireflyDevice/FDTimer.h"
#include "../FireflyDevice/FDUsb.h"

#include <iostream>

using namespace FireflyDesign;

// Create a no-op FDTimer and FDTimerFactory.  You would need a real implementation that
// works with your main event loop dispatch for a real application.  This ping test application
// does not actually require timers.
class Timer : public FDTimer {
public:
	Timer();

	virtual void setInvocation(std::function<void()> invocation);
	virtual std::function<void()> getInvocation();

	virtual void setTimeout(duration_type timeout);
	virtual duration_type getTimeout();

	virtual void setType(Type type);
	virtual Type getType();

	virtual void setEnabled(bool enabled);
	virtual bool isEnabled();

private:
	std::function<void()> invocation;
	duration_type timeout;
	Type type;
	bool enabled;
};

Timer::Timer() {
}

void Timer::setInvocation(std::function<void()> invocation) {
	this->invocation = invocation;
}

std::function<void()> Timer::getInvocation() {
	return invocation;
}

void Timer::setTimeout(duration_type timeout) {
	this->timeout = timeout;
}

FDTimer::duration_type Timer::getTimeout() {
	return timeout;
}

void Timer::setType(Type type) {
	this->type = type;
}

FDTimer::Type Timer::getType() {
	return type;
}

void Timer::setEnabled(bool enabled) {
	this->enabled = enabled;
}

bool Timer::isEnabled() {
	return enabled;
}

class TimerFactory : public FDTimerFactory {
public:
	TimerFactory();

	std::shared_ptr<FDTimer> makeTimer(std::function<void()> invocation, FDTimer::duration_type timeout, FDTimer::Type type);

};

TimerFactory::TimerFactory() {
}

std::shared_ptr<FDTimer> TimerFactory::makeTimer(std::function<void()> invocation, FDTimer::duration_type timeout, FDTimer::Type type) {
	return std::make_shared<Timer>();
}

class Device : public FDFireflyIceChannelUSBDevice {
public:
	Device(FDUsb *usb) {
		_usb = usb;
	}
	virtual ~Device() {
	}

	virtual void setDelegate(std::shared_ptr<FDFireflyIceChannelUSBDeviceDelegate> delegate) { _delegate = delegate; }
	virtual std::shared_ptr<FDFireflyIceChannelUSBDeviceDelegate> getDelegate() { return _delegate; }

	virtual void open() {
		_usb->open();
	}
	virtual void close() {
		_usb->close();
	}

	virtual void setReport(std::vector<uint8_t> data) {
		_usb->writeOutputReport(data);
	}

private:
	FDUsb *_usb;
	std::shared_ptr<FDFireflyIceChannelUSBDeviceDelegate> _delegate;
};

class Observer : public FDFireflyIceObserver {
public:
	virtual void fireflyIcePing(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> data) {
		OutputDebugString(L"ping\n");
	}
};

// This test sends a ping command to all FireflyIce devices on USB ports and prints "ping" when
// the ping response is received.  Note that this example uses blocking waits for I/O.  Normally,
// the I/O events should be handled in your main loop.
void test() {
	std::vector<std::wstring> paths = FDUsb::allDevicePaths();
	for (std::wstring path : paths) {
		OutputDebugString(path.c_str());
		OutputDebugString(L"\n");

		// create and configure a FireflyIce object to communicate with the device via USB
		DWORD result;
		FDUsb usb(path);
		std::shared_ptr<Device> device = std::make_shared<Device>(&usb);
		std::shared_ptr<FDFireflyIceChannelUSB> channel = std::make_shared<FDFireflyIceChannelUSB>(device);
		std::shared_ptr<TimerFactory> timerFactory = std::make_shared<TimerFactory>();
		std::shared_ptr<FDFireflyIce> fireflyIce = std::make_shared<FDFireflyIce>(timerFactory);
		fireflyIce->observable->addObserver(fireflyIce);
		fireflyIce->addChannel(channel, channel->getName());

		// add our observer so we can get ping backs
		std::shared_ptr<Observer> observer = std::make_shared<Observer>();
		fireflyIce->observable->addObserver(observer);

		// open the USB channel to the device
		channel->open();

		// send a ping to the device
		std::vector<uint8_t> pingData;
		pingData.push_back(0x5a);
		fireflyIce->coder->sendPing(channel, pingData);

		// Normally the code below would be called from the main dispatch loop,
		// but for simplicity of this example we just do it all in a blocking
		// manner so it is easy see the sequence.

		// wait for the USB write to complete
		result = WaitForSingleObject(usb.getWriteEvent(), INFINITE);
		if (result == WAIT_OBJECT_0) {
			OutputDebugString(L"write complete\n");
		}
		// wait for the USB response to be received
		usb.startAsynchronousRead();
		result = WaitForSingleObject(usb.getReadEvent(), INFINITE);
		if (result == WAIT_OBJECT_0) {
			OutputDebugString(L"read complete\n");
		}

		// get the USB response data and send it to the channel to decode it and dispatch it to the observers
		std::vector<uint8_t> inputReport = usb.readInputReport();
		channel->usbHidDeviceReport(device, inputReport);
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
