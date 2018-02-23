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

#import <FireflyDevice/FDBinary.h>
#import <FireflyDevice/FDFireflyDeviceLogger.h>
#import <FireflyDevice/FDFireflyIceCoder.h>
#import <FireflyDevice/FDPullTask.h>

#define _log self.fireflyIce.log

@interface FDPullTaskItem : NSObject

@property NSData *responseData;
@property id value;

@end

@implementation FDPullTaskItem
@end

@interface FDPullTask ()

@property FDFireflyIceVersion *version;
@property NSString *site;
@property FDFireflyIceStorage *storage;
@property NSUInteger initialBacklog;
@property NSUInteger currentBacklog;
@property BOOL isSyncDataPending;
@property NSMutableArray *syncAheadItems;
@property NSArray *syncUploadItems;
@property uint32_t lastPage;
@property BOOL isActive;
@property BOOL complete;
@property NSTimer *timer;

// Wait time between pull attempts.  Starts at minWait.  On error backs off linearly until maxWait.
// On success reverts to minWait.
@property NSTimeInterval wait;
@property NSTimeInterval minWait;
@property NSTimeInterval maxWait;

@end

@implementation FDPullTask

@synthesize timeout = _timeout;
@synthesize priority = _priority;
@synthesize isSuspended = _isSuspended;
@synthesize appointment = _appointment;

+ (FDPullTask *)pullTask:(NSString *)hardwareId fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel delegate:(id<FDPullTaskDelegate>)delegate identifier:(NSString *)identifier
{
    FDPullTask *pullTask = [[FDPullTask alloc] init];
    pullTask.hardwareId = hardwareId;
    pullTask.fireflyIce = fireflyIce;
    pullTask.channel = channel;
    pullTask.delegate = delegate;
    pullTask.identifier = identifier;
    return pullTask;
}

- (id)init
{
    if (self = [super init]) {
        _priority = -50;
        _timeout = 60;
        _minWait = 60;
        _maxWait = 3600;
        _wait = _minWait;
        _pullAheadLimit = 8;
        _decoderByType = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)startTimer
{
    [self cancelTimer];
    _timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
}

- (void)timerFired:(NSTimer *)timer
{
    NSLog(@"timeout waiting for sync data response");
    [self resync];
}

- (void)cancelTimer
{
    [_timer invalidate];
    _timer = nil;
}

- (void)startSync
{
    NSUInteger limit = 1;
    if (_version.capabilities & FD_CONTROL_CAPABILITY_SYNC_AHEAD) {
        limit = _pullAheadLimit;
    }
    NSInteger pending = _syncAheadItems.count + _syncUploadItems.count;
    if (pending < limit) {
        if (!_isSyncDataPending) {
            FDFireflyDeviceLogInfo(@"FD010701", @"requesting sync data with offset %u", pending);
            [_fireflyIce.coder sendSyncStart:_channel offset:(uint32_t)pending];
            [self startTimer];
            _isSyncDataPending = YES;
        } else {
            FDFireflyDeviceLogInfo(@"FD010702", @"waiting for pending sync data before starting new sync data request");
        }
    } else {
        FDFireflyDeviceLogInfo(@"FD010703", @"waiting for upload complete to sync data with offset %u", pending);
    }
}

- (void)beginSync
{
    [_fireflyIce.coder sendGetProperties:_channel properties:FD_CONTROL_PROPERTY_SITE | FD_CONTROL_PROPERTY_STORAGE];
    _complete = NO;
    _syncAheadItems = [NSMutableArray array];
    _isSyncDataPending = NO;
    _lastPage = 0xfffffff0; // 0xfffffffe == no more data, 0xffffffff == ram data, low numbers are actual page numbers
    [self startSync];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel version:(FDFireflyIceVersion *)version
{
    _version = version;
    if (_version.capabilities & FD_CONTROL_CAPABILITY_LOCK) {
        [_fireflyIce.coder sendLock:_channel identifier:FDLockIdentifierSync operation:FDLockOperationAcquire];
    } else {
        [self beginSync];
    }
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel lock:(FDFireflyIceLock *)lock
{
    if ((lock.identifier == FDLockIdentifierSync) && [_channel.name isEqualToString:lock.ownerName]) {
        [self beginSync];
    } else {
        FDFireflyDeviceLogInfo(@"FD010704", [NSString stringWithFormat:@"sync could not acquire lock (owned by %@)", lock.ownerName]);
        [_fireflyIce.executor fail:self error:[NSError errorWithDomain:FDPullTaskErrorDomain code:FDPullTaskErrorCodeCouldNotAcquireLock userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:NSLocalizedString(@"sync task could not acquire lock (owned by %@)", @""), lock.ownerName]}]];
    }
}

- (void)activate:(FDExecutor *)executor
{
    _isActive = YES;
    [_fireflyIce.observable addObserver:self];
    
    if ([_delegate respondsToSelector:@selector(pullTaskActive:)]) {
        [_delegate pullTaskActive:self];
    }
    
    if (_upload.isConnectionOpen) {
        [executor complete:self];
    } else {
        [_fireflyIce.coder sendGetProperties:_channel properties:FD_CONTROL_PROPERTY_VERSION];
    }
}

- (void)deactivate:(FDExecutor *)executor
{
    [self cancelTimer];
    
    if (_upload.isConnectionOpen) {
        [_upload cancel:[NSError errorWithDomain:FDPullTaskErrorDomain code:FDPullTaskErrorCodeCancelling userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"sync task deactivated: canceling upload", @"")}]];
    }
    
    _isActive = NO;
    [_fireflyIce.observable removeObserver:self];
    
    if ([_delegate respondsToSelector:@selector(pullTaskInactive:)]) {
        [_delegate pullTaskInactive:self];
    }
}

- (void)scheduleNextAppointment
{
    FDExecutor *executor = self.fireflyIce.executor;
    if (_reschedule && executor.run) {
        _appointment = [NSDate dateWithTimeIntervalSinceNow:_wait];
        [executor execute:self];
    }
}

- (void)executorTaskStarted:(FDExecutor *)executor
{
    FDFireflyDeviceLogInfo(@"FD010705", @"%@ task started", NSStringFromClass([self class]));
    [self activate:executor];
}

- (void)executorTaskSuspended:(FDExecutor *)executor
{
    FDFireflyDeviceLogInfo(@"FD010706", @"%@ task suspended", NSStringFromClass([self class]));
    [self deactivate:executor];
}

- (void)executorTaskResumed:(FDExecutor *)executor
{
    FDFireflyDeviceLogInfo(@"FD010707", @"%@ task resumed", NSStringFromClass([self class]));
    [self activate:executor];
}

- (void)executorTaskCompleted:(FDExecutor *)executor
{
    FDFireflyDeviceLogInfo(@"FD010708", @"%@ task completed", NSStringFromClass([self class]));
    [self deactivate:executor];
    
    [self scheduleNextAppointment];
}

- (void)notifyError:(NSError *)error
{
    _error = error;
    if ([_delegate respondsToSelector:@selector(pullTask:error:)]) {
        [_delegate pullTask:self error:error];
    }
}

- (void)executorTaskFailed:(FDExecutor *)executor error:(NSError *)error
{
    FDFireflyDeviceLogInfo(@"FD010709", @"%@ task failed with error %@", NSStringFromClass([self class]), error);
    
    if ([error.domain isEqualToString:@"FDDetour"] && error.code == 0) {
        // !!! flush out and start sync again...
    }
    
    [self notifyError:error];
    
    [self deactivate:executor];
    
    [self scheduleNextAppointment];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel site:(NSString *)site
{
    _site = site;
    FDFireflyDeviceLogInfo(@"FD010710", @"device site %@", _site);
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel storage:(FDFireflyIceStorage *)storage
{
    _storage = storage;
    FDFireflyDeviceLogInfo(@"FD010711", @"storage %@", _storage);
    _initialBacklog = _storage.pageCount;
    _currentBacklog = _storage.pageCount;
}

- (void)notifyProgress
{
    float progress = 1.0f;
    if (_initialBacklog > 0) {
        progress = (_initialBacklog - _currentBacklog) / (float)_initialBacklog;
    }
    FDFireflyDeviceLogInfo(@"FD010712", @"sync task progress %f", progress);
    if ([_delegate respondsToSelector:@selector(pullTask:progress:)]) {
        [_delegate pullTask:self progress:progress];
    }
}

- (NSArray *)getUploadItems
{
    NSMutableArray *uploadItems = [NSMutableArray array];
    for (FDPullTaskItem *item in _syncAheadItems) {
        [uploadItems addObject:item.value];
    }
    _syncUploadItems = _syncAheadItems;
    _syncAheadItems = [NSMutableArray array];
    return uploadItems;
}

- (void)checkUpload
{
    if (!_upload.isConnectionOpen) {
        NSUInteger backlog = _currentBacklog;
        if (backlog > _syncAheadItems.count) {
            backlog -= _syncAheadItems.count;
        } else {
            backlog = 0;
        }
        NSArray *uploadItems = [self getUploadItems];
        [_upload post:_site items:uploadItems backlog:backlog];
        [self startSync];
    }
}

- (void)uploadComplete
{
    [self uploadComplete:nil];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel detour:(FDDetour *)detour error:(NSError *)error
{
    [_fireflyIce.executor fail:self error:error];
}

- (void)onComplete
{
    if (_version.capabilities & FD_CONTROL_CAPABILITY_LOCK) {
        [_fireflyIce.coder sendLock:_channel identifier:FDLockIdentifierSync operation:FDLockOperationRelease];
    }
    [_fireflyIce.executor complete:self];
    if ([_delegate respondsToSelector:@selector(pullTaskComplete:)]) {
        [_delegate pullTaskComplete:self];
    }
}

- (void)resync
{
    NSLog(@"initiating a resync");
    [_upload cancel:nil];
    [_syncAheadItems removeAllObjects];
    _syncUploadItems = nil;
    _isSyncDataPending = NO;
    _lastPage = 0xfffffff0; // 0xfffffffe == no more data, 0xffffffff == ram data, low numbers are actual page numbers
    [self startSync];
}

- (void)addSyncAheadItem:(NSData *)responseData value:(id)value
{
    FDPullTaskItem *item = [[FDPullTaskItem alloc] init];
    item.responseData = responseData;
    item.value = value;
    [_syncAheadItems addObject:item];
    
    if (_upload != nil) {
        [self checkUpload];
    } else {
        NSArray *uploadItems = [self getUploadItems];
        if ([_delegate respondsToSelector:@selector(pullTask:items:)]) {
            [_delegate pullTask:self items:uploadItems];
        }
        [self performSelectorOnMainThread:@selector(uploadComplete) withObject:nil waitUntilDone:NO];
    }
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel syncData:(NSData *)data
{
    FDFireflyDeviceLogInfo(@"FD010719", @"sync data for %@", _site);
    
    [self cancelTimer];
    [_fireflyIce.executor feedWatchdog:self];
    
    self.totalBytesReceived += data.length;
    
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    NSData *product __unused = [binary getData:8];
    NSData *unique __unused = [binary getData:8];
    uint32_t page = [binary getUInt32];
    uint16_t length = [binary getUInt16];
    uint16_t hash = [binary getUInt16];
    uint32_t type = [binary getUInt32];
    FDFireflyDeviceLogInfo(@"FD010720", @"syncData: page=%08x length=%u hash=0x%04x type=0x%08x", page, length, hash, type);
    
    // No sync data left? If so wait for uploads to complete or finish up now if there aren't any open uploads.
    if (page == 0xfffffffe) {
        _complete = YES;
        if (!_upload.isConnectionOpen) {
            [self onComplete];
        }
        return;
    }
    
    // Note that page == 0xffffffff is used for the RAM buffer (data that hasn't been flushed out to EEPROM yet). -denis
    if ((page != 0xffffffff) && (_lastPage == page)) {
        // got a repeat, a message must have been dropped...
        // need to resync to recover...
        [self resync];
        return;
    }
    _lastPage = page;
    
    FDBinary *response = [[FDBinary alloc] init];
    [response putUInt8:FD_CONTROL_SYNC_ACK];
    [response putUInt32:page];
    [response putUInt16:length];
    [response putUInt16:hash];
    [response putUInt32:type];
    NSData *responseData = response.dataValue;
    
    NSNumber *typeKey = [NSNumber numberWithInt:type];
    id<FDPullTaskDecoder> decoder = _decoderByType[typeKey];
    if (decoder != nil) {
        @try {
            NSData *requestData = [binary getRemainingData];
            id value = [decoder decode:type data:requestData responseData:responseData];
            if (value != nil) {
                [self addSyncAheadItem:responseData value:value];
            }
        } @catch (NSException *e) {
            FDFireflyDeviceLogInfo(@"FD010721", @"discarding record: invalid sync record (%@) type 0x%08x data %@", e.description, type, data);
            [_channel fireflyIceChannelSend:responseData];
        }
    } else {
        // !!! unknown type - ack to discard it so more records will be synced
        FDFireflyDeviceLogInfo(@"FD010724", @"discarding record: unknown sync record type 0x%08x data %@", type, data);
        [channel fireflyIceChannelSend:responseData];
    }
    
    _isSyncDataPending = NO;
    [self startSync];
}

- (void)upload:(FDPullTaskUpload *)upload complete:(NSError *)error
{
    [self uploadComplete:error];
}

- (void)uploadComplete:(NSError *)error
{
    if (!_isActive) {
        return;
    }
    
    if (error == nil) {
        if (_currentBacklog > _syncUploadItems.count) {
            _currentBacklog -= _syncUploadItems.count;
        } else {
            _currentBacklog = 0;
        }
        [self notifyProgress];
        
        @try {
            for (FDPullTaskItem *item in _syncUploadItems) {
                FDFireflyDeviceLogInfo(@"FD010722", @"sending syncData response %@ %@", item.value, item.responseData);
                [_channel fireflyIceChannelSend:item.responseData];
            }
            _syncUploadItems = nil;
            _error = nil;
            _wait = _minWait;
            
            if (_complete) {
                if (_syncAheadItems.count > 0) {
                    [self checkUpload];
                } else {
                    [self onComplete];
                }
            } else {
                [self startSync];
            }
        } @catch (NSException *e) {
            // !!! channel could be closed when the upload finishes (a subsequent channel close will
            // stop all the running tasks)
            error = [NSError errorWithDomain:FDPullTaskErrorDomain code:FDPullTaskErrorCodeException userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"sync task exception", @""), @"com.fireflydesign.device.exception":e}];
        }
    }
    if (error != nil) {
        // back off
        _wait += _minWait;
        if (_wait > _maxWait) {
            _wait = _maxWait;
        }
        [_fireflyIce.executor fail:self error:error];
        
        [self notifyError:error];
    }
}

@end
