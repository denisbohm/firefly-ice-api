//
//  FDFireflyIceTaskSteps.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDBinary.h"
#include "FDFireflyIceCoder.h"
#include "FDFireflyIceTaskSteps.h"
#include "FDFireflyDeviceLogger.h"

#include <random>

namespace fireflydesign {

	FDFireflyIceTaskSteps::FDFireflyIceTaskSteps() {
		timeout = 15;
		priority = 0;
		isSuspended = false;
		appointment = 0;
		_random = std::bind(std::uniform_int_distribution<int32_t>{}, std::mt19937(std::random_device{}()));
		_invocation = nullptr;
		_invocationId = 0;
	}

	FDFireflyIceTaskSteps::~FDFireflyIceTaskSteps() {
	}

	void FDFireflyIceTaskSteps::executorTaskStarted(FDExecutor *executor)
	{
		//    FDFireflyDeviceLogDebug(@"%@ task started", NSStringFromClass([self class]));
		fireflyIce->observable.addObserver(shared_from_this());
	}

	void FDFireflyIceTaskSteps::executorTaskSuspended(FDExecutor *executor)
	{
		//    FDFireflyDeviceLogDebug(@"%@ task suspended", NSStringFromClass([self class]));
		fireflyIce->observable.removeObserver(shared_from_this());
	}

	void FDFireflyIceTaskSteps::executorTaskResumed(FDExecutor *executor)
	{
		//    FDFireflyDeviceLogDebug(@"%@ task resumed", NSStringFromClass([self class]));
		fireflyIce->observable.addObserver(shared_from_this());
	}

	void FDFireflyIceTaskSteps::executorTaskCompleted(FDExecutor *executor)
	{
		//    FDFireflyDeviceLogDebug(@"%@ task completed", NSStringFromClass([self class]));
		fireflyIce->observable.removeObserver(shared_from_this());
	}

	void FDFireflyIceTaskSteps::executorTaskFailed(FDExecutor *executo, std::shared_ptr<FDError> error)
	{
		//    FDFireflyDeviceLogDebug(@"%@ task failed with error %@", NSStringFromClass([self class]), error);
		fireflyIce->observable.removeObserver(shared_from_this());
	}

	void FDFireflyIceTaskSteps::fireflyIceDetourError(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::shared_ptr<FDDetour> detour, std::shared_ptr<FDError> error)
	{
		fireflyIce->executor->fail(shared_from_this(), error);
	}

	void FDFireflyIceTaskSteps::fireflyIcePing(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> data)
	{
		//    FDFireflyDeviceLogDebug(@"ping received");
		FDBinary binary(data);
		uint32_t invocationId = binary.getUInt32();
		if (invocationId != _invocationId) {
			FDFireflyDeviceLogWarn("unexpected ping 0x%08x (expected 0x%08x)", invocationId, _invocationId);
			return;
		}

		if (_invocation != nullptr) {
			//        FDFireflyDeviceLogDebug(@"invoking step %@", NSStringFromSelector(_invocation.selector));
			std::function<void(void)> invocation = _invocation;
			_invocation = nullptr;
			invocation();
		}
		else {
			//        FDFireflyDeviceLogDebug(@"all steps completed");
			fireflyIce->executor->complete(shared_from_this());
		}
	}

	void FDFireflyIceTaskSteps::next(std::function<void(void)> invocation)
	{
		//    FDFireflyDeviceLogDebug(@"queing next step %@", NSStringFromSelector(selector));

		fireflyIce->executor->feedWatchdog(shared_from_this());

		_invocation = invocation;
		_invocationId = _random();

		//    FDFireflyDeviceLogDebug(@"setup ping 0x%08x %@ %@", _invocationId, NSStringFromClass([self class]), NSStringFromSelector(_invocation.selector));

		FDBinary binary = FDBinary();
		binary.putUInt32(_invocationId);
		std::vector<uint8_t> data = binary.dataValue();
		fireflyIce->coder->sendPing(channel, data);
	}

	void FDFireflyIceTaskSteps::done()
	{
		//    FDFireflyDeviceLogDebug(@"task done");
		fireflyIce->executor->complete(shared_from_this());
	}

}
