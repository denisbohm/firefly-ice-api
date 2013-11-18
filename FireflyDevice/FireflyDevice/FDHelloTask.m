//
//  FDHelloTask.m
//  FireflyDevice
//
//  Created by Denis Bohm on 10/6/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIceCoder.h"
#import "FDHelloTask.h"

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
        NSLog(@"version or hardware id not received - closing connection");
        [self.channel close];
        [self done];
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
    NSLog(@"setting the time");
    [self.fireflyIce.coder sendSetPropertyTime:self.channel time:[NSDate date]];
}

- (void)checkTime
{
    NSLog(@"hello (hardware %@) (firmware %@)", self.fireflyIce.hardwareId, self.fireflyIce.version);
    
    if (_time == nil) {
        NSLog(@"time not set for hw %@ fw %@ (last reset %@)", self.fireflyIce.hardwareId, self.fireflyIce.version, _reset);
        [self setTime];
    } else {
        NSTimeInterval offset = [_time timeIntervalSinceDate:[NSDate date]];
        if (fabs(offset) > _maxOffset) {
            NSLog(@"time is off by %0.3f seconds for hw %@ fw %@ (last reset %@)", offset, self.fireflyIce.hardwareId, self.fireflyIce.version, _reset);
            [self setTime];
        } else {
//            NSLog(@"time is off by %0.3f seconds for hw %@ fw %@", offset, self.fireflyIce.hardwareId, self.fireflyIce.version);
        }
    }
    [self done];
    [_delegate helloTaskComplete:self];
}

@end
