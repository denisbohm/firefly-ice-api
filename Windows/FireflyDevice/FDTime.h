//
//  FDTime.h
//  FireflyDevice
//
//  Created by Denis Bohm on 3/27/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDTIME_H
#define FDTIME_H

#include "FDCommon.h"

namespace FireflyDesign {

	class FDTime {
	public:
		typedef double time_type;
		typedef double duration_type;

		static time_type time();
	};

}

#endif