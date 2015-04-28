//
//  FDPullTask.m
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
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class FDPullTask extends FDExecutor.Task implements FDFireflyIceObserver, FDPullTaskUpload.Delegate {

    public static int FD_STORAGE_TYPE(char a, char b, char c, char d) {
        return ((a & 0xff) | ((b & 0xff) << 8) | ((c & 0xff) << 16) | ((d & 0xff) << 24));
    }

    public class Item {
        byte[] responseData;
        Object value;
    }

    public interface FDPullTaskDecoder {

        Object decode(int type, byte[] data, byte[] responseData);

    }

    public final static String FDPullTaskErrorDomain = "com.fireflydesign.device.FDPullTask";

    public enum FDPullTaskErrorCode {
        Cancelling,
        Exception,
        CouldNotAcquireLock
    }

    public interface FDPullTaskDelegate {

        // Called when the pull task becomes active.
        void pullTaskActive(FDPullTask pullTask);

        // Called when there is an error uploading.
        void pullTaskError(FDPullTask pullTask, FDError error);

        // Called when there is no uploader.
        void pullTaskItems(FDPullTask pullTask, List<Object> items);

        // Called after each successful upload.
        void pullTaskProgress(FDPullTask pullTask, float progress);

        // Called when all the data has been read from the device and sent to the upload service.
        void pullTaskComplete(FDPullTask pullTask);

        // Called when the pull task becomes inactive.
        void pullTaskInactive(FDPullTask pullTask);

    }

    public FDFireflyDeviceLog log;
    public String hardwareId;
    public FDFireflyIce fireflyIce;
    public FDFireflyIceChannel channel;
    public FDPullTaskDelegate delegate;
    public String identifier;
    public Map<String, FDPullTaskDecoder> decoderByType;
    public FDPullTaskUpload upload;
    public int pullAheadLimit;
    public int totalBytesReceived;

    public boolean reschedule;

    public int initialBacklog;
    public int currentBacklog;

    public FDError error;
    
    public FDTimerFactory timerFactory;

    public FDPullTask pullTask(String hardwareId, FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDPullTaskDelegate delegate, String identifier) {
        FDPullTask pullTask = new FDPullTask();
        pullTask.hardwareId = hardwareId;
        pullTask.fireflyIce = fireflyIce;
        pullTask.channel = channel;
        pullTask.delegate = delegate;
        pullTask.identifier = identifier;
        return pullTask;
    }

    FDFireflyIceVersion version;
    String site;
    FDFireflyIceStorage storage;
    boolean isSyncDataPending;
    List<Item> syncAheadItems;
    List<Item> syncUploadItems;
    int lastPage;
    boolean isActive;
    boolean complete;
    FDTimer timer;

// Wait time between pull attempts.  Starts at minWait.  On error backs off linearly until maxWait.
// On success reverts to minWait.
    double wait;
    double minWait;
    double maxWait;

    public FDPullTask() {
        priority = -50;
        timeout = 60;
        minWait = 60;
        maxWait = 3600;
        wait = minWait;
        pullAheadLimit = 8;
        decoderByType = new HashMap<String, FDPullTaskDecoder>();
    }

    void startTimer() {
        cancelTimer();
        timer = timerFactory.makeTimer(new FDTimer.Delegate() { public void timerFired() { timeout(); } }, 2.0 , FDTimer.Type.OneShot);
    }

    void timeout() {
        FDFireflyDeviceLogger.info(log, "timeout waiting for sync data response");
        resync();
    }

    void cancelTimer() {
        timer.setEnabled(false);
        timer = null;
    }

    void startSync() {
        int limit = 1;
        if ((version.capabilities & FDFireflyIceCoder.FD_CONTROL_CAPABILITY_SYNC_AHEAD) != 0) {
            limit = pullAheadLimit;
        }
        int pending = syncAheadItems.size() + syncUploadItems.size();
        if (pending < limit) {
            if (!isSyncDataPending) {
                FDFireflyDeviceLogger.info(log, "requesting sync data with offset %u", pending);
                fireflyIce.coder.sendSyncStart(channel, pending);
                startTimer();
                isSyncDataPending = true;
            } else {
                FDFireflyDeviceLogger.info(log, "waiting for pending sync data before starting new sync data request");
            }
        } else {
            FDFireflyDeviceLogger.info(log, "waiting for upload complete to sync data with offset %u", pending);
        }
    }

    void beginSync() {
        fireflyIce.coder.sendGetProperties(channel, FDFireflyIceCoder.FD_CONTROL_PROPERTY_SITE | FDFireflyIceCoder.FD_CONTROL_PROPERTY_STORAGE);
        complete = false;
        syncAheadItems = new ArrayList<Item>();
        isSyncDataPending = false;
        lastPage = 0xfffffff0; // 0xfffffffe == no more data, 0xffffffff == ram data, low numbers are actual page numbers
        startSync();
    }

    @Override
    public void fireflyIceVersion(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceVersion version) {
        this.version = version;
        if ((version.capabilities & FDFireflyIceCoder.FD_CONTROL_CAPABILITY_LOCK) != 0) {
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

    @Override
    public void fireflyIceReset(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceReset reset) {

    }

    @Override
    public void fireflyIceMode(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, int mode) {

    }

    @Override
    public void fireflyIceTxPower(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, int txPower) {

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

    @Override
    public void fireflyIceLock(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceLock lock) {
        if ((lock.identifier == FDFireflyIceLock.Identifier.Sync) && channel.getName().equals(lock.ownerName())) {
            beginSync();
        } else {
            FDFireflyDeviceLogger.info(log, FDString.format("sync could not acquire lock (owned by %s)", lock.ownerName()));
            Map<String, String> userInfo = new HashMap<String, String>();
            userInfo.put(FDError.FDLocalizedDescriptionKey, "sync task could not acquire lock");
            userInfo.put(FDError.FDLocalizedRecoveryOptionsErrorKey, "Make sure the device is only connected to by one client");
            userInfo.put("com.fireflydesign.device.detail", FDString.format("sync task could not acquire lock (owned by %s)", lock.ownerName()));
            fireflyIce.executor.fail(this, FDError.error(FDPullTaskErrorDomain, FDPullTaskErrorCode.CouldNotAcquireLock.ordinal(), userInfo));
        }
    }

    void activate(FDExecutor executor) {
        isActive = true;
        fireflyIce.observable.addObserver(this);

        if (delegate != null) {
            delegate.pullTaskActive(this);
        }

        if (upload.isConnectionOpen()) {
            executor.complete(this);
        } else {
            fireflyIce.coder.sendGetProperties(channel, FDFireflyIceCoder.FD_CONTROL_PROPERTY_VERSION);
        }
    }

    void deactivate(FDExecutor executor) {
        cancelTimer();

        if (upload.isConnectionOpen()) {
            upload.cancel(FDError.error(FDPullTaskErrorDomain, FDPullTaskErrorCode.Cancelling.ordinal(), "sync task deactivated: canceling upload"));
        }

        isActive = false;
        fireflyIce.observable.removeObserver(this);

        if (delegate != null) {
            delegate.pullTaskInactive(this);
        }
    }

    void scheduleNextAppointment() {
        FDExecutor executor = this.fireflyIce.executor;
        if (reschedule && executor.run) {
            appointment = FDTime.time() + wait;
            executor.execute(this);
        }
    }

    @Override
    public void executorTaskStarted(FDExecutor executor) {
        FDFireflyDeviceLogger.info(log, "%s task started", getClass().getName());
        activate(executor);
    }

    @Override
    public void executorTaskSuspended(FDExecutor executor) {
        FDFireflyDeviceLogger.info(log, "%s task suspended", getClass().getName());
        deactivate(executor);
    }

    @Override
    public void executorTaskResumed(FDExecutor executor) {
        FDFireflyDeviceLogger.info(log, "%s task resumed", getClass().getName());
        activate(executor);
    }

    @Override
    public void executorTaskCompleted(FDExecutor executor) {
        FDFireflyDeviceLogger.info(log, "%s task completed", getClass().getName());
        deactivate(executor);

        scheduleNextAppointment();
    }

    void notifyError(FDError error) {
        this.error = error;
        if (delegate != null) {
            delegate.pullTaskError(this, error);
        }
    }

    @Override
    public void executorTaskFailed(FDExecutor executor, FDError error) {
        FDFireflyDeviceLogger.info(log, "%s task failed with error %s", getClass().getName(), error);

        if (error.domain.equals("FDDetour") && (error.code == 0)) {
            // !!! flush out and start sync again...
        }

        notifyError(error);

        deactivate(executor);

        scheduleNextAppointment();
    }

    @Override
    public void fireflyIceSite(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, String site) {
        this.site = site;
        FDFireflyDeviceLogger.info(log, "device site %s", site);
    }

    @Override
    public void fireflyIceStorage(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceStorage storage) {
        this.storage = storage;
        FDFireflyDeviceLogger.info(log, "storage %s", storage);
        initialBacklog = storage.pageCount;
        currentBacklog = storage.pageCount;
    }

    void notifyProgress() {
        float progress = 1.0f;
        if (initialBacklog > 0) {
            progress = (initialBacklog - currentBacklog) / (float)initialBacklog;
        }
        FDFireflyDeviceLogger.info(log, "sync task progress %f", progress);
        if (delegate != null) {
            delegate.pullTaskProgress(this, progress);
        }
    }

    List<Object> getUploadItems() {
        List<Object> uploadItems = new ArrayList<Object>();
        for (Item item : syncAheadItems) {
            uploadItems.add(item.value);
        }
        syncUploadItems = syncAheadItems;
        syncAheadItems = new ArrayList<Item>();
        return uploadItems;
    }

    void checkUpload() {
        if (!upload.isConnectionOpen()) {
            int backlog = currentBacklog;
            if (backlog > syncAheadItems.size()) {
                backlog -= syncAheadItems.size();
            } else {
                backlog = 0;
            }
            List<Object> uploadItems = getUploadItems();
            upload.post(site, uploadItems, backlog);
            startSync();
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
    }

    @Override
    public void fireflyIcePing(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, byte[] data) {

    }

    void onComplete() {
        if ((version.capabilities & FDFireflyIceCoder.FD_CONTROL_CAPABILITY_LOCK) != 0) {
            fireflyIce.coder.sendLock(channel, FDFireflyIceLock.Identifier.Sync, FDFireflyIceLock.Operation.Release);
        }
        fireflyIce.executor.complete(this);
        if (delegate != null) {
            delegate.pullTaskComplete(this);
        }
    }

    void resync() {
        FDFireflyDeviceLogger.info(log, "initiating a resync");
        upload.cancel(null);
        syncAheadItems.clear();
        syncUploadItems = null;
        isSyncDataPending = false;
        lastPage = 0xfffffff0; // 0xfffffffe == no more data, 0xffffffff == ram data, low numbers are actual page numbers
        startSync();
    }

    void addSyncAheadItem(byte[] responseData, Object value) {
        Item item = new Item();
        item.responseData = responseData;
        item.value = value;
        syncAheadItems.add(item);

        if (upload != null) {
            checkUpload();
        } else {
            List<Object> uploadItems = getUploadItems();
            if (delegate != null) {
                delegate.pullTaskItems(this, uploadItems);
            }
            uploadComplete();
        }
    }

    @Override
    public void fireflyIceSync(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, byte[] data) {
        FDFireflyDeviceLogger.info(log, "sync data for %s", site);

        cancelTimer();
        fireflyIce.executor.feedWatchdog(this);

        totalBytesReceived += data.length;

        FDBinary binary = new FDBinary(data);
        List<Byte> product = binary.getData(8);
        List<Byte> unique = binary.getData(8);
        int page = binary.getUInt32();
        short length = binary.getUInt16();
        short hash = binary.getUInt16();
        int type = binary.getUInt32();
        FDFireflyDeviceLogger.info(log, "syncData: page=%08x length=%u hash=0x%04x type=0x%08x", page, length, hash, type);

        // No sync data left? If so wait for uploads to complete or finish up now if there aren't any open uploads.
        if (page == 0xfffffffe) {
            complete = true;
            if (!upload.isConnectionOpen()) {
                onComplete();
            }
            return;
        }

        // Note that page == 0xffffffff is used for the RAM buffer (data that hasn't been flushed out to EEPROM yet). -denis
        if ((page != 0xffffffff) && (lastPage == page)) {
            // got a repeat, a message must have been dropped...
            // need to resync to recover...
            resync();
            return;
        }
        lastPage = page;

        FDBinary response = new FDBinary();
        response.putUInt8(FDFireflyIceCoder.FD_CONTROL_SYNC_ACK);
        response.putUInt32(page);
        response.putUInt16(length);
        response.putUInt16(hash);
        response.putUInt32(type);
        byte[] responseData = FDBinary.toByteArray(response.dataValue());

        Integer typeKey = type;
        FDPullTaskDecoder decoder = decoderByType.get(typeKey);
        if (decoder != null) {
            try {
                Object value = decoder.decode(type, FDBinary.toByteArray(binary.getRemainingData()), responseData);
                if (value != null) {
                    addSyncAheadItem(responseData, value);
                }
            } catch (Exception e) {
                FDFireflyDeviceLogger.info(log, "discarding record: invalid sync record (%@) type 0x%08x data %@", e.getMessage(), type, responseData);
                channel.fireflyIceChannelSend(responseData);
            }
        } else {
            // !!! unknown type - ack to discard it so more records will be synced
            FDFireflyDeviceLogger.info(log, "discarding record: unknown sync record type 0x%08x data %@", type, responseData);
            channel.fireflyIceChannelSend(responseData);
        }

        isSyncDataPending = false;
        startSync();
    }

    @Override
    public void uploadComplete(FDPullTaskUpload upload, FDError error) {
        if (!isActive) {
            return;
        }

        if (error == null) {
            if (currentBacklog > syncUploadItems.size()) {
                currentBacklog -= syncUploadItems.size();
            } else {
                currentBacklog = 0;
            }
            notifyProgress();

            try {
                for (Item item : syncUploadItems) {
                    FDFireflyDeviceLogger.info(log, "sending syncData response %@ %@", item.value, item.responseData);
                    channel.fireflyIceChannelSend(item.responseData);
                }
                syncUploadItems = null;
                error = null;
                wait = minWait;

                if (complete) {
                    if (syncAheadItems.size() > 0) {
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
                error = FDError.error(FDPullTaskErrorDomain, FDPullTaskErrorCode.Exception.ordinal(), "sync task exception");
            }
        }
        if (error != null) {
            // back off
            wait += minWait;
            if (wait > maxWait) {
                wait = maxWait;
            }
            fireflyIce.executor.fail(this, error);

            notifyError(error);
        }
    }

}