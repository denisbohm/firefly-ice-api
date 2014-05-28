//
//  FDSyncTask.h
//  FireflyDevice
//
//  Created by Denis Bohm on 9/25/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDSYNCTASK_H
#define FDSYNCTASK_H

#include "FDCommon.h"

#include "FDExecutor.h"
#include "FDFireflyIce.h"
#include "FDTimer.h"

namespace FireflyDesign {

	class FDSyncTaskUpload;

	class FDSyncTaskUploadDelegate {
	public:
		virtual ~FDSyncTaskUploadDelegate() {}

		virtual void uploadComplete(FDSyncTaskUpload* upload, std::shared_ptr<FDError> error) {}
	};

	class FDSyncTaskUploadItem {
	public:
		typedef double time_type;
		typedef double duration_type;

		std::string hardwareId;
		time_type time;
		duration_type interval;
		std::vector<double> vmas;

		std::vector<uint8_t> responseData;
	};
#define FDSyncTaskItem FDSyncTaskUploadItem

	class FDSyncTaskUpload {
	public:
		FDSyncTaskUpload();
		virtual ~FDSyncTaskUpload();

		std::shared_ptr<FDSyncTaskUploadDelegate> delegate;
		bool isConnectionOpen;
		std::string site;

		virtual void post(std::string site, std::vector<FDSyncTaskUploadItem> items, int backlog) = 0;
		virtual void cancel(std::shared_ptr<FDError> error) = 0;
	};

	/*
	class FDSyncTaskItem {
	public:
		typedef double time_type;
		typedef double duration_type;

		std::string hardwareId;
		time_type time;
		duration_type interval;
		std::vector<double> vmas;

		std::vector<uint8_t> responseData;
	};
	*/

#define FDSyncTaskErrorDomain "com.fireflydesign.device.FDSyncTask"

	enum {
		FDSyncTaskErrorCodeCancelling,
		FDSyncTaskErrorCodeException
	};

	class FDSyncTask;
	class FDSyncTaskUpload;

	class FDSyncTaskDelegate {
	public:
		typedef double time_type;
		typedef double duration_type;

		// Called when the sync task becomes active.
		virtual void syncTaskActive(FDSyncTask *syncTask) {}

		// Called if there is no upload object.
		virtual void syncTaskVMAs(FDSyncTask *syncTask, std::string site, std::string hardwareId, time_type time, duration_type interval, std::vector<double> vmas, int backlog) {}

		// Called when there is an error uploading.
		virtual void syncTaskError(FDSyncTask *syncTask, std::shared_ptr<FDError> error) {}

		// Called after each successful upload.
		virtual void syncTaskProgress(FDSyncTask *syncTask, float progress) {}

		// Called when all the data has been read from the device and synced to the web service.
		virtual void syncTaskComplete(FDSyncTask *syncTask) {}

		// Called when the sync task becomes inactive.
		virtual void syncTaskInactive(FDSyncTask *syncTask) {}
	};

	class FDSyncTask : public FDExecutorTask, public FDFireflyIceObserver, public FDSyncTaskUploadDelegate, public std::enable_shared_from_this<FDSyncTask> {
	public:
		FDSyncTask();
		virtual ~FDSyncTask();

		static std::shared_ptr<FDSyncTask> syncTask(std::string hardwareId, std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::shared_ptr<FDSyncTaskDelegate> delegate, std::string identifier);

		std::shared_ptr<FDFireflyDeviceLog> log;

		std::string hardwareId;
		std::shared_ptr<FDFireflyIce> fireflyIce;
		std::shared_ptr<FDFireflyIceChannel> channel;
		std::shared_ptr<FDSyncTaskDelegate> delegate;
		std::string identifier;
		std::shared_ptr<FDSyncTaskUpload> upload;
		bool reschedule;

		int getInitialBacklog();
		int getCurrentBacklog();

		time_type getLastDataDate();
		std::shared_ptr<FDError> getError();

	public:
		virtual void fireflyIceVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceVersion version);
		virtual void fireflyIceLock(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceLock lock);
		virtual void fireflyIceSite(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::string site);
		virtual void fireflyIceStorage(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel>channel, FDFireflyIceStorage storage);
		virtual void fireflyIceDetourError(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::shared_ptr<FDDetour> detour, std::shared_ptr<FDError> error);
		virtual void fireflyIceSync(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> syncData);

	public:
		virtual void executorTaskStarted(FDExecutor *executor);
		virtual void executorTaskSuspended(FDExecutor *executor);
		virtual void executorTaskResumed(FDExecutor *executor);
		virtual void executorTaskCompleted(FDExecutor *executor);
		virtual void executorTaskFailed(FDExecutor *executor, std::shared_ptr<FDError> error);

	private:
		typedef double duration_type;

		void startSync();
		void beginSync();
		void scheduleNextAppointment();
		void notifyProgress();
		void activate(FDExecutor *executor);
		void deactivate(FDExecutor *executor);
		void notifyError(std::shared_ptr<FDError> error);
		void syncLog(std::string hardwareId, FDBinary& binary);
		std::vector<FDSyncTaskUploadItem> getUploadItems();
		void checkUpload();
		void uploadComplete();
		void uploadComplete(FDSyncTaskUpload* upload, std::shared_ptr<FDError> error);
		void onComplete();
		void syncVMA(std::string hardwareId, FDBinary& binary, int floatBytes, std::vector<uint8_t> responseData);
		void resync();
		void startTimer();
		void timerFired();
		void cancelTimer();

		std::shared_ptr<FDFireflyIceVersion> _version;
		std::string _site;
		std::shared_ptr<FDFireflyIceStorage> _storage;
		int _initialBacklog;
		int _currentBacklog;
		time_type _lastDataDate;
		std::shared_ptr<FDError> _error;
		bool _isSyncDataPending;
		std::vector<FDSyncTaskItem> _syncAheadItems;
		std::vector<FDSyncTaskUploadItem> _syncUploadItems;
		uint32_t _lastPage;
		bool _isActive;
		int _syncAheadLimit;
		bool _complete;
		std::shared_ptr<FDTimer> _timer;

		// Wait time between sync attempts.  Starts at minWait.  On error backs off linearly until maxWait.
		// On success reverts to minWait.
		duration_type _wait;
		duration_type _minWait;
		duration_type _maxWait;
	};

}

#endif