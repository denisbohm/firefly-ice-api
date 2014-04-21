//
//  FDString.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 3/27/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDString.h"

#include <cstdarg>
#include <cstdio>
#include <iomanip>
#include <sstream>
#include <vector>

namespace FireflyDesign {

	std::string FDString::format(const std::string fmt, ...) {
		std::vector<char> str(100, '\0');
		while (1) {
			va_list ap;
			va_start(ap, fmt);
			auto n = vsnprintf_s(str.data(), str.size(), _TRUNCATE, fmt.c_str(), ap);
			va_end(ap);
			if ((n > -1) && (size_t(n) < str.size())) {
				return str.data();
			}
			if (n > -1)
				str.resize(n + 1);
			else
				str.resize(str.size() * 2);
		}
		return str.data();
	}

	std::string FDString::formatDateTime(time_type epochTime) {
		std::time_t time = (std::time_t)epochTime;
		struct tm tm;
		gmtime_s(&tm, &time);
		std::stringstream ss;
		// "yyyy-MM-dd HH:mm:ss.SSS"
		ss << std::put_time(&tm, "%Y-%m-%d %H:%M:%S");
		std::string s = ss.str();
		return s;
	}

}