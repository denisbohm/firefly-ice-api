//
//  FDFireflyIceSimpleTask.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 10/17/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDFireflyIceSimpleTask.h"

namespace FireflyDesign {

	FDFireflyIceSimpleTask::FDFireflyIceSimpleTask(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::function<void(void)> block)
		: FDFireflyIceTaskSteps(fireflyIce, channel)
	{
		_block = block;
	}

	void FDFireflyIceSimpleTask::executorTaskStarted(FDExecutor *executor) {
		FDFireflyIceTaskSteps::executorTaskStarted(executor);
		_block();
		next(std::bind(&FDFireflyIceSimpleTask::complete, this));
	}

	void FDFireflyIceSimpleTask::complete() {
		done();
	}

}
