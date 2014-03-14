//
//  FDHelloTask.m
//  FireflyDevice
//
//  Created by Denis Bohm on 10/6/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import "FDFireflyIceCoder.h"
#import "FDHelloTask.h"
#import "FDFireflyDeviceLogger.h"

#define _log self.fireflyIce.log

@interface FDHelloTask ()

@property NSTimeInterval maxOffset;

@property NSDate *time;
@property FDFireflyIceReset *reset;

@end

@implementation FDHelloTask

+ (FDHelloTask *)helloTask:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel delegate:(id<FDHelloTaskDelegate>)delegate
{
    FDHelloTask *helloTask = [[FDHelloTask alloc] init];
    helloTask.fireflyIce = fireflyIce;
    helloTask.channel = channel;
    helloTask.delegate = delegate;
    return helloTask;
}

- (id)init
{
    if (self = [super init]) {
        self.priority = 100;
        _maxOffset = 120;
    }
    return self;
}

- (void)executorTaskStarted:(FDExecutor *)executor
{
    [super executorTaskStarted:executor];
    
    [self.fireflyIce.coder sendGetProperties:self.channel properties:FD_CONTROL_PROPERTY_VERSION | FD_CONTROL_PROPERTY_HARDWARE_ID | FD_CONTROL_PROPERTY_RTC | FD_CONTROL_PROPERTY_RESET];
    [self next:@selector(checkVersion)];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel version:(FDFireflyIceVersion *)version
{
    fireflyIce.version = version;
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel bootVersion:(FDFireflyIceVersion *)bootVersion
{
    fireflyIce.bootVersion = bootVersion;
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel hardwareId:(FDFireflyIceHardwareId *)hardwareId
{
    fireflyIce.hardwareId = hardwareId;
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel time:(NSDate *)time
{
    _time = time;
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel reset:(FDFireflyIceReset *)reset
{
    _reset = reset;
}

- (void)checkVersion
{
    if ((self.fireflyIce.version == nil) || (self.fireflyIce.hardwareId == nil)) {
        NSString *description = NSLocalizedString(@"Incomplete information received on initial communication with the device", @"");
        FDFireflyDeviceLogInfo(description);
        [self.channel close];
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: description,
                                   NSLocalizedRecoveryOptionsErrorKey: NSLocalizedString(@"Make sure the device stays in close range", @"")
                                   };
        NSError *error = [NSError errorWithDomain:FDHelloTaskErrorDomain code:FDHelloTaskErrorCodeIncomplete userInfo:userInfo];
        [self.fireflyIce.executor fail:self error:error];
        return;
    }
    
    if (self.fireflyIce.version.capabilities & FD_CONTROL_CAPABILITY_BOOT_VERSION) {
        [self.fireflyIce.coder sendGetProperties:self.channel properties:FD_CONTROL_PROPERTY_BOOT_VERSION];
        [self next:@selector(checkTime)];
    } else {
        [self checkTime];
    }
}

- (void)setTime
{
    FDFireflyDeviceLogInfo(@"setting the time");
    [self.fireflyIce.coder sendSetPropertyTime:self.channel time:[NSDate date]];
}

- (void)checkTime
{
    FDFireflyDeviceLogInfo(@"hello (hardware %@) (firmware %@)", self.fireflyIce.hardwareId, self.fireflyIce.version);
    
    if (_time == nil) {
        FDFireflyDeviceLogInfo(@"time not set for hw %@ fw %@ (last reset %@)", self.fireflyIce.hardwareId, self.fireflyIce.version, _reset);
        [self setTime];
    } else {
        NSTimeInterval offset = [_time timeIntervalSinceDate:[NSDate date]];
        if (fabs(offset) > _maxOffset) {
            FDFireflyDeviceLogInfo(@"time is off by %0.3f seconds for hw %@ fw %@ (last reset %@)", offset, self.fireflyIce.hardwareId, self.fireflyIce.version, _reset);
            [self setTime];
        } else {
//            FDFireflyDeviceLogDebug(@"time is off by %0.3f seconds for hw %@ fw %@", offset, self.fireflyIce.hardwareId, self.fireflyIce.version);
        }
    }
    [self done];
}

- (void)executorTaskCompleted:(FDExecutor *)executor
{
    [super executorTaskCompleted:executor];
    [_delegate helloTaskSuccess:self];
}

- (void)executorTaskFailed:(FDExecutor *)executor error:(NSError *)error
{
    [super executorTaskFailed:executor error:error];
    [_delegate helloTask:self error:error];
}

@end
