//
//  FDExecutor.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDExecutor.h"
#include "FDFireflyDeviceLogger.h"
#include "FDTime.h"
#include "FDTimer.h"

namespace FireflyDesign {

	FDExecutorTask::FDExecutorTask() {
		timeout = 10;
		priority = 0;
		isSuspended = false;
		appointment = 0;
	}

	FDExecutorTask::~FDExecutorTask() {
	}

	FDExecutor::FDExecutor() {
		timeoutCheckInterval = 5;
		_run = false;
		_currentFeedTime = 0;
	}

	FDExecutor::~FDExecutor() {
	}

	void FDExecutor::start()
	{
		if (!_timer) {
			_timer = FDTimerFactory::defaultTimerFactory->makeTimer(std::bind(&FDExecutor::check, this), timeoutCheckInterval, FDTimer::Repeating);
		}
		_timer->setEnabled(true);
		schedule();
	}

	void FDExecutor::abortTask(std::shared_ptr<FDExecutorTask> task)
	{
		try {
			std::map<std::string, std::string> userInfo{ { FDLocalizedDescriptionKey, "executor task was aborted" } };
			task->executorTaskFailed(this, FDError::error(FDExecutorErrorDomain, FDExecutorErrorCodeAbort, userInfo));
		} catch (std::exception e) {
			taskException(e);
		}
	}

	void FDExecutor::abortTasks(std::list<std::shared_ptr<FDExecutorTask>> tasks)
	{
		for (std::shared_ptr<FDExecutorTask> task : tasks) {
			abortTask(task);
		}
		tasks.clear();
	}

	void FDExecutor::stop()
	{
		_timer->setEnabled(false);
		_timer.reset();

		if (currentTask) {
			abortTask(currentTask);
			currentTask.reset();
		}
		abortTasks(appointmentTasks);
		abortTasks(tasks);
	}

	bool FDExecutor::getRun() {
		return _run;
	}

	void FDExecutor::setRun(bool run)
	{
		if (_run == run) {
			return;
		}

		_run = run;
		if (_run) {
			start();
		}
		else {
			stop();
		}
	}

	void FDExecutor::sortTasksByPriority()
	{
		tasks.sort([](std::shared_ptr<FDExecutorTask> a, std::shared_ptr<FDExecutorTask> b) {
			return a->priority < b->priority;
		});
	}

	void FDExecutor::checkAppointments()
	{
		std::list<std::shared_ptr<FDExecutorTask>> tasks(appointmentTasks.begin(), appointmentTasks.end());
		FDTime::time_type now = FDTime::time();
		for (std::shared_ptr<FDExecutorTask> task : tasks) {
			if ((now - task->appointment) >= 0) {
				task->appointment = 0;
				appointmentTasks.remove(task);
				tasks.push_back(task);
			}
		}
		sortTasksByPriority();
		schedule();
	}

	void FDExecutor::addTask(std::shared_ptr<FDExecutorTask> task)
	{
		if (task->appointment != 0) {
			appointmentTasks.push_back(task);
			return;
		}

		tasks.push_back(task);
		sortTasksByPriority();
	}

	void FDExecutor::checkTimeout()
	{
		if (!currentTask) {
			return;
		}

		FDTime::duration_type duration = FDTime::time() - _currentFeedTime;
		if (duration > currentTask->timeout) {
			FDFireflyDeviceLogInfo("executor task timeout");
			std::map<std::string, std::string> userInfo{ { FDLocalizedDescriptionKey, "executor task timed out" } };
			fail(currentTask, FDError::error(FDExecutorErrorDomain, FDExecutorErrorCodeTimeout, userInfo));
		}
	}

	void FDExecutor::check()
	{
		checkTimeout();
		checkAppointments();
	}

	void FDExecutor::taskException(std::exception e)
	{
		FDFireflyDeviceLogWarn("task exception %s", e.what());
	}

	void FDExecutor::schedule()
	{
		if (!_run) {
			return;
		}

		if (currentTask) {
			if (tasks.size() == 0) {
				return;
			}
			std::shared_ptr<FDExecutorTask> task = tasks.front();
			if (currentTask->priority >= task->priority) {
				return;
			}
			std::shared_ptr<FDExecutorTask> saveCurrentTask = currentTask;
			currentTask.reset();
			saveCurrentTask->isSuspended = true;
			addTask(saveCurrentTask);
			try {
				saveCurrentTask->executorTaskSuspended(this);
			} catch (std::exception e) {
				taskException(e);
			}
		}
		if (tasks.size() == 0) {
			return;
		}

		currentTask = tasks.front();
		tasks.erase(tasks.begin());
		_currentFeedTime = FDTime::time();
		if (currentTask->isSuspended) {
			currentTask->isSuspended = false;
			try {
				currentTask->executorTaskResumed(this);
			} catch (std::exception e) {
				taskException(e);
			}
		} else {
			try {
				currentTask->executorTaskStarted(this);
			} catch (std::exception e) {
				taskException(e);
			}
		}
	}

	void FDExecutor::execute(std::shared_ptr<FDExecutorTask> task)
	{
		cancel(task);
		addTask(task);

		schedule();
	}

	void FDExecutor::feedWatchdog(std::shared_ptr<FDExecutorTask> task)
	{
		if (currentTask == task) {
			_currentFeedTime = FDTime::time();
		} else {
			FDFireflyDeviceLogWarn("expected current task to feed watchdog...");
		}
	}

	void FDExecutor::over(std::shared_ptr<FDExecutorTask> task, std::shared_ptr<FDError> error)
	{
		if (currentTask == task) {
			currentTask.reset();
			try {
				if (!error) {
					task->executorTaskCompleted(this);
				}
				else {
					task->executorTaskFailed(this, error);
				}
			} catch (std::exception e) {
				taskException(e);
			}
			schedule();
		} else {
			FDFireflyDeviceLogWarn("expected current task to be complete...");
		}
	}

	void FDExecutor::fail(std::shared_ptr<FDExecutorTask> task, std::shared_ptr<FDError> error)
	{
		over(task, error);
	}

	void FDExecutor::complete(std::shared_ptr<FDExecutorTask> task)
	{
		over(task, std::shared_ptr<FDError>());
	}

	void FDExecutor::cancel(std::shared_ptr<FDExecutorTask> task)
	{
		if (currentTask == task) {
			std::map<std::string, std::string> userInfo = { { FDLocalizedDescriptionKey, "executor task was canceled" } };
			fail(task, FDError::error(FDExecutorErrorDomain, FDExecutorErrorCodeCancel, userInfo));
		}
		tasks.remove(task);
		appointmentTasks.remove(task);
	}

	std::vector<std::shared_ptr<FDExecutorTask>> FDExecutor::allTasks()
	{
		std::vector<std::shared_ptr<FDExecutorTask>> allTasks;
		if (currentTask) {
			allTasks.push_back(currentTask);
		}
		allTasks.insert(allTasks.end(), tasks.begin(), tasks.end());
		allTasks.insert(allTasks.end(), appointmentTasks.begin(), appointmentTasks.end());
		return allTasks;
	}

	bool FDExecutor::hasTasks()
	{
		return currentTask || (tasks.size() > 0) || (appointmentTasks.size() > 0);
	}

}
