//
//  FDBundle.h
//  FireflyDevice
//
//  Created by Denis Bohm on 2/14/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDBUNDLE_H
#define FDBUNDLE_H

#include <map>

namespace fireflydesign {

	class FDBundleInfo {
	public:
		std::map<std::string, std::string> infoDictionary;
	};

	class FDBundle : public FDBundleInfo {
	public:
		FDBundle();
	};

}

#endif