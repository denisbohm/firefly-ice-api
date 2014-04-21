//
//  FDFireflyIceTaskSteps.h
//  FireflyDevice
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDFIREFLYICETASKSTEPS_H
#define FDFIREFLYICETASKSTEPS_H

#include "FDExecutor.h"
#include "FDFireflyIce.h"

#include <memory>

namespace FireflyDesign {

	class FDFireflyIceTaskSteps : public FDExecutorTask, public FDFireflyIceObserver, public std::enable_shared_from_this<FDFireflyIceTaskSteps>
	{
	public:
		FDFireflyIceTaskSteps(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel);
		virtual ~FDFireflyIceTaskSteps();

		std::shared_ptr<FDFireflyIce> fireflyIce;
		std::shared_ptr<FDFireflyIceChannel> channel;

		void next(std::function<void()> invocation);
		void done();

		std::shared_ptr<FDFireflyDeviceLog> log;

	private:
		std::function<uint32_t()> _random;
		std::function<void()> _invocation;
		uint32_t _invocationId;

	public:
		virtual void executorTaskStarted(FDExecutor *executor);
		virtual void executorTaskSuspended(FDExecutor *executor);
		virtual void executorTaskResumed(FDExecutor *executor);
		virtual void executorTaskCompleted(FDExecutor *executor);
		virtual void executorTaskFailed(FDExecutor *executor, std::shared_ptr<FDError> error);

	public:
		virtual void fireflyIceDetourError(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::shared_ptr<FDDetour> detour, std::shared_ptr<FDError> error);
		virtual void fireflyIcePing(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> data);
	};

}

#endif
