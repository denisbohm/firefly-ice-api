//
//  FDFireflyDeviceLogger.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 12/21/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDFireflyDeviceLogger.h"

namespace fireflydesign {

	static std::shared_ptr<FDFireflyDeviceLog> fireflyDeviceLogger;

	void FDFireflyDeviceLogger::setLog(std::shared_ptr<FDFireflyDeviceLog> log) {
		fireflyDeviceLogger = log;
	}

	std::shared_ptr<FDFireflyDeviceLog> FDFireflyDeviceLogger::getLog() {
		return fireflyDeviceLogger;
	}

	void FDFireflyDeviceLogger::log(std::shared_ptr<FDFireflyDeviceLog> log, std::string file, unsigned line, std::string cls, std::string method, std::string format, ...) {
		va_list args;
		va_start(args, format);
		char buffer[256];
		vsnprintf_s(buffer, sizeof(buffer), format.c_str(), args);
		va_end(args);
		std::string message(buffer);

		if (!log) {
			log = fireflyDeviceLogger;
		}
		if (log) {
			log->log(file, line, cls, method, message);
		} else {
			printf("log: %s:%lu %@.%@ %@", file.c_str(), (unsigned long)line, cls.c_str(), method.c_str(), message.c_str());
		}
	}

}
