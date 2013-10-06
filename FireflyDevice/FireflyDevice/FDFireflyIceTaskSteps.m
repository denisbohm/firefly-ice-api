//
//  FDFireflyIceTaskSteps.m
//  Sync
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDBinary.h"
#import "FDFireflyIceCoder.h"
#import "FDFireflyIceTaskSteps.h"

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
        _timeout = 600; // !!! just for testing -denis
    }
    return self;
}

- (void)executorTaskStarted:(FDExecutor *)executor
{
//    NSLog(@"task started");
    [_fireflyIce.observable addObserver:self];
}

- (void)executorTaskSuspended:(FDExecutor *)executor
{
//    NSLog(@"task suspended");
    [_fireflyIce.observable removeObserver:self];
}

- (void)executorTaskResumed:(FDExecutor *)executor
{
//    NSLog(@"task resumed");
    [_fireflyIce.observable addObserver:self];
}

- (void)executorTaskCompleted:(FDExecutor *)executor
{
//    NSLog(@"task completed");
    [_fireflyIce.observable removeObserver:self];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel ping:(NSData *)data
{
//    NSLog(@"ping received");
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    uint32_t invocationId = [binary getUInt32];
    if (invocationId != _invocationId) {
        NSLog(@"unexpected ping");
        return;
    }
    
    if (_invocation != nil) {
//        NSLog(@"invoking step %@", NSStringFromSelector(_invocation.selector));
        NSInvocation *invocation = _invocation;
        _invocation = nil;
        [invocation invoke];
    } else {
//        NSLog(@"all steps completed");
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
//    NSLog(@"queing next step %@", NSStringFromSelector(selector));
    
    [_fireflyIce.executor feedWatchdog:self];
    
    _invocation = [self invocation:selector];
    _invocationId = arc4random_uniform(0xffffffff);
    
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt32:_invocationId];
    NSData *data = [binary dataValue];
    [_fireflyIce.coder sendPing:_channel data:data];
}

- (void)done
{
//    NSLog(@"task done");
    [_fireflyIce.executor complete:self];
}

@end
