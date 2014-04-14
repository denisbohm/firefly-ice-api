//
//  FDExecutor.h
//  FireflyDevice
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDEXECUTOR_H
#define FDEXECUTOR_H

#include "FDError.h"

#include <exception>
#include <list>
#include <vector>

namespace fireflydesign {

	class FDFireflyDeviceLog;
	class FDExecutor;

#define FDExecutorErrorDomain "com.fireflydesign.device.FDExecutor"

	class FDExecutorTask {
	public:
		FDExecutorTask();
		virtual ~FDExecutorTask();

		typedef double time_interval_type;
		typedef double date_type;

		time_interval_type timeout;
		int priority;
		bool isSuspended;
		date_type appointment;

		virtual void executorTaskStarted(FDExecutor *executor) = 0;
		virtual void executorTaskSuspended(FDExecutor *executor) = 0;
		virtual void executorTaskResumed(FDExecutor *executor) = 0;
		virtual void executorTaskCompleted(FDExecutor *executor) = 0;
		virtual void executorTaskFailed(FDExecutor *executor, std::shared_ptr<FDError> error) = 0;
	};

	enum FDExecutorError {
		FDExecutorErrorCodeAbort,
		FDExecutorErrorCodeCancel,
		FDExecutorErrorCodeTimeout,
	};

	class FDExecutor {
	public:
		typedef double time_interval_type;
		typedef double date_type;

		FDExecutor();
		~FDExecutor();

		std::shared_ptr<FDFireflyDeviceLog> log;

		time_interval_type timeoutCheckInterval;

		bool getRun();
		void setRun(bool run);

		void execute(std::shared_ptr<FDExecutorTask> task);
		void cancel(std::shared_ptr<FDExecutorTask> task);
		std::vector<std::shared_ptr<FDExecutorTask>> allTasks();
		bool hasTasks();

		void feedWatchdog(std::shared_ptr<FDExecutorTask> task);
		void complete(std::shared_ptr<FDExecutorTask> task);
		void fail(std::shared_ptr<FDExecutorTask> task, std::shared_ptr<FDError> error);

	private:
	public:
		std::list<std::shared_ptr<FDExecutorTask>> tasks;
		std::list<std::shared_ptr<FDExecutorTask>> appointmentTasks;
		std::shared_ptr<FDExecutorTask> currentTask;
		bool _run;
		date_type currentFeedTime;
//		@property NSTimer *timer;

		void start();
		void abortTask(std::shared_ptr<FDExecutorTask> task);
		void abortTasks(std::list<std::shared_ptr<FDExecutorTask>>);
		void stop();
		void sortTasksByPriority();
		void checkAppointments();
		void addTask(std::shared_ptr<FDExecutorTask> task);
		void checkTimeout();
		void check();
		void taskException(std::exception e);
		void schedule();
		void over(std::shared_ptr<FDExecutorTask> task, std::shared_ptr<FDError> error);
	};

}

#endif