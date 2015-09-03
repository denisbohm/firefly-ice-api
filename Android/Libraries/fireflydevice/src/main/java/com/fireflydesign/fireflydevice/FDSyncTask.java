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

package com.fireflydesign.fireflydevice;

import java.util.ArrayList;
import java.util.List;

public class FDSyncTask extends FDExecutor.Task implements FDFireflyIceObserver {

    public static interface FDSyncTaskUploadDelegate {
        void uploadComplete(FDSyncTaskUpload upload, FDError error);
    }

    public static class FDSyncTaskUploadItem {
        public String hardwareId;
        public double time;
        public double interval;
        public double[] vmas;

        public byte[] responseData;
    }

    public static abstract class FDSyncTaskUpload {
        public FDSyncTaskUploadDelegate delegate;
        public boolean isConnectionOpen;
        public String site;

        public FDSyncTaskUpload() {
            isConnectionOpen = false;
        }

        public abstract void post(String site, FDSyncTaskUploadItem[] items, int backlog);
        public abstract void cancel(FDError error);
    }

    public final static String FDSyncTaskErrorDomain = "com.fireflydesign.device.FDSyncTask";

    public enum FDSyncTaskErrorCode {
        Cancelling,
        Exception
    }

    public interface FDSyncTaskDelegate {
        // Called when the sync task becomes active.
        void syncTaskActive(FDSyncTask syncTask);
    
        // Called if there is no upload object.
        void syncTaskVMAs(FDSyncTask syncTask, String site, String hardwareId, double time, double interval, double[] vmas, int backlog);
    
        // Called when there is an error uploading.
        void syncTaskError(FDSyncTask syncTask, FDError error);
    
        // Called after each successful upload.
        void syncTaskProgress(FDSyncTask syncTask, float progress);
    
        // Called when all the data has been read from the device and synced to the web service.
        void syncTaskComplete(FDSyncTask syncTask);
    
        // Called when the sync task becomes inactive.
        void syncTaskInactive(FDSyncTask syncTask);
    }

    public FDFireflyDeviceLog log;
    public String hardwareId;
    public FDFireflyIce fireflyIce;
    public FDFireflyIceChannel channel;
    public FDSyncTaskDelegate delegate;
    public String identifier;
    public FDSyncTaskUpload upload;
    public boolean reschedule;

    FDTimerFactory _timerFactory;
    FDFireflyIceVersion _version;
    String _site;
    FDFireflyIceStorage _storage;
    int _initialBacklog;
    int _currentBacklog;
    double _lastDataDate;
    FDError _error;
    boolean _isSyncDataPending;
    List<FDSyncTaskUploadItem> _syncAheadItems;
    List<FDSyncTaskUploadItem> _syncUploadItems;
    int _lastPage;
    boolean _isActive;
    int _syncAheadLimit;
    boolean _complete;
    FDTimer _timer;

    // Wait time between sync attempts.  Starts at minWait.  On error backs off linearly until maxWait.
    // On success reverts to minWait.
    double _wait;
    double _minWait;
    double _maxWait;

    public static FDSyncTask newSyncTask(String hardwareId, FDTimerFactory timerFactory, FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDSyncTaskDelegate delegate, String identifier) {
		FDSyncTask syncTask = new FDSyncTask();
		syncTask._timerFactory = timerFactory;
		syncTask.hardwareId = hardwareId;
		syncTask.fireflyIce = fireflyIce;
		syncTask.channel = channel;
		syncTask.delegate = delegate;
		syncTask.identifier = identifier;
		return syncTask;
	}

	public FDSyncTask() {
		priority = -50;
		timeout = 60;

		reschedule = false;

		_initialBacklog = 0;
		_currentBacklog = 0;
		_lastDataDate = 0;
		_isSyncDataPending = false;
		_lastPage = 0xfffffff0;
		_isActive = false;
		_syncAheadLimit = 1;
		_complete = false;

		_minWait = 60;
		_maxWait = 3600;
		_wait = _minWait;
	}

	public void dispose() {
		cancelTimer();
	}

	void startTimer() {
		cancelTimer();

		_timer = _timerFactory.makeTimer(
            new FDTimer.Delegate() {
                public void timerFired() {
                    timerFired();
                }
            },
            0.1,
            FDTimer.Type.OneShot
        );
		_timer.setEnabled(true);
	}

	void timerFired() {
		try {
			FDFireflyDeviceLogger.info(log, "FD010723", "timeout waiting for sync data response");
			resync();
		} catch (Exception e) {
			FDError error = FDError.error(FDSyncTaskErrorDomain, FDSyncTaskErrorCode.Exception.ordinal(), "sync task exception");
			fireflyIce.executor.fail(this, error);
			notifyError(error);
		}
	}

	void cancelTimer() {
		if (_timer != null) {
			_timer.setEnabled(false);
			_timer = null;
		}
	}

	int getInitialBacklog() {
		return _initialBacklog;
	}

	int getCurrentBacklog() {
		return _currentBacklog;
	}

	double getLastDataDate() {
		return _lastDataDate;
	}

	FDError getError() {
		return _error;
	}

	void startSync() {
		int limit = 1;
		if ((_version.capabilities & FDFireflyIceCoder.FD_CONTROL_CAPABILITY_SYNC_AHEAD) != 0) {
			limit = _syncAheadLimit;
		}
		int pending = _syncAheadItems.size() + _syncUploadItems.size();
		if (pending < limit) {
			if (!_isSyncDataPending) {
				FDFireflyDeviceLogger.info(log, "FD010701", "requesting sync data with offset %d", pending);
				fireflyIce.coder.sendSyncStart(channel, pending);
				startTimer();
				_isSyncDataPending = true;
			} else {
				FDFireflyDeviceLogger.info(log, "FD010702", "waiting for pending sync data before starting new sync data request");
			}
		} else {
			FDFireflyDeviceLogger.info(log, "FD010703", "waiting for upload complete to sync data with offset %d", pending);
		}
	}

	void beginSync() {
		fireflyIce.coder.sendGetProperties(channel, FDFireflyIceCoder.FD_CONTROL_PROPERTY_SITE | FDFireflyIceCoder.FD_CONTROL_PROPERTY_STORAGE);
		_complete = false;
		_syncAheadItems.clear();
		_isSyncDataPending = false;
		_lastPage = 0xfffffff0; // 0xfffffffe == no more data, 0xffffffff == ram data, low numbers are actual page numbers
		startSync();
	}

	public void fireflyIceVersion(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceVersion version) {
		_version = version;
		if ((_version.capabilities & FDFireflyIceCoder.FD_CONTROL_CAPABILITY_LOCK) != 0) {
			fireflyIce.coder.sendLock(channel, FDFireflyIceLock.Identifier.Sync, FDFireflyIceLock.Operation.Acquire);
		} else {
			beginSync();
		}
	}

    @Override
    public void fireflyIceHardwareId(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceHardwareId hardwareId) {

    }

    @Override
    public void fireflyIceBootVersion(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceVersion bootVersion) {

    }

    @Override
    public void fireflyIceDebugLock(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, boolean debugLock) {

    }

    @Override
    public void fireflyIceTime(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, double time) {

    }

    @Override
    public void fireflyIcePower(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIcePower power) {

    }

    public void fireflyIceLock(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceLock lock) {
		if ((lock.identifier == FDFireflyIceLock.Identifier.Sync) && channel.getName().equals(lock.ownerName())) {
			beginSync();
		} else {
			FDFireflyDeviceLogger.info(log, "FD010704", "sync could not acquire lock");
			fireflyIce.executor.complete(this);
		}
	}

    @Override
    public void fireflyIceLogging(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceLogging logging) {

    }

    @Override
    public void fireflyIceName(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, String name) {

    }

    @Override
    public void fireflyIceDiagnostics(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceDiagnostics diagnostics) {

    }

    @Override
    public void fireflyIceRetained(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceRetained retained) {

    }

    @Override
    public void fireflyIceDirectTestModeReport(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceDirectTestModeReport directTestModeReport) {

    }

    @Override
    public void fireflyIceExternalHash(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, byte[] externalHash) {

    }

    @Override
    public void fireflyIcePageData(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, byte[] pageData) {

    }

    @Override
    public void fireflyIceSectorHashes(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceSectorHash[] sectorHashes) {

    }

    @Override
    public void fireflyIceUpdateCommit(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceUpdateCommit updateCommit) {

    }

    @Override
    public void fireflyIceSensing(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceSensing sensing) {

    }

    void activate(FDExecutor executor) {
		_isActive = true;
		fireflyIce.observable.addObserver(this);

		if (delegate != null) {
			delegate.syncTaskActive(this);
		}

		if ((upload != null) && upload.isConnectionOpen) {
			executor.complete(this);
		} else {
			fireflyIce.coder.sendGetProperties(channel, FDFireflyIceCoder.FD_CONTROL_PROPERTY_VERSION);
		}
	}

	void deactivate(FDExecutor executor) {
		cancelTimer();

		if ((upload != null) && upload.isConnectionOpen) {
			upload.cancel(FDError.error(FDSyncTaskErrorDomain, FDSyncTaskErrorCode.Cancelling.ordinal(), "sync task deactivated: canceling upload"));
		}

		_isActive = false;
		fireflyIce.observable.removeObserver(this);

		if (delegate != null) {
			delegate.syncTaskInactive(this);
		}
	}

	void scheduleNextAppointment() {
		FDExecutor executor = fireflyIce.executor;
		if (reschedule && executor.getRun()) {
			appointment = FDTime.time() + _wait;
			executor.execute(this);
		}
	}

	public void executorTaskStarted(FDExecutor executor) {
		FDFireflyDeviceLogger.info(log, "FD010705", "task started");
		activate(executor);
	}

    public void executorTaskSuspended(FDExecutor executor) {
		FDFireflyDeviceLogger.info(log, "FD010706", "task suspended");
		deactivate(executor);
	}

    public void executorTaskResumed(FDExecutor executor) {
		FDFireflyDeviceLogger.info(log, "FD010707", "task resumed");
		activate(executor);
	}

    public void executorTaskCompleted(FDExecutor executor) {
		FDFireflyDeviceLogger.info(log, "FD010708", "task completed");
		deactivate(executor);

		scheduleNextAppointment();
	}

	void notifyError(FDError error) {
		_error = error;
		if (delegate != null) {
			delegate.syncTaskError(this, error);
		}
	}

	public void executorTaskFailed(FDExecutor executor, FDError error) {
		FDFireflyDeviceLogger.info(log, "FD010709", "task failed with error %s", error.description());

		if (error.domain.equals("FDDetour") && (error.code == 0)) {
			// !!! flush out and start sync again...
		}

		notifyError(error);

		deactivate(executor);

		scheduleNextAppointment();
	}

	public void fireflyIceSite(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, String site) {
		_site = site;
		FDFireflyDeviceLogger.info(log, "FD010710", "device site %s", _site);
	}

    @Override
    public void fireflyIceReset(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceReset reset) {

    }

    public void fireflyIceStorage(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceStorage storage) {
		_storage = storage;
		FDFireflyDeviceLogger.info(log, "FD010711", "storage %s", _storage.description());
		_initialBacklog = _storage.pageCount;
		_currentBacklog = _storage.pageCount;
	}

    @Override
    public void fireflyIceMode(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, int mode) {

    }

    @Override
    public void fireflyIceTxPower(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, int txPower) {

    }

    void notifyProgress() {
		float progress = 1.0f;
		if (_initialBacklog > 0) {
			progress = (_initialBacklog - _currentBacklog) / (float)_initialBacklog;
		}
		FDFireflyDeviceLogger.info(log, "FD010712", "sync task progress %f", progress);
		if (delegate != null) {
			delegate.syncTaskProgress(this, progress);
		}
	}

    static int FD_STORAGE_TYPE(char a, char b, char c, char d) {
        return (a | (b << 8) | (c << 16) | (d << 24));
    }

    final static int FD_LOG_TYPE = FD_STORAGE_TYPE('F', 'D', 'L', 'O');
    final static int FD_VMA_TYPE = FD_STORAGE_TYPE('F', 'D', 'V', 'M');
    final static int FD_VMA2_TYPE = FD_STORAGE_TYPE('F', 'D', 'V', '2');

	void syncLog(String hardwareId, FDBinary binary) {
		double time = binary.getTime64();
		String date = FDString.formatDateTime(time);
		byte[] bytes = binary.getRemainingDataArray();
		String message = FDBinary.toString(bytes);
		FDFireflyDeviceLogger.info(log, "FD010713", "device message %s %s %s", hardwareId, date, message);
	}

	List<FDSyncTaskUploadItem> getUploadItems() {
		List<FDSyncTaskUploadItem> uploadItems = new ArrayList<FDSyncTaskUploadItem>();
		for (FDSyncTaskUploadItem item : _syncAheadItems) {
			FDSyncTaskUploadItem uploadItem = new FDSyncTaskUploadItem();
			uploadItem.hardwareId = item.hardwareId;
			uploadItem.time = item.time;
			uploadItem.interval = item.interval;
			uploadItem.vmas = item.vmas;
			uploadItems.add(uploadItem);
		}
		_syncUploadItems = _syncAheadItems;
		_syncAheadItems.clear();
		return uploadItems;
	}

	void checkUpload() {
		if (!upload.isConnectionOpen) {
			int backlog = _currentBacklog;
			if (backlog > (int)_syncAheadItems.size()) {
				backlog -= _syncAheadItems.size();
			} else {
				backlog = 0;
			}
			List<FDSyncTaskUploadItem> uploadItems = getUploadItems();
			upload.post(_site, uploadItems.toArray(new FDSyncTaskUploadItem[0]), backlog);
			startSync();
		}
	}

	void syncVMA(String hardwareId, FDBinary binary, int floatBytes, byte[] responseData) {
		double time = binary.getUInt32(); // 4-byte time
		int interval = binary.getUInt16();
		int n = binary.getRemainingLength() / floatBytes; // 4 bytes == sizeof(float32)
		FDFireflyDeviceLogger.info(log, "FD010715", "sync VMAs: %d values", n);
		double[] vmas = new double[n];
		for (int i = 0; i < n; ++i) {
			double value = (floatBytes == 2) ? binary.getFloat16() : binary.getFloat32();
			vmas[i] = value;
		}

		double lastDataDate = time + (n - 1) * interval;
		if ((_lastDataDate == 0) || (lastDataDate > _lastDataDate)) {
			_lastDataDate = lastDataDate;
		}

		FDSyncTaskUploadItem item = new FDSyncTaskUploadItem();
		item.hardwareId = hardwareId;
		item.time = time;
		item.interval = interval;
		item.vmas = vmas;
		item.responseData = responseData;
		_syncAheadItems.add(item);

		if (upload != null) {
			checkUpload();
		} else {
			int backlog = _currentBacklog;
			if (backlog > 0) {
				--backlog;
			}
			if (delegate != null) {
				delegate.syncTaskVMAs(this, _site, hardwareId, time, interval, vmas, backlog);
			}
			getUploadItems();
			uploadComplete();
		}
	}

	void uploadComplete() {
		uploadComplete(null, null);
	}

    @Override
    public void fireflyIceStatus(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceChannel.Status status) {

    }

    public void fireflyIceDetourError(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDDetour detour, FDError error) {
		fireflyIce.executor.fail(this, error);
		notifyError(error);
	}

    @Override
    public void fireflyIcePing(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, byte[] data) {

    }

    void onComplete() {
		if ((_version.capabilities & FDFireflyIceCoder.FD_CONTROL_CAPABILITY_LOCK) != 0) {
			fireflyIce.coder.sendLock(channel, FDFireflyIceLock.Identifier.Sync, FDFireflyIceLock.Operation.Release);
		}
		fireflyIce.executor.complete(this);
		if (delegate != null) {
			delegate.syncTaskComplete(this);
		}
	}

	void resync() {
		if (upload != null) {
			FDError error = null;
			upload.cancel(error);
		}
		_syncAheadItems.clear();
		_syncUploadItems.clear();
		_isSyncDataPending = false;
		startSync();
	}

	public void fireflyIceSync(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, byte[] data) {
		FDFireflyDeviceLogger.info(log, "FD010724", "sync data for %s", _site);

		fireflyIce.executor.feedWatchdog(this);

		FDBinary binary = new FDBinary(data);
		byte[] product = binary.getDataArray(8);
		byte[] unique = binary.getDataArray(8);
		int page = binary.getUInt32();
		short length = binary.getUInt16();
		short hash = binary.getUInt16();
		int type = binary.getUInt32();
		FDFireflyDeviceLogger.info(log, "FD010716", "syncData: page=%d length=%d hash=0x%04x type=0x%08x", page, length, hash, type);

		// No sync data left? If so wait for uploads to complete or finish up now if there aren't any open uploads.
		if (page == 0xfffffffe) {
			_complete = true;
			if (!((upload != null) && upload.isConnectionOpen)) {
				onComplete();
			}
			return;
		}

		// Note that page == 0xffffffff is used for the RAM buffer (data that hasn't been flushed out to EEPROM yet). -denis
		if ((page != 0xffffffff) && (_lastPage == page)) {
			// got a repeat, a message must have been dropped...
			// need to resync to recover...
			resync();
			return;
		}
		_lastPage = page;

		FDBinary response = new FDBinary();
		response.putUInt8(FDFireflyIceCoder.FD_CONTROL_SYNC_ACK);
		response.putUInt32(page);
		response.putUInt16(length);
		response.putUInt16(hash);
		response.putUInt32(type);
		byte[] responseData = FDBinary.toByteArray(response.dataValue());

		if ((type == FD_VMA_TYPE) || (type == FD_VMA2_TYPE)) {
            syncVMA(hardwareId, binary, type == FD_VMA2_TYPE ? 2 : 4, responseData);
            // don't respond now.  need to wait for http post to complete before responding
        } else
		if (type == FD_LOG_TYPE) {
            syncLog(hardwareId, binary);
            channel.fireflyIceChannelSend(responseData);
        } else {
			// !!! unknown type - ack to discard it so more records will be synced
			FDFireflyDeviceLogger.info(log, "FD010721", "discarding record: unknown sync record type 0x%08x data", type);
			channel.fireflyIceChannelSend(responseData);
		}

		_isSyncDataPending = false;
		startSync();
	}

	void uploadComplete(FDSyncTaskUpload upload, FDError error) {
		if (!_isActive) {
			return;
		}

		if (error == null) {
			if (_currentBacklog > (int)_syncUploadItems.size()) {
				_currentBacklog -= _syncUploadItems.size();
			}
			else {
				_currentBacklog = 0;
			}
			notifyProgress();

			try {
				for (FDSyncTaskUploadItem item : _syncUploadItems) {
					FDFireflyDeviceLogger.info(log, "FD010722", "sending syncData response");
					channel.fireflyIceChannelSend(item.responseData);
				}
				_syncUploadItems.clear();
				error = null;
				_wait = _minWait;

				if (_complete) {
					if (_syncAheadItems.size() > 0) {
						checkUpload();
					} else {
						onComplete();
					}
				} else {
					startSync();
				}
			} catch (Exception e) {
				// !!! channel could be closed when the upload finishes (a subsequent channel close will
				// stop all the running tasks)
				error = FDError.error(FDSyncTaskErrorDomain, FDSyncTaskErrorCode.Exception.ordinal(), "sync task exception");
			}
		}
		if (error != null) {
			// back off
			_wait += _minWait;
			if (_wait > _maxWait) {
				_wait = _maxWait;
			}
			fireflyIce.executor.fail(this, error);
			notifyError(error);
		}
	}

}
