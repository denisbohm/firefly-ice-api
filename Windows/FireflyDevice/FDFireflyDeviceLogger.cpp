//
//  FDFireflyDeviceLogger.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 12/21/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDFireflyDeviceLogger.h"
#include "FDString.h"

#include <Windows.h>

namespace FireflyDesign {

	static std::shared_ptr<FDFireflyDeviceLog> fireflyDeviceLogger;

	void FDFireflyDeviceLogger::setLog(std::shared_ptr<FDFireflyDeviceLog> log) {
		fireflyDeviceLogger = log;
	}

	std::shared_ptr<FDFireflyDeviceLog> FDFireflyDeviceLogger::getLog() {
		return fireflyDeviceLogger;
	}

	void FDFireflyDeviceLogger::log(std::shared_ptr<FDFireflyDeviceLog> log, std::string file, unsigned line, std::string method, std::string format, ...) {
		va_list args;
		va_start(args, format);
		char buffer[512];
		vsnprintf_s(buffer, sizeof(buffer), format.c_str(), args);
		va_end(args);
		std::string message(buffer);

		size_t index = file.find_last_of('\\');
		if (index != std::string::npos) {
			file = file.substr(index + 1);
		}

		if (!log) {
			log = fireflyDeviceLogger;
		}
		if (log) {
			log->log(file, line, method, message);
		} else {
			std::string s = FDString::format("%s:%lu %s %s\n", file.c_str(), (unsigned long)line, method.c_str(), message.c_str());
			printf("%s", s.c_str());
			std::wstring ws(s.begin(), s.end());
			OutputDebugString(ws.c_str());
		}
	}

}
