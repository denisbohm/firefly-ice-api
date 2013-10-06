//
//  ZZSyncTask.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/28/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "ZZHardwareId.h"
#import "ZZSyncTask.h"
#import "ZZUpload.h"

#import <FireflyDevice/FDBinary.h>
#import <FireflyDevice/FDFireflyIceCoder.h>

@interface ZZSyncTask () <ZZUploadDelegate>

@property ZZUpload *upload;
@property NSString *site;
@property FDFireflyIceStorage *storage;
@property NSData *responseData;
@property BOOL isActive;
@property NSTimeInterval wait;
@property NSTimeInterval minWait;
@property NSTimeInterval maxWait;

@end

@implementation ZZSyncTask

@synthesize timeout = _timeout;
@synthesize priority = _priority;
@synthesize isSuspended = _isSuspended;
@synthesize appointment = _appointment;

+ (ZZSyncTask *)syncTask:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel
{
    ZZSyncTask *syncTask = [[ZZSyncTask alloc] init];
    syncTask.fireflyIce = fireflyIce;
    syncTask.channel = channel;
    return syncTask;
}

- (id)init
{
    if (self = [super init]) {
        _timeout = 60;
        _minWait = 60;
        _maxWait = 60 * 60;
        _wait = _minWait;
    }
    return self;
}

- (void)startSync
{
    [_fireflyIce.coder sendGetProperties:_channel properties:FD_CONTROL_PROPERTY_SITE | FD_CONTROL_PROPERTY_STORAGE];
    [_fireflyIce.coder sendSyncStart:_channel];
}

- (void)activate:(FDExecutor *)executor
{
    NSLog(@"sync task activated");
    _isActive = YES;
    [_fireflyIce.observable addObserver:self];
    
    if (_upload.isConnectionOpen) {
        [executor complete:self];
    } else {
        [self startSync];
    }
}

- (void)deactivate:(FDExecutor *)executor
{
    NSLog(@"sync task deactivated");
    _isActive = NO;
    [_fireflyIce.observable removeObserver:self];
}

- (void)executorTaskStarted:(FDExecutor *)executor
{
    [self activate:executor];
}

- (void)executorTaskSuspended:(FDExecutor *)executor
{
    [self deactivate:executor];
}

- (void)executorTaskResumed:(FDExecutor *)executor
{
    [self activate:executor];
}

- (void)executorTaskCompleted:(FDExecutor *)executor
{
    [self deactivate:executor];
    
    if (executor.run) {
        _appointment = [NSDate dateWithTimeIntervalSinceNow:_wait];
        [executor execute:self];
    }
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel site:(NSString *)site
{
    _site = site;
    NSLog(@"device site %@", _site);
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel storage:(FDFireflyIceStorage *)storage
{
    _storage = storage;
    NSLog(@"storage %@", _storage);
}

+ (NSString*)uuid
{
    CFUUIDRef puuid = CFUUIDCreate(nil);
    CFStringRef uuidString = CFUUIDCreateString(nil, puuid);
    NSString *result = (__bridge_transfer NSString *)CFStringCreateCopy(NULL, uuidString);
    CFRelease(puuid);
    CFRelease(uuidString);
    return result;
}

- (void)configureUpload
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [userDefaults stringForKey:@"ZZUploadUUID"];
    if (uuid == nil) {
        uuid = [NSString stringWithFormat:@"ZZUpload-3.0-%@", [ZZSyncTask uuid]];
        [userDefaults setObject:uuid forKey:@"ZZUploadUUID"];
        [userDefaults synchronize];
    }

    _upload = [[ZZUpload alloc] init];
    _upload.uuid = uuid;
    _upload.delegate = self;
}

#define FD_STORAGE_TYPE(a, b, c, d) (a | (b << 8) | (c << 16) | (d << 24))

#define FD_LOG_TYPE FD_STORAGE_TYPE('F', 'D', 'L', 'O')
#define FD_VMA_TYPE FD_STORAGE_TYPE('F', 'D', 'V', 'M')

- (void)syncLog:(NSString *)hardwareId binary:(FDBinary *)binary
{
    NSTimeInterval time = [binary getTime64];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    NSString *date = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:time]];
    NSString *message = [[NSString alloc] initWithData:[binary getRemainingData] encoding:NSUTF8StringEncoding];
    NSLog(@"device message %@ %@ %@", hardwareId, date, message);
}

- (void)syncVMA:(NSString *)hardwareId binary:(FDBinary *)binary
{
    NSTimeInterval time = [binary getTime64];
    uint16_t interval = [binary getUInt16];
    NSUInteger n = [binary getRemainingLength] / 4; //  4 == sizeof(float32)
    NSMutableArray *vmas = [NSMutableArray array];
    for (NSUInteger i = 0; i < n; ++i) {
        float value = [binary getFloat32];
        [vmas addObject:[NSNumber numberWithFloat:value]];
    }
    NSUInteger backlog = _storage.pageCount;
    if (backlog > 0) {
        --backlog;
    }
    [_upload post:_site hardwareId:hardwareId time:time interval:interval vmas:vmas backlog:backlog];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel syncData:(NSData *)data
{
    NSLog(@"sync data for %@", _site);
    if (_upload == nil) {
        [self configureUpload];
    }
    
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    NSData *product __unused = [binary getData:8];
    NSData *unique = [binary getData:8];
    NSString *hardwareId = [ZZHardwareId hardwareId:unique];
    uint32_t page = [binary getUInt32];
    uint16_t length = [binary getUInt16];
    uint16_t hash = [binary getUInt16];
    uint32_t type = [binary getUInt32];
    
    if (page == 0xfffffffe) {
        // nothing to sync
        [fireflyIce.executor complete:self];
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
            if (!_upload.isConnectionOpen) {
                [self syncVMA:hardwareId binary:binary];
                _responseData = responseData;
            }
            // need to wait for http post to complete before responding
            return;
        case FD_LOG_TYPE:
            [self syncLog:hardwareId binary:binary];
            break;
        default:
            // !!! unknown type - ack it so more records will be synced
            break;
    }

    [channel fireflyIceChannelSend:responseData];
    [self startSync];
}

- (void)upload:(ZZUpload *)upload complete:(NSError *)error
{
    if (!_isActive) {
        return;
    }
    
    if (error == nil) {
        [_channel fireflyIceChannelSend:_responseData];
        _wait = _minWait;
        [self startSync];
    } else {
        // back off
        _wait *= 2;
        if (_wait > _maxWait) {
            _wait = _maxWait;
        }
        [_fireflyIce.executor complete:self];
    }
}

@end
