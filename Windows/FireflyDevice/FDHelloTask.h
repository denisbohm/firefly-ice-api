//
//  FDHelloTask.h
//  FireflyDevice
//
//  Created by Denis Bohm on 10/6/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDHELLOTASK_H
#define FDHELLOTASK_H

#include "FDFireflyIceTaskSteps.h"

namespace FireflyDesign {

#define FDHelloTaskErrorDomain "com.fireflydesign.device.FDHelloTask"

	enum {
		FDHelloTaskErrorCodeIncomplete
	};

	class FDHelloTask;

	class FDHelloTaskDelegate {
	public:
		virtual ~FDHelloTaskDelegate() {}
		virtual void helloTaskSuccess(FDHelloTask *helloTask) {}
		virtual void helloTaskError(FDHelloTask *helloTask, std::shared_ptr<FDError> error) {}
	};

	class FDHelloTask : public FDFireflyIceTaskSteps {
	public:
		FDHelloTask(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::shared_ptr<FDHelloTaskDelegate> delegate);

		std::shared_ptr<FDHelloTaskDelegate> delegate;

	public:
		virtual void fireflyIceVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceVersion version);
		virtual void fireflyIceHardwareId(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceHardwareId hardwareId);
		virtual void fireflyIceBootVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceVersion bootVersion);
		virtual void fireflyIceTime(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, time_type time);
		virtual void fireflyIcePower(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIcePower power);
		virtual void fireflyIceReset(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceReset reset);

	private:
		typedef double duration_type;

		duration_type _maxOffset;

	public:
		std::shared_ptr<FDFireflyIceVersion> _version;
		std::shared_ptr<FDFireflyIceVersion> _bootVersion;
		std::shared_ptr<FDFireflyIceHardwareId> _hardwareId;
		time_type _time;
		std::shared_ptr<FDFireflyIcePower> _power;
		std::shared_ptr<FDFireflyIceReset> _reset;

	private:
		virtual void executorTaskStarted(FDExecutor *executor);
		virtual void executorTaskCompleted(FDExecutor *executor);
		virtual void executorTaskFailed(FDExecutor *executor, std::shared_ptr<FDError> error);

		void checkVersion();
		void checkTime();
		void setTime();
	};

}

#endif