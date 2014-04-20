//
//  FDUsb.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDUsb.h"

#include <exception>
#include <string>
#include <vector>

#include <Hidsdi.h>
#include <Rpc.h>
#include <Setupapi.h>

#pragma comment( lib, "Hid" )
#pragma comment( lib, "Setupapi" )

namespace FireflyDesign {

#define FIREFLY_ICE_VENDOR_ID 0x2333
#define FIREFLY_ICE_PRODUCT_ID 0x0002

	class WinUsb {
	public:
		WinUsb();
		~WinUsb();

		std::vector<std::wstring> enumerate();

	private:
		void disposeDetail();

		HDEVINFO hDevInfo;

		PSP_INTERFACE_DEVICE_DETAIL_DATA detailData;
		HANDLE deviceHandle;
	};

	WinUsb::WinUsb() {
		hDevInfo = 0;
		detailData = 0;
		deviceHandle = INVALID_HANDLE_VALUE;
	}

	void WinUsb::disposeDetail() {
		if (detailData) {
			free(detailData);
			detailData = 0;
		}
		if (deviceHandle != INVALID_HANDLE_VALUE) {
			CloseHandle(deviceHandle);
			deviceHandle = INVALID_HANDLE_VALUE;
		}
	}

	WinUsb::~WinUsb() {
		disposeDetail();

		if (hDevInfo) {
			SetupDiDestroyDeviceInfoList(hDevInfo);
		}
	}

	std::vector<std::wstring> WinUsb::enumerate() {
		std::vector<std::wstring> paths;

		GUID HidGuid;
		HidD_GetHidGuid(&HidGuid);

		// Get information about HIDs
		hDevInfo = SetupDiGetClassDevs(&HidGuid, NULL, NULL, DIGCF_PRESENT | DIGCF_INTERFACEDEVICE);
		if (hDevInfo == INVALID_HANDLE_VALUE)
		{
			throw std::exception("SetupDiGetClassDevs failed");
		}

		// Identify each HID interface
		DWORD MemberIndex = 0;
		while (1) {
			SP_DEVICE_INTERFACE_DATA devInfoData;
			devInfoData.cbSize = sizeof(devInfoData);
			if (!SetupDiEnumDeviceInterfaces(hDevInfo, 0, &HidGuid, MemberIndex, &devInfoData))
			{
				break;
			}
			++MemberIndex;

			// Get the Pathname of the current device
			DWORD required = 0;
			if (!SetupDiGetDeviceInterfaceDetail(hDevInfo, &devInfoData, NULL, 0, &required, NULL)) {
				if (GetLastError() != ERROR_INSUFFICIENT_BUFFER)
				{
					continue;
				}
			}
			// detailData.cbSize = sizeof(SP_INTERFACE_DEVICE_DETAIL_DATA); detailData.cbSize = 5;
			detailData = (PSP_INTERFACE_DEVICE_DETAIL_DATA)malloc(required);
			detailData->cbSize = sizeof(SP_INTERFACE_DEVICE_DETAIL_DATA);
			if (!SetupDiGetDeviceInterfaceDetail(hDevInfo, &devInfoData, detailData, required, NULL, NULL)) {
				disposeDetail();
				continue;
			}

			// Get Handle for the current device
			deviceHandle = CreateFile(
				detailData->DevicePath,
				GENERIC_READ | GENERIC_WRITE,
				FILE_SHARE_READ | FILE_SHARE_WRITE,
				(LPSECURITY_ATTRIBUTES)NULL,
				OPEN_EXISTING,
				0,
				NULL
				);
			if (deviceHandle == INVALID_HANDLE_VALUE)
			{
				disposeDetail();
				continue;
			}

			// Read Attributes from the current device
			HIDD_ATTRIBUTES Attributes;
			Attributes.Size = sizeof(Attributes);
			if (!HidD_GetAttributes(deviceHandle, &Attributes))
			{
				disposeDetail();
				continue;
			}

			if ((Attributes.VendorID == FIREFLY_ICE_VENDOR_ID) && (Attributes.ProductID == FIREFLY_ICE_PRODUCT_ID))
			{
				paths.push_back(std::wstring(detailData->DevicePath));
			}

			disposeDetail();
		}

		return paths;
	}

	std::vector<std::wstring> FDUsb::allDevicePaths() {
		WinUsb winUsb;
		std::vector<std::wstring> paths = winUsb.enumerate();
		return paths;
	}

	FDUsb::FDUsb(std::wstring path)
	{
		_path = path;

		_fileHandle = INVALID_HANDLE_VALUE;
		_writeEvent = NULL;
		_readEvent = NULL;
	}

	FDUsb::~FDUsb()
	{
		close();
	}

	void FDUsb::open()
	{
		close();

		_fileHandle = CreateFile(_path.c_str(), GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, NULL);
		if (_fileHandle == INVALID_HANDLE_VALUE)
		{
			throw std::exception("CreateFile error");
		}

		_writeEvent = CreateEvent(NULL, TRUE, TRUE, NULL);
		if (_writeEvent == NULL)
		{
			throw std::exception("CreateEvent error");
		}
		memset(&_writeOverlapped, sizeof(OVERLAPPED), 0);
		_writeOverlapped.hEvent = _writeEvent;

		_readEvent = CreateEvent(NULL, TRUE, TRUE, NULL);
		if (_readEvent == NULL)
		{
			throw std::exception("CreateEvent error");
		}
		memset(&_readOverlapped, sizeof(OVERLAPPED), 0);
		_readOverlapped.hEvent = _readEvent;
	}

	void FDUsb::close()
	{
		if (_fileHandle != INVALID_HANDLE_VALUE)
		{
			CancelIo(_fileHandle);
			CloseHandle(_fileHandle);
			_fileHandle = INVALID_HANDLE_VALUE;
		}

		if (_writeEvent != NULL)
		{
			CloseHandle(_writeEvent);
			_writeEvent = NULL;
		}

		if (_readEvent != NULL)
		{
			CloseHandle(_readEvent);
			_readEvent = NULL;
		}
	}

	HANDLE FDUsb::getReadEvent() {
		return _readEvent;
	}

	HANDLE FDUsb::getWriteEvent() {
		return _writeEvent;
	}

	/*
	void FDUsb::writeOutputReport(std::vector<uint8_t> outputReport)
	{
		if (outputReport.size() != 64)
		{
			throw std::exception("invalid output report size");
		}
		uint8_t buffer[65];
		buffer[0] = 0;
		memcpy(&buffer[1], outputReport.data(), 64);
		HidD_SetOutputReport(_writeHandle, buffer, 64);
	}

	std::vector<uint8_t> FDUsb::readInputReport()
	{
		uint8_t inputReport[65];
		inputReport[0] = 0;
		if (!HidD_GetInputReport(_readHandle, inputReport, 64))
		{
			throw std::exception("HidD_GetInputReport failed");
		}
		return std::vector<uint8_t>(inputReport, inputReport + 64);
	}
	*/

	void FDUsb::writeOutputReport(std::vector<uint8_t> outputReport)
	{
		if (outputReport.size() != 64)
		{
			throw std::exception("invalid output report size");
		}

		DWORD writeCount;
		if (GetOverlappedResult(_fileHandle, &_writeOverlapped, &writeCount, FALSE) == 0) {
			throw std::exception("GetOverlappedResult failed");
		}

		memcpy(&_writeBuffer[1], outputReport.data(), 64);
		_writeBuffer[0] = 0;
		if (!WriteFile(_fileHandle, _writeBuffer, 65, &writeCount, &_writeOverlapped)) {
			DWORD error = GetLastError();
			if (error == ERROR_HANDLE_EOF)
			{
				throw std::exception("ReadFile failed: EOF");
			}
			if (error != ERROR_IO_PENDING)
			{
				throw std::exception("ReadFile failed");
			}
		}
	}

	std::vector<uint8_t> FDUsb::readInputReport()
	{
		DWORD numberOfBytesTransferred;
		if (!GetOverlappedResult(_fileHandle, &_readOverlapped, &numberOfBytesTransferred, FALSE)) {
			if (GetLastError() != ERROR_IO_PENDING)
			{
				throw std::exception("GetOverlappedResult failed");
			}
			throw std::exception("GetOverlappedResult failed: I/O pending");
		}
		if (numberOfBytesTransferred != 65)
		{
			throw std::exception("GetOverlappedResult failed: incorrect number of bytes transferred");
		}

		return std::vector<uint8_t>(&_readBuffer[1], &_readBuffer[1] + 64);
	}

	void FDUsb::startAsynchronousRead()
	{
		if (!ReadFile(_fileHandle, _readBuffer, sizeof(_readBuffer), NULL, &_readOverlapped)) {
			if (GetLastError() == ERROR_HANDLE_EOF)
			{
				throw std::exception("ReadFile failed: EOF");
			}
			if (GetLastError() != ERROR_IO_PENDING)
			{
				throw std::exception("ReadFile failed");
			}
		}
	}

}