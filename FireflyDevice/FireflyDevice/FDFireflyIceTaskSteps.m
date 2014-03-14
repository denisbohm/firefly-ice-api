//
//  FDFireflyIceTaskSteps.m
//  FireflyDevice
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import "FDBinary.h"
#import "FDFireflyIceCoder.h"
#import "FDFireflyIceTaskSteps.h"
#import "FDFireflyDeviceLogger.h"

#define _log _fireflyIce.log

@interface FDFireflyIceTaskSteps ()

@property NSInvocation *invocation;
@property uint32_t invocationId;

@end

@implementation FDFireflyIceTaskSteps

@synthesize timeout = _timeout;
@synthesize priority = _priority;
@synthesize isSuspended = _isSuspended;
@synthesize appointment = _appointment;

- (id)init
{
    if (self = [super init]) {
        _timeout = 15;
    }
    return self;
}

- (void)executorTaskStarted:(FDExecutor *)executor
{
//    FDFireflyDeviceLogDebug(@"%@ task started", NSStringFromClass([self class]));
    [_fireflyIce.observable addObserver:self];
}

- (void)executorTaskSuspended:(FDExecutor *)executor
{
//    FDFireflyDeviceLogDebug(@"%@ task suspended", NSStringFromClass([self class]));
    [_fireflyIce.observable removeObserver:self];
}

- (void)executorTaskResumed:(FDExecutor *)executor
{
//    FDFireflyDeviceLogDebug(@"%@ task resumed", NSStringFromClass([self class]));
    [_fireflyIce.observable addObserver:self];
}

- (void)executorTaskCompleted:(FDExecutor *)executor
{
//    FDFireflyDeviceLogDebug(@"%@ task completed", NSStringFromClass([self class]));
    [_fireflyIce.observable removeObserver:self];
}

- (void)executorTaskFailed:(FDExecutor *)executor error:(NSError *)error
{
//    FDFireflyDeviceLogDebug(@"%@ task failed with error %@", NSStringFromClass([self class]), error);
    [_fireflyIce.observable removeObserver:self];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel detour:(FDDetour *)detour error:(NSError *)error
{
    [_fireflyIce.executor fail:self error:error];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel ping:(NSData *)data
{
//    FDFireflyDeviceLogDebug(@"ping received");
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    uint32_t invocationId = [binary getUInt32];
    if (invocationId != _invocationId) {
        FDFireflyDeviceLogWarn(@"unexpected ping 0x%08x (expected 0x%08x %@ %@)", invocationId, _invocationId, NSStringFromClass([self class]), NSStringFromSelector(_invocation.selector));
        return;
    }
    
    if (_invocation != nil) {
//        FDFireflyDeviceLogDebug(@"invoking step %@", NSStringFromSelector(_invocation.selector));
        NSInvocation *invocation = _invocation;
        _invocation = nil;
        [invocation invoke];
    } else {
//        FDFireflyDeviceLogDebug(@"all steps completed");
        [_fireflyIce.executor complete:self];
    }
}

- (NSInvocation *)invocation:(SEL)selector
{
    NSMethodSignature *signature = [[self class] instanceMethodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:self];
    [invocation setSelector:selector];
    return invocation;
}

- (void)next:(SEL)selector
{
//    FDFireflyDeviceLogDebug(@"queing next step %@", NSStringFromSelector(selector));
    
    [_fireflyIce.executor feedWatchdog:self];
    
    _invocation = [self invocation:selector];
    if (arc4random_uniform) {
        _invocationId = arc4random_uniform(0xffffffff);
    } else {
        _invocationId = arc4random();
    }
    
//    FDFireflyDeviceLogDebug(@"setup ping 0x%08x %@ %@", _invocationId, NSStringFromClass([self class]), NSStringFromSelector(_invocation.selector));

    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt32:_invocationId];
    NSData *data = [binary dataValue];
    [_fireflyIce.coder sendPing:_channel data:data];
}

- (void)done
{
//    FDFireflyDeviceLogDebug(@"task done");
    [_fireflyIce.executor complete:self];
}

@end
