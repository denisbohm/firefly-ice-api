//
//  FDTimer.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDTimer.h"

namespace FireflyDesign {

	FDTimer::~FDTimer() {
	}

	std::shared_ptr<FDTimerFactory> FDTimerFactory::defaultTimerFactory;

	FDTimerFactory::~FDTimerFactory() {
	}

}