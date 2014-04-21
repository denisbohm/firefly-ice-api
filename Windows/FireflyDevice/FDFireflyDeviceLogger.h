//
//  FDFireflyDeviceLogger.h
//  FireflyDevice
//
//  Created by Denis Bohm on 12/21/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDFIREFLYDEVICELOGGER_H
#define FDFIREFLYDEVICELOGGER_H

#include <stdarg.h>

#include <memory>
#include <string>

namespace FireflyDesign {

#define FDFireflyDeviceLogError(f, ...) FDFireflyDeviceLogger::log(log, __FILE__, __LINE__, __FUNCSIG__, f, ##__VA_ARGS__)
#define FDFireflyDeviceLogWarn(f, ...) FDFireflyDeviceLogger::log(log, __FILE__, __LINE__, __FUNCSIG__, f, ##__VA_ARGS__)
#define FDFireflyDeviceLogInfo(f, ...) FDFireflyDeviceLogger::log(log, __FILE__, __LINE__, __FUNCSIG__, f, ##__VA_ARGS__)
#define FDFireflyDeviceLogDebug(f, ...) FDFireflyDeviceLogger::log(log, __FILE__, __LINE__, __FUNCSIG__, f, ##__VA_ARGS__)
#define FDFireflyDeviceLogVerbose(f, ...) FDFireflyDeviceLogger::log(log, __FILE__, __LINE__, __FUNCSIG__, f, ##__VA_ARGS__)

	class FDFireflyDeviceLog {
	public:
		~FDFireflyDeviceLog() {}

		virtual void log(std::string file, unsigned line, std::string method, std::string message) = 0;
	};

	class FDFireflyDeviceLogger {
	public:
		void setLog(std::shared_ptr<FDFireflyDeviceLog> log);
		std::shared_ptr<FDFireflyDeviceLog> getLog();

		static void log(std::shared_ptr<FDFireflyDeviceLog> log, std::string file, unsigned line, std::string method, std::string format, ...);
	};

}

#endif