//
//  FDTime.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 3/27/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDTime.h"

#include <ctime>

namespace FireflyDesign {

	FDTime::time_type FDTime::time() {
		time_t timer;
		std::time(&timer);
		return (time_type)timer;
	}

}
