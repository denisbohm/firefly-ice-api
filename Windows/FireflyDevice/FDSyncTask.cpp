//
//  FDSyncTask.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 9/25/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

/*
 * Posting uploads is often much slower than getting upload data from a device.
 * So the procedure is to read data from the device and queue it up.  When the
 * uploader becomes available, all the queued up data is posted.  When the post
 * completes then the queued up syncs are all acked to the device.
 
 * The amount of look ahead when reading data from the device needs to be limited
 * so that we don't overflow sending back acks in a single transfer.
 */

#include "FDBinary.h"
#include "FDFireflyDeviceLogger.h"
#include "FDFireflyIceChannel.h"
#include "FDFireflyIceCoder.h"
#include "FDSyncTask.h"
#include "FDTime.h"

#include <sstream>
#include <string>

namespace fireflydesign {

	std::shared_ptr<FDSyncTask> FDSyncTask::syncTask(std::string hardwareId, std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::shared_ptr<FDSyncTaskDelegate> delegate, std::string identifier)
	{
		std::shared_ptr<FDSyncTask> syncTask = std::make_shared<FDSyncTask>();
		syncTask->hardwareId = hardwareId;
		syncTask->fireflyIce = fireflyIce;
		syncTask->channel = channel;
		syncTask->delegate = delegate;
		syncTask->identifier = identifier;
		return syncTask;
	}

	FDSyncTask::FDSyncTask() {
		priority = -50;
		timeout = 60;
		_minWait = 60;
		_maxWait = 3600;
		_wait = _minWait;
		_syncAheadLimit = 8;
	}

	void FDSyncTask::startSync()
	{
		int limit = 1;
		if (_version->capabilities & FD_CONTROL_CAPABILITY_SYNC_AHEAD) {
			limit = _syncAheadLimit;
		}
		int pending = _syncAheadItems.size() + _syncUploadItems.size();
		if (pending < limit) {
			if (!_isSyncDataPending) {
				FDFireflyDeviceLogInfo("requesting sync data with offset %u", pending);
				fireflyIce->coder->sendSyncStart(channel, pending);
				_isSyncDataPending = true;
			} else {
				FDFireflyDeviceLogInfo("waiting for pending sync data before starting new sync data request");
			}
		} else {
			FDFireflyDeviceLogInfo("waiting for upload complete to sync data with offset %u", pending);
		}
	}

	void FDSyncTask::beginSync()
	{
		fireflyIce->coder->sendGetProperties(channel, FD_CONTROL_PROPERTY_SITE | FD_CONTROL_PROPERTY_STORAGE);
		_complete = false;
		_syncAheadItems.clear();
		_isSyncDataPending = false;
		startSync();
	}

	void FDSyncTask::fireflyIceVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceVersion version)
	{
		_version = std::make_shared<FDFireflyIceVersion>(version);
		if (_version->capabilities & FD_CONTROL_CAPABILITY_LOCK) {
			fireflyIce->coder->sendLock(channel, fd_lock_identifier_sync, fd_lock_operation_acquire);
		} else {
			beginSync();
		}
	}

	void FDSyncTask::fireflyIceLock(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceLock lock)
	{
		if ((lock.identifier == fd_lock_identifier_sync) && (channel->getName().compare(lock.ownerName()) == 0)) {
			beginSync();
		} else {
			FDFireflyDeviceLogInfo("sync could not acquire lock");
			fireflyIce->executor->complete(shared_from_this());
		}
	}

	void FDSyncTask::activate(FDExecutor *executor)
	{
		_isActive = true;
		fireflyIce->observable.addObserver(shared_from_this());

		if (delegate) {
			delegate->syncTaskActive(this);
		}

		if (upload->isConnectionOpen) {
			executor->complete(shared_from_this());
		} else {
			fireflyIce->coder->sendGetProperties(channel, FD_CONTROL_PROPERTY_VERSION);
		}
	}

	void FDSyncTask::deactivate(FDExecutor *executor)
	{
		if (upload->isConnectionOpen) {
			upload->cancel(FDError::error(FDSyncTaskErrorDomain, FDSyncTaskErrorCodeCancelling, "sync task deactivated: canceling upload"));
		}

		_isActive = false;
		fireflyIce->observable.removeObserver(shared_from_this());

		if (delegate) {
			delegate->syncTaskInactive(this);
		}
	}

	void FDSyncTask::scheduleNextAppointment()
	{
		std::shared_ptr<FDExecutor> executor = fireflyIce->executor;
		if (reschedule && executor->getRun()) {
			appointment = FDTime::time() + _wait;
			executor->execute(shared_from_this());
		}
	}

	void FDSyncTask::executorTaskStarted(FDExecutor* executor)
	{
		FDFireflyDeviceLogInfo("task started");
		activate(executor);
	}

	void FDSyncTask::executorTaskSuspended(FDExecutor* executor)
	{
		FDFireflyDeviceLogInfo("task suspended");
		deactivate(executor);
	}

	void FDSyncTask::executorTaskResumed(FDExecutor* executor)
	{
		FDFireflyDeviceLogInfo("task resumed");
		activate(executor);
	}

	void FDSyncTask::executorTaskCompleted(FDExecutor* executor)
	{
		FDFireflyDeviceLogInfo("task completed");
		deactivate(executor);

		scheduleNextAppointment();
	}

	void FDSyncTask::notifyError(std::shared_ptr<FDError> error)
	{
		this->error = error;
		if (delegate) {
			delegate->syncTaskError(this, error);
		}
	}

	void FDSyncTask::executorTaskFailed(FDExecutor *executor, std::shared_ptr<FDError> error)
	{
		FDFireflyDeviceLogInfo("task failed with error %s", error->description());

		if ((error->domain.compare("FDDetour") == 0) && (error->code == 0)) {
			// !!! flush out and start sync again...
		}

		notifyError(error);

		deactivate(executor);

		scheduleNextAppointment();
	}

	void FDSyncTask::fireflyIceSite(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::string site)
	{
		_site = site;
		FDFireflyDeviceLogInfo("device site %s", _site);
	}

	void FDSyncTask::fireflyIceStorage(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel>channel, FDFireflyIceStorage storage)
	{
		_storage = std::make_shared<FDFireflyIceStorage>(storage);
		FDFireflyDeviceLogInfo("storage %s", _storage->description());
		_initialBacklog = _storage->pageCount;
		_currentBacklog = _storage->pageCount;
	}

	void FDSyncTask::notifyProgress()
	{
		float progress = 1.0f;
		if (_initialBacklog > 0) {
			progress = (_initialBacklog - _currentBacklog) / (float)_initialBacklog;
		}
		FDFireflyDeviceLogInfo("sync task progress %f", progress);
		if (delegate) {
			delegate->syncTaskProgress(this, progress);
		}
	}

#define FD_STORAGE_TYPE(a, b, c, d) (a | (b << 8) | (c << 16) | (d << 24))

#define FD_LOG_TYPE FD_STORAGE_TYPE('F', 'D', 'L', 'O')
#define FD_VMA_TYPE FD_STORAGE_TYPE('F', 'D', 'V', 'M')
#define FD_VMA2_TYPE FD_STORAGE_TYPE('F', 'D', 'V', '2')

	/*
	void FDSyncTask::syncLog(std::string hardwareId, FDBinary& binary)
	{
		time_type time = binary.getTime64();
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle : NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle : NSDateFormatterMediumStyle];
		NSString *date = [dateFormatter stringFromDate : [NSDate dateWithTimeIntervalSince1970 : time]];
		NSString *message = [[NSString alloc] initWithData:[binary getRemainingData] encoding : NSUTF8StringEncoding];
		FDFireflyDeviceLogInfo(@"device message %@ %@ %@", hardwareId, date, message);
	}
	*/

	std::vector<FDSyncTaskUploadItem> FDSyncTask::getUploadItems()
	{
		std::vector<FDSyncTaskUploadItem> uploadItems;
		for (FDSyncTaskItem item : _syncAheadItems) {
			FDSyncTaskUploadItem uploadItem;
			uploadItem.hardwareId = item.hardwareId;
			uploadItem.time = item.time;
			uploadItem.interval = item.interval;
			uploadItem.vmas = item.vmas;
			uploadItems.push_back(uploadItem);
		}
		_syncUploadItems = _syncAheadItems;
		_syncAheadItems.clear();
		return uploadItems;
	}

	void FDSyncTask::checkUpload()
	{
		if (!upload->isConnectionOpen) {
			int backlog = _currentBacklog;
			if (backlog > (int)_syncAheadItems.size()) {
				backlog -= _syncAheadItems.size();
			} else {
				backlog = 0;
			}
			std::vector<FDSyncTaskUploadItem> uploadItems = getUploadItems();
			upload->post(_site, uploadItems, backlog);
			startSync();
		}
	}

	void FDSyncTask::syncVMA(std::string hardwareId, FDBinary& binary, int floatBytes, std::vector<uint8_t> responseData)
	{
		time_type time = binary.getUInt32(); // 4-byte time
		uint16_t interval = binary.getUInt16();
		int n = binary.getRemainingLength() / floatBytes; // 4 bytes == sizeof(float32)
		FDFireflyDeviceLogInfo("sync VMAs: %d values", n);
		std::vector<double> vmas;
		for (int i = 0; i < n; ++i) {
			float value = (floatBytes == 2) ? binary.getFloat16() : binary.getFloat32();
			vmas.push_back(value);
		}

		time_type lastDataDate = time + (n - 1) * interval;
		if ((this->lastDataDate == 0) || (lastDataDate > this->lastDataDate)) {
			this->lastDataDate = lastDataDate;
		}

		FDSyncTaskItem item;
		item.hardwareId = hardwareId;
		item.time = time;
		item.interval = interval;
		item.vmas = vmas;
		item.responseData = responseData;
		_syncAheadItems.push_back(item);

		if (upload) {
			checkUpload();
		} else {
			int backlog = _currentBacklog;
			if (backlog > 0) {
				--backlog;
			}
			if (delegate) {
				delegate->syncTaskVMAs(this, _site, hardwareId, time, interval, vmas, backlog);
			}
			getUploadItems();
			uploadComplete();
		}
	}

	void FDSyncTask::uploadComplete()
	{
		uploadComplete(nullptr, nullptr);
	}

	void FDSyncTask::fireflyIceDetourError(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::shared_ptr<FDDetour> detour, std::shared_ptr<FDError> error)
	{
		fireflyIce->executor->fail(shared_from_this(), error);
	}

	void FDSyncTask::onComplete()
	{
		if (_version->capabilities & FD_CONTROL_CAPABILITY_LOCK) {
			fireflyIce->coder->sendLock(channel, fd_lock_identifier_sync, fd_lock_operation_release);
		}
		fireflyIce->executor->complete(shared_from_this());
		if (delegate) {
			delegate->syncTaskComplete(this);
		}
	}

	static std::string formatHardwareId(std::vector<uint8_t> unique)
	{
		std::ostringstream os;
		os << "FireflyIce-";
		for (uint8_t byte : unique) {
			os << std::hex << byte;
		}
		std::string hardwareId = os.str();
		return hardwareId;
	}

	void FDSyncTask::fireflyIceSync(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> data)
	{
		FDFireflyDeviceLogInfo("sync data for %s", _site);

		fireflyIce->executor->feedWatchdog(shared_from_this());

		FDBinary binary(data);
		std::vector<uint8_t> product = binary.getData(8);
		std::vector<uint8_t> unique = binary.getData(8);
		std::string hardwareId = formatHardwareId(unique);
		uint32_t page = binary.getUInt32();
		uint16_t length = binary.getUInt16();
		uint16_t hash = binary.getUInt16();
		uint32_t type = binary.getUInt32();
		FDFireflyDeviceLogInfo("syncData: page=%u length=%u hash=0x%04x type=0x%08x", page, length, hash, type);

		// No sync data left? If so wait for uploads to complete or finish up now if there aren't any open uploads.
		if (page == 0xfffffffe) {
			_complete = true;
			if (!upload->isConnectionOpen) {
				onComplete();
			}
			return;
		}

		FDBinary response;
		response.putUInt8(FD_CONTROL_SYNC_ACK);
		response.putUInt32(page);
		response.putUInt16(length);
		response.putUInt16(hash);
		response.putUInt32(type);
		std::vector<uint8_t> responseData = response.dataValue();

		switch (type) {
		case FD_VMA_TYPE:
		case FD_VMA2_TYPE:
			syncVMA(hardwareId, binary, type == FD_VMA2_TYPE ? 2 : 4, responseData);
			// don't respond now.  need to wait for http post to complete before responding
			break;
		case FD_LOG_TYPE:
			syncLog(hardwareId, binary);
			channel->fireflyIceChannelSend(responseData);
			break;
		default:
			// !!! unknown type - ack to discard it so more records will be synced
			FDFireflyDeviceLogInfo("discarding record: unknown sync record type 0x%08x data", type);
			channel->fireflyIceChannelSend(responseData);
			break;
		}

		_isSyncDataPending = false;
		startSync();
	}

	void FDSyncTask::uploadComplete(FDSyncTaskUpload* upload, std::shared_ptr<FDError> error)
	{
		if (!_isActive) {
			return;
		}

		if (error) {
			if (_currentBacklog > (int)_syncUploadItems.size()) {
				_currentBacklog -= _syncUploadItems.size();
			}
			else {
				_currentBacklog = 0;
			}
			notifyProgress();

			try {
				for (FDSyncTaskItem item : _syncUploadItems) {
					FDFireflyDeviceLogInfo("sending syncData response");
					channel->fireflyIceChannelSend(item.responseData);
				}
				_syncUploadItems.clear();
				error.reset();
				_wait = _minWait;

				if (_complete) {
					onComplete();
				} else {
					startSync();
				}
			} catch (std::exception e) {
				// !!! channel could be closed when the upload finishes (a subsequent channel close will
				// stop all the running tasks)
				error = FDError::error(FDSyncTaskErrorDomain, FDSyncTaskErrorCodeException, "sync task exception");
			}
		}
		if (error) {
			// back off
			_wait += _minWait;
			if (_wait > _maxWait) {
				_wait = _maxWait;
			}
			fireflyIce->executor->fail(shared_from_this(), error);

			notifyError(error);
		}
	}

}
