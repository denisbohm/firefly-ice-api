//
//  FDString.h
//  FireflyDevice
//
//  Created by Denis Bohm on 3/27/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDSTRING_H
#define FDSTRING_H

#include <string>

namespace FireflyDesign {

	class FDString {
	public:
		typedef double time_type;

		static std::string format(const std::string fmt, ...);
		static std::string formatDateTime(time_type time);
	};

}

#endif