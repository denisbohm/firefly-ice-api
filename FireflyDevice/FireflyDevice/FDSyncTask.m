//
//  FDSyncTask.m
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
#import <FireflyDevice/FDSyncTask.h>

#define _log self.fireflyIce.log

@implementation FDSyncTaskUploadItem
@end

@interface FDSyncTaskItem : NSObject

@property NSString *hardwareId;
@property NSTimeInterval time;
@property NSTimeInterval interval;
@property NSArray *vmas;

@property NSData *responseData;

@end

@implementation FDSyncTaskItem
@end

@interface FDSyncTask () <FDSyncTaskUploadDelegate>

@property FDFireflyIceVersion *version;
@property NSString *site;
@property FDFireflyIceStorage *storage;
@property NSUInteger initialBacklog;
@property NSUInteger currentBacklog;
@property BOOL isSyncDataPending;
@property NSMutableArray *syncAheadItems;
@property NSArray *syncUploadItems;
@property BOOL isActive;
@property NSUInteger syncAheadLimit;
@property BOOL complete;

// Wait time between sync attempts.  Starts at minWait.  On error backs off linearly until maxWait.
// On success reverts to minWait.
@property NSTimeInterval wait;
@property NSTimeInterval minWait;
@property NSTimeInterval maxWait;

@end

@implementation FDSyncTask

@synthesize timeout = _timeout;
@synthesize priority = _priority;
@synthesize isSuspended = _isSuspended;
@synthesize appointment = _appointment;

+ (FDSyncTask *)syncTask:(NSString *)hardwareId fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel delegate:(id<FDSyncTaskDelegate>)delegate identifier:(NSString *)identifier
{
    FDSyncTask *syncTask = [[FDSyncTask alloc] init];
    syncTask.hardwareId = hardwareId;
    syncTask.fireflyIce = fireflyIce;
    syncTask.channel = channel;
    syncTask.delegate = delegate;
    syncTask.identifier = identifier;
    return syncTask;
}

- (id)init
{
    if (self = [super init]) {
        _priority = -50;
        _timeout = 60;
        _minWait = 60;
        _maxWait = 3600;
        _wait = _minWait;
        _syncAheadLimit = 8;
    }
    return self;
}

- (void)startSync
{
    NSUInteger limit = 1;
    if (_version.capabilities & FD_CONTROL_CAPABILITY_SYNC_AHEAD) {
        limit = _syncAheadLimit;
    }
    NSInteger pending = _syncAheadItems.count + _syncUploadItems.count;
    if (pending < limit) {
        if (!_isSyncDataPending) {
            FDFireflyDeviceLogInfo(@"requesting sync data with offset %u", pending);
            [_fireflyIce.coder sendSyncStart:_channel offset:(uint32_t)pending];
            _isSyncDataPending = YES;
        } else {
            FDFireflyDeviceLogInfo(@"waiting for pending sync data before starting new sync data request");
        }
    } else {
        FDFireflyDeviceLogInfo(@"waiting for upload complete to sync data with offset %u", pending);
    }
}

- (void)beginSync
{
    [_fireflyIce.coder sendGetProperties:_channel properties:FD_CONTROL_PROPERTY_SITE | FD_CONTROL_PROPERTY_STORAGE];
    _complete = NO;
    _syncAheadItems = [NSMutableArray array];
    _isSyncDataPending = NO;
    [self startSync];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel version:(FDFireflyIceVersion *)version
{
    _version = version;
    if (_version.capabilities & FD_CONTROL_CAPABILITY_LOCK) {
        [_fireflyIce.coder sendLock:_channel identifier:fd_lock_identifier_sync operation:fd_lock_operation_acquire];
    } else {
        [self beginSync];
    }
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel lock:(FDFireflyIceLock *)lock
{
    if ((lock.identifier == fd_lock_identifier_sync) && [_channel.name isEqualToString:lock.ownerName]) {
        [self beginSync];
    } else {
        FDFireflyDeviceLogInfo(@"sync could not acquire lock");
        [_fireflyIce.executor complete:self];
    }
}

- (void)activate:(FDExecutor *)executor
{
    _isActive = YES;
    [_fireflyIce.observable addObserver:self];
    
    if ([_delegate respondsToSelector:@selector(syncTaskActive:)]) {
        [_delegate syncTaskActive:self];
    }
    
    if (_upload.isConnectionOpen) {
        [executor complete:self];
    } else {
        [_fireflyIce.coder sendGetProperties:_channel properties:FD_CONTROL_PROPERTY_VERSION];
    }
}

- (void)deactivate:(FDExecutor *)executor
{
    if (_upload.isConnectionOpen) {
        [_upload cancel:[NSError errorWithDomain:FDSyncTaskErrorDomain code:FDSyncTaskErrorCodeCancelling userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"sync task deactivated: canceling upload", @"")}]];
    }
    
    _isActive = NO;
    [_fireflyIce.observable removeObserver:self];
    
    if ([_delegate respondsToSelector:@selector(syncTaskInactive:)]) {
        [_delegate syncTaskInactive:self];
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
    FDFireflyDeviceLogInfo(@"%@ task started", NSStringFromClass([self class]));
    [self activate:executor];
}

- (void)executorTaskSuspended:(FDExecutor *)executor
{
    FDFireflyDeviceLogInfo(@"%@ task suspended", NSStringFromClass([self class]));
    [self deactivate:executor];
}

- (void)executorTaskResumed:(FDExecutor *)executor
{
    FDFireflyDeviceLogInfo(@"%@ task resumed", NSStringFromClass([self class]));
    [self activate:executor];
}

- (void)executorTaskCompleted:(FDExecutor *)executor
{
    FDFireflyDeviceLogInfo(@"%@ task completed", NSStringFromClass([self class]));
    [self deactivate:executor];
    
    [self scheduleNextAppointment];
}

- (void)notifyError:(NSError *)error
{
    _error = error;
    if ([_delegate respondsToSelector:@selector(syncTask:error:)]) {
        [_delegate syncTask:self error:error];
    }
}

- (void)executorTaskFailed:(FDExecutor *)executor error:(NSError *)error
{
    FDFireflyDeviceLogInfo(@"%@ task failed with error %@", NSStringFromClass([self class]), error);
    
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
    FDFireflyDeviceLogInfo(@"device site %@", _site);
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel storage:(FDFireflyIceStorage *)storage
{
    _storage = storage;
    FDFireflyDeviceLogInfo(@"storage %@", _storage);
    _initialBacklog = _storage.pageCount;
    _currentBacklog = _storage.pageCount;
}

- (void)notifyProgress
{
    float progress = 1.0f;
    if (_initialBacklog > 0) {
        progress = (_initialBacklog - _currentBacklog) / (float)_initialBacklog;
    }
    FDFireflyDeviceLogInfo(@"sync task progress %f", progress);
    if ([_delegate respondsToSelector:@selector(syncTask:progress:)]) {
        [_delegate syncTask:self progress:progress];
    }
}

#define FD_STORAGE_TYPE(a, b, c, d) (a | (b << 8) | (c << 16) | (d << 24))

#define FD_LOG_TYPE FD_STORAGE_TYPE('F', 'D', 'L', 'O')
#define FD_VMA_TYPE FD_STORAGE_TYPE('F', 'D', 'V', 'M')
#define FD_VMA2_TYPE FD_STORAGE_TYPE('F', 'D', 'V', '2')

- (void)syncLog:(NSString *)hardwareId binary:(FDBinary *)binary
{
    NSTimeInterval time = [binary getTime64];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    NSString *date = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:time]];
    NSString *message = [[NSString alloc] initWithData:[binary getRemainingData] encoding:NSUTF8StringEncoding];
    FDFireflyDeviceLogInfo(@"device message %@ %@ %@", hardwareId, date, message);
}

- (NSArray *)getUploadItems
{
    NSMutableArray *uploadItems = [NSMutableArray array];
    for (FDSyncTaskItem *item in _syncAheadItems) {
        FDSyncTaskUploadItem *uploadItem = [[FDSyncTaskUploadItem alloc] init];
        uploadItem.hardwareId = item.hardwareId;
        uploadItem.time = item.time;
        uploadItem.interval = item.interval;
        uploadItem.vmas = item.vmas;
        [uploadItems addObject:uploadItem];
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

- (void)syncVMA:(NSString *)hardwareId binary:(FDBinary *)binary floatBytes:(NSUInteger)floatBytes responseData:(NSData *)responseData
{
    NSTimeInterval time = [binary getUInt32]; // 4-byte time
    uint16_t interval = [binary getUInt16];
    NSUInteger n = [binary getRemainingLength] / floatBytes; // 4 bytes == sizeof(float32)
    FDFireflyDeviceLogInfo(@"sync VMAs: %lu values", (unsigned long)n);
    NSMutableArray *vmas = [NSMutableArray array];
    for (NSUInteger i = 0; i < n; ++i) {
        float value = (floatBytes == 2) ? [binary getFloat16] : [binary getFloat32];
        [vmas addObject:[NSNumber numberWithFloat:value]];
    }
    
    NSDate *lastDataDate = [NSDate dateWithTimeIntervalSince1970:time + (n - 1) * interval];
    if ((_lastDataDate == nil) || ([lastDataDate compare:_lastDataDate] == NSOrderedDescending)) {
        _lastDataDate = lastDataDate;
    }
    
    FDSyncTaskItem *item = [[FDSyncTaskItem alloc] init];
    item.hardwareId = hardwareId;
    item.time = time;
    item.interval = interval;
    item.vmas = vmas;
    item.responseData = responseData;
    [_syncAheadItems addObject:item];
    
    if (_upload != nil) {
        [self checkUpload];
    } else {
        NSUInteger backlog = _currentBacklog;
        if (backlog > 0) {
            --backlog;
        }
        [_delegate syncTask:self site:_site hardwareId:hardwareId time:time interval:interval vmas:vmas backlog:backlog];
        
        [self getUploadItems];
        [self performSelectorOnMainThread:@selector(uploadComplete) withObject:nil waitUntilDone:NO];
    }
}

- (void)uploadComplete
{
    [self upload:nil complete:nil];
}


- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel detour:(FDDetour *)detour error:(NSError *)error
{
    [_fireflyIce.executor fail:self error:error];
}

- (void)onComplete
{
    if (_version.capabilities & FD_CONTROL_CAPABILITY_LOCK) {
        [_fireflyIce.coder sendLock:_channel identifier:fd_lock_identifier_sync operation:fd_lock_operation_release];
    }
    [_fireflyIce.executor complete:self];
    if ([_delegate respondsToSelector:@selector(syncTaskComplete:)]) {
        [_delegate syncTaskComplete:self];
    }
}

+ (NSString *)hardwareId:(NSData *)unique
{
    NSMutableString *hardwareId = [NSMutableString stringWithString:@"FireflyIce-"];
    uint8_t *bytes = (uint8_t *)unique.bytes;
    for (NSUInteger i = 0; i < unique.length; ++i) {
		uint8_t byte = bytes[i];
        [hardwareId appendFormat:@"%02X", byte];
	}
    return hardwareId;
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel syncData:(NSData *)data
{
    FDFireflyDeviceLogInfo(@"sync data for %@", _site);
    
    [_fireflyIce.executor feedWatchdog:self];
    
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    NSData *product __unused = [binary getData:8];
    NSData *unique = [binary getData:8];
    NSString *hardwareId = [FDSyncTask hardwareId:unique];
    uint32_t page = [binary getUInt32];
    uint16_t length = [binary getUInt16];
    uint16_t hash = [binary getUInt16];
    uint32_t type = [binary getUInt32];
    FDFireflyDeviceLogInfo(@"syncData: page=%u length=%u hash=0x%04x type=0x%08x", page, length, hash, type);
    
    // No sync data left? If so wait for uploads to complete or finish up now if there aren't any open uploads.
    if (page == 0xfffffffe) {
        _complete = YES;
        if (!_upload.isConnectionOpen) {
            [self onComplete];
        }
        return;
    }
    
    FDBinary *response = [[FDBinary alloc] init];
    [response putUInt8:FD_CONTROL_SYNC_ACK];
    [response putUInt32:page];
    [response putUInt16:length];
    [response putUInt16:hash];
    [response putUInt32:type];
    NSData *responseData = response.dataValue;
    
    switch (type) {
        case FD_VMA_TYPE:
        case FD_VMA2_TYPE:
            [self syncVMA:hardwareId binary:binary floatBytes:type == FD_VMA2_TYPE ? 2 : 4 responseData:responseData];
            // don't respond now.  need to wait for http post to complete before responding
            break;
        case FD_LOG_TYPE:
            [self syncLog:hardwareId binary:binary];
            [channel fireflyIceChannelSend:responseData];
            break;
        default:
            // !!! unknown type - ack to discard it so more records will be synced
            FDFireflyDeviceLogInfo(@"discarding record: unknown sync record type 0x%08x data %@", type, responseData);
            [channel fireflyIceChannelSend:responseData];
            break;
    }
    
    _isSyncDataPending = NO;
    [self startSync];
}

- (void)upload:(FDSyncTaskUpload *)upload complete:(NSError *)error
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
            for (FDSyncTaskItem *item in _syncUploadItems) {
                FDFireflyDeviceLogInfo(@"sending syncData response %@", item.responseData);
                [_channel fireflyIceChannelSend:item.responseData];
            }
            _syncUploadItems = nil;
            _error = nil;
            _wait = _minWait;
            
            if (_complete) {
                [self onComplete];
            } else {
                [self startSync];
            }
        } @catch (NSException *e) {
            // !!! channel could be closed when the upload finishes (a subsequent channel close will
            // stop all the running tasks)
            error = [NSError errorWithDomain:FDSyncTaskErrorDomain code:FDSyncTaskErrorCodeException userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"sync task exception", @""), @"com.zamzee.device.exception":e}];
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

