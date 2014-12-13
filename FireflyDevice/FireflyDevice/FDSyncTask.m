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

@implementation FDSyncTaskAcc
@end

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

@interface FDSyncTask ()

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

// Wait time between sync attempts.  Starts at minWait.  On error backs off linearly until maxWait.
// On success reverts to minWait.
@property NSTimeInterval wait;
@property NSTimeInterval minWait;
@property NSTimeInterval maxWait;

@property NSDateFormatter *dateFormatter;

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
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
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
        limit = _syncAheadLimit;
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
        FDFireflyDeviceLogInfo(@"FD010704", [NSString stringWithFormat:@"sync could not acquire lock (owned by %@)", lock.ownerName]);
        [_fireflyIce.executor fail:self error:[NSError errorWithDomain:FDSyncTaskErrorDomain code:FDSyncTaskErrorCodeCouldNotAcquireLock userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:NSLocalizedString(@"sync task could not acquire lock (owned by %@)", @""), lock.ownerName]}]];
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
    [self cancelTimer];
    
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
    if ([_delegate respondsToSelector:@selector(syncTask:error:)]) {
        [_delegate syncTask:self error:error];
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
    if ([_delegate respondsToSelector:@selector(syncTask:progress:)]) {
        [_delegate syncTask:self progress:progress];
    }
}

#define FD_STORAGE_TYPE(a, b, c, d) (a | (b << 8) | (c << 16) | (d << 24))

#define FD_LOG_TYPE FD_STORAGE_TYPE('F', 'D', 'L', 'O')
#define FD_VMA_TYPE FD_STORAGE_TYPE('F', 'D', 'V', 'M')
#define FD_VMA2_TYPE FD_STORAGE_TYPE('F', 'D', 'V', '2')
#define FD_ACC_TYPE FD_STORAGE_TYPE('F', 'D', 'S', 'A')

- (void)syncLog:(NSString *)hardwareId binary:(FDBinary *)binary
{
    NSTimeInterval time = [binary getTime64];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    NSString *date = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:time]];
    NSString *message = [[NSString alloc] initWithData:[binary getRemainingData] encoding:NSUTF8StringEncoding];
    FDFireflyDeviceLogInfo(@"FD010713", @"device message %@ %@ %@", hardwareId, date, message);
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
    if ([binary getRemainingLength] < 6) {
        // invalid record
        FDFireflyDeviceLogWarn(@"FD010714", @"invalid VMA record");
        [_channel fireflyIceChannelSend:responseData];
        return;
    }
    NSTimeInterval time = [binary getUInt32]; // 4-byte time
    uint16_t interval = [binary getUInt16];
    NSUInteger n = [binary getRemainingLength] / floatBytes; // 4 bytes == sizeof(float32), 2 bytes == sizeof(float16)
    FDFireflyDeviceLogInfo(@"FD010715", @"sync VMAs: %lu values", (unsigned long)n);
    NSMutableArray *vmas = [NSMutableArray array];
    for (NSUInteger i = 0; i < n; ++i) {
        float value = (floatBytes == 2) ? [binary getFloat16] : [binary getFloat32];
        [vmas addObject:[NSNumber numberWithFloat:value]];
    }
    
    NSDate *start = [NSDate dateWithTimeIntervalSince1970:time + interval];
    NSDate *end = [NSDate dateWithTimeIntervalSince1970:time + interval + vmas.count * interval];
    FDFireflyDeviceLogInfo(@"FD010716", @"got syncData %@ - %@ %@", [_dateFormatter stringFromDate:start], [_dateFormatter stringFromDate:end], responseData);

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
        if ([_delegate respondsToSelector:@selector(syncTask:site:hardwareId:time:interval:vmas:backlog:)]) {
            [_delegate syncTask:self site:_site hardwareId:hardwareId time:time interval:interval vmas:vmas backlog:backlog];
        }
        
        [self getUploadItems];
        [self performSelectorOnMainThread:@selector(uploadComplete) withObject:nil waitUntilDone:NO];
    }
}

// 8G scale
#define SCALE 0.0001

- (void)syncAcc:(NSString *)hardwareId binary:(FDBinary *)binary
{
    if ([binary getRemainingLength] < 10) {
        // invalid record
        FDFireflyDeviceLogWarn(@"FD010717", @"invalid ACC record");
        return;
    }
    NSTimeInterval time = [binary getTime64];
    uint16_t interval = [binary getUInt16];
    NSUInteger n = [binary getRemainingLength] / 4;
    FDFireflyDeviceLogInfo(@"FD010718", @"sync ACC: %lu values", (unsigned long)n);
    NSMutableArray *accs = [NSMutableArray array];
    for (NSUInteger i = 0; i < n; ++i) {
        uint32_t xyz = [binary getUInt32];
        int16_t x10 = ((xyz >> 20) & 0x03ff) << 6;
        int16_t y10 = ((xyz >> 10) & 0x03ff) << 6;
        int16_t z10 = ((xyz >>  0) & 0x03ff) << 6;
        FDSyncTaskAcc *acc = [[FDSyncTaskAcc alloc] init];
        acc.x = x10 * SCALE;
        acc.y = y10 * SCALE;
        acc.z = z10 * SCALE;
        [accs addObject:acc];
    }
    if ([_delegate respondsToSelector:@selector(syncTask:site:hardwareId:time:interval:accs:backlog:)]) {
        [_delegate syncTask:self site:_site hardwareId:hardwareId time:time interval:interval accs:accs backlog:_currentBacklog];
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

- (void)resync
{
    NSLog(@"initiating a resync");
    [_upload cancel:nil];
    [_syncAheadItems removeAllObjects];
    _syncUploadItems = nil;
    _isSyncDataPending = NO;
    [self startSync];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel syncData:(NSData *)data
{
    FDFireflyDeviceLogInfo(@"FD010719", @"sync data for %@", _site);
    
    [self cancelTimer];
    [_fireflyIce.executor feedWatchdog:self];
    
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
    
    switch (type) {
        case FD_VMA_TYPE:
        case FD_VMA2_TYPE:
            [self syncVMA:_hardwareId binary:binary floatBytes:type == FD_VMA2_TYPE ? 2 : 4 responseData:responseData];
            // don't respond now.  need to wait for http post to complete before responding
            break;
        case FD_ACC_TYPE:
            [self syncAcc:_hardwareId binary:binary];
            [channel fireflyIceChannelSend:responseData];
            break;
        case FD_LOG_TYPE:
            [self syncLog:_hardwareId binary:binary];
            [channel fireflyIceChannelSend:responseData];
            break;
        default:
            // !!! unknown type - ack to discard it so more records will be synced
            FDFireflyDeviceLogInfo(@"FD010721", @"discarding record: unknown sync record type 0x%08x data %@", type, responseData);
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
                NSDate *start = [NSDate dateWithTimeIntervalSince1970:item.time + item.interval];
                NSDate *end = [NSDate dateWithTimeIntervalSince1970:item.time + item.interval + item.vmas.count * item.interval];
                FDFireflyDeviceLogInfo(@"FD010722", @"sending syncData response %@ - %@ %@", [_dateFormatter stringFromDate:start], [_dateFormatter stringFromDate:end], item.responseData);
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

