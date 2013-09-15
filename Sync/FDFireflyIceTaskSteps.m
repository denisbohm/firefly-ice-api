//
//  FDFireflyIceTaskSteps.m
//  Sync
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIceCoder.h"
#import "FDFireflyIceTaskSteps.h"

#import <FireflyProduction/FDBinary.h>

@interface FDFireflyIceTaskSteps ()

@property NSInvocation *invocation;
@property uint32_t invocationId;

@end

@implementation FDFireflyIceTaskSteps

@synthesize isSuspended;
@synthesize priority;

- (void)taskStarted
{
    [_firefly.observable addObserver:self];
}

- (void)taskSuspended
{
    [_firefly.observable removeObserver:self];    
}

- (void)taskResumed
{
    [_firefly.observable addObserver:self];    
}

- (void)taskCompleted
{
    [_firefly.observable removeObserver:self];
}

- (void)fireflyIcePing:(id<FDFireflyIceChannel>)channel data:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    uint32_t invocationId = [binary getUInt32];
    if (invocationId != _invocationId) {
        // unexpected ping
        return;
    }
    
    if (_invocation != nil) {
        NSInvocation *invocation = _invocation;
        _invocation = nil;
        [invocation invoke];
    } else {
        [_firefly.executor complete:self];
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
    _invocation = [self invocation:selector];
    _invocationId = arc4random_uniform(0xffffffff);
    
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt32:_invocationId];
    NSData *data = [binary dataValue];
    [_firefly.coder sendPing:_channel data:data];
}

- (void)done
{
    [_firefly.executor complete:self];
}

@end
