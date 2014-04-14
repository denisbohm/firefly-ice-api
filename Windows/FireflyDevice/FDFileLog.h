//
//  FDFileLog.h
//  FireflyDevice
//
//  Created by Denis Bohm on 12/23/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDFILELOG_H
#define FDFILELOG_H

#include "FDFireflyDeviceLogger.h"

#include <filesystem>
#include <mutex>
#include <sstream>
#include <string>

namespace fireflydesign {

	class FDFileLog : FDFireflyDeviceLog {
	public:
		FDFileLog();

		std::size_t logLimit;

		void getContent(std::stringstream& string);
		std::string getContent();

		virtual void log(std::string file, unsigned line, std::string cls, std::string method, std::string message);

	private:
		std::tr2::sys::path logDirectory;
		std::tr2::sys::path logFileName;
		std::tr2::sys::path logFileNameOld;
		std::mutex logMutex;
		std::ofstream logFile;

		void FDFileLog::appendFile(std::stringstream& buffer, std::string fileName);
		void FDFileLog::close();
		void FDFileLog::log(std::string message);
		std::string FDFileLog::lastPathComponent(std::string path);
	};

}

#endif