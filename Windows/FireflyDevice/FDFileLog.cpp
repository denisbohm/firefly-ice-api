//
//  FDFileLog.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 12/23/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDFileLog.h"

#include <cstdio>
#include <iomanip>
#include <iostream>

namespace fireflydesign {

	FDFileLog::FDFileLog() {
		logLimit = 100000;
		logDirectory = std::tr2::sys::initial_path<std::tr2::sys::path>();
		logFileName = logDirectory / std::tr2::sys::path("log.txt");
		logFileNameOld = logDirectory / std::tr2::sys::path("log-1.txt");
	}

	std::string FDFileLog::getContent() {
		std::stringstream buffer;
		FDFileLog::getContent(buffer);
		return buffer.str();
	}

	void FDFileLog::getContent(std::stringstream& buffer) {
		std::lock_guard<std::mutex> lock(logMutex);

		close();

		appendFile(buffer, logFileNameOld);
		appendFile(buffer, logFileName);
	}

	void FDFileLog::appendFile(std::stringstream& buffer, std::string fileName) {
		std::ifstream stream(fileName);
		buffer << stream.rdbuf();
	}

	void FDFileLog::close() {
		logFile.close();
	}

	void FDFileLog::log(std::string message) {
		std::lock_guard<std::mutex> lock(logMutex);

		if (!logFile.is_open()) {
			logFile.open(logFileName, std::ofstream::out | std::ofstream::app);
			if (!logFile.is_open()) {
				std::tr2::sys::create_directories(logDirectory);
				logFile.open(logFileName, std::ofstream::out | std::ofstream::app);
			}
		}
		if (logFile.is_open()) {
			std::time_t time = std::time(NULL);
			struct tm tm;
			gmtime_s(&tm, &time);
			// "yyyy-MM-dd HH:mm:ss.SSS"
			logFile << std::put_time(&tm, "%Y-%m-%d %H:%M:%S") << " " << message << "\n";
			logFile.flush();
			unsigned long long length = logFile.tellp();
			if (length > logLimit) {
				close();
				std::tr2::sys::remove(logFileNameOld);
				std::tr2::sys::rename(logFileName, logFileNameOld);
			}
		}
	}

	std::string FDFileLog::lastPathComponent(std::string path) {
		std::size_t index = path.find_last_of("/\\");
		if (index != std::string::npos) {
			return path.substr(index + 1);
		}
		return path;
	}

	void FDFileLog::log(std::string file, unsigned line, std::string cls, std::string method, std::string message) {
		std::string fullMessage = lastPathComponent(file) + ":" + std::to_string(line) + " " + cls + "." + method + " " + message;

		std::cout << fullMessage << "\n";
		log(fullMessage);
	}

}
