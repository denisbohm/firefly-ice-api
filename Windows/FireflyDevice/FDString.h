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

namespace fireflydesign {

	class FDString {
	public:
		static std::string FDString::format(const std::string &fmt, ...);
	};

}

#endif