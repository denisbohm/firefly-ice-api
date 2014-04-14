//
//  FDHelloTask.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 10/6/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDError.h"
#include "FDFireflyIceChannel.h"
#include "FDFireflyIceCoder.h"
#include "FDFireflyDeviceLogger.h"
#include "FDHelloTask.h"
#include "FDTime.h"

namespace fireflydesign {

	FDHelloTask::FDHelloTask(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::shared_ptr<FDHelloTaskDelegate> delegate)
	{
		priority = 100;
		_maxOffset = 120;
	}

	void FDHelloTask::executorTaskStarted(FDExecutor *executor)
	{
		FDFireflyIceTaskSteps::executorTaskStarted(executor);

		fireflyIce->coder->sendGetProperties(channel,
			FD_CONTROL_PROPERTY_VERSION |
			FD_CONTROL_PROPERTY_HARDWARE_ID |
			FD_CONTROL_PROPERTY_RTC |
			FD_CONTROL_PROPERTY_RESET |
			FD_CONTROL_PROPERTY_BOOT_VERSION
		);
		next(std::bind(&FDHelloTask::checkVersion, this));
	}

	void FDHelloTask::checkVersion()
	{
		if (!_version || !_hardwareId) {
			std::string description = "Incomplete information received on initial communication with the device";
			FDFireflyDeviceLogInfo(description);
			channel->close();
			std::map<std::string, std::string> userInfo;
			userInfo[FDLocalizedDescriptionKey] = description;
			userInfo[FDLocalizedRecoveryOptionsErrorKey] = "Make sure the device stays in close range";
			std::shared_ptr<FDError> error = FDError::error(FDHelloTaskErrorDomain, FDHelloTaskErrorCodeIncomplete, userInfo);
			fireflyIce->executor->fail(shared_from_this(), error);
			return;
		}

		fireflyIce->version = _version;
		fireflyIce->bootVersion = _bootVersion;
		fireflyIce->hardwareId = _hardwareId;

		if (fireflyIce->version->capabilities & FD_CONTROL_CAPABILITY_BOOT_VERSION) {
			fireflyIce->coder->sendGetProperties(channel, FD_CONTROL_PROPERTY_BOOT_VERSION);
			next(std::bind(&FDHelloTask::checkTime, this));
		} else {
			checkTime();
		}
	}

	void FDHelloTask::setTime()
	{
		FDFireflyDeviceLogInfo("setting the time");
		fireflyIce->coder->sendSetPropertyTime(channel, FDTime::time());
	}

	void FDHelloTask::checkTime()
	{
		FDFireflyDeviceLogInfo("hello (hardware %s) (firmware %s)", fireflyIce->hardwareId->description(), fireflyIce->version->description());

		if (_time == 0) {
			FDFireflyDeviceLogInfo("time not set for hw %s fw %s (last reset %s)", fireflyIce->hardwareId->description(), fireflyIce->version->description(), _reset->description());
			setTime();
		}
		else {
			duration_type offset = FDTime::time() - _time;
			if (fabs(offset) > _maxOffset) {
				FDFireflyDeviceLogInfo("time is off by %0.3f seconds for hw %s fw %s (last reset %s)", offset, fireflyIce->hardwareId->description(), fireflyIce->version->description(), _reset->description());
				setTime();
			}
			else {
				//            FDFireflyDeviceLogDebug(@"time is off by %0.3f seconds for hw %@ fw %@", offset, self.fireflyIce.hardwareId, self.fireflyIce.version);
			}
		}
		done();
	}

	void FDHelloTask::executorTaskCompleted(FDExecutor *executor)
	{
		FDFireflyIceTaskSteps::executorTaskCompleted(executor);
		if (delegate != nullptr) {
			delegate->helloTaskSuccess(this);
		}
	}

	void FDHelloTask::executorTaskFailed(FDExecutor *executor, std::shared_ptr<FDError> error)
	{
		FDFireflyIceTaskSteps::executorTaskFailed(executor, error);
		if (delegate != nullptr) {
			delegate->helloTaskError(this, error);
		}
	}

}
