//
//  FDUsb.h
//  FireflyDevice
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDUSB_H
#define FDUSB_H

#include <cstdint>
#include <vector>

#include <windows.h>

namespace fireflydesign {

	class FDUsb {
	public:
		static std::vector<std::wstring> allDevicePaths();

		FDUsb(std::wstring path);
		virtual ~FDUsb();

		void open();
		void close();

		HANDLE getWriteEvent();
		void writeOutputReport(std::vector<uint8_t> outputReport);

		HANDLE getReadEvent();
		void startAsynchronousRead();
		std::vector<uint8_t> readInputReport();

	private:
		std::wstring _path;

		HANDLE _fileHandle;

		HANDLE _writeEvent;
		OVERLAPPED _writeOverlapped;
		uint8_t _writeBuffer[65];

		HANDLE _readEvent;
		OVERLAPPED _readOverlapped;
		uint8_t _readBuffer[65];
	};

}

#endif