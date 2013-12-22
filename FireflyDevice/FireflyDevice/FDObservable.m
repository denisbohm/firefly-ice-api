//
//  FDObservable.m
//  Sync
//
//  Created by Denis Bohm on 7/28/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDObservable.h"
#import "FDFireflyDeviceLogger.h"

#import <objc/runtime.h>

@interface FDObservable ()

@property Protocol *protocol;
@property NSMutableArray *observers;

@end

@implementation FDObservable

- (id)init:(Protocol *)protocol
{
    if (self = [super init]) {
        _protocol = protocol;
        _observers = [NSMutableArray array];
    }
    return self;
}

- (void)addObserver:(id)observer
{
    if (![[observer class] conformsToProtocol:_protocol]) {
        @throw [NSException exceptionWithName:@"ObserverDoesNotConformToProtocol" reason:@"observer does not conform to protocol" userInfo:nil];
    }
    [_observers addObject:observer];
}

- (void)removeObserver:(id)observer
{
    [_observers removeObject:observer];
}

- (struct objc_method_description)getObjcMethodDescription:(SEL)selector {
    struct objc_method_description methodDescription = protocol_getMethodDescription(_protocol, selector, NO, YES);
    if (methodDescription.name == nil) {
        methodDescription = protocol_getMethodDescription(_protocol, selector, YES, YES);
    }
    return methodDescription;
}

- (BOOL)respondsToSelector:(SEL)selector {
    if ([super respondsToSelector:selector]) {
        return YES;
    }
    struct objc_method_description methodDescription = [self getObjcMethodDescription:selector];
    return methodDescription.name != nil;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    struct objc_method_description methodDescription = [self getObjcMethodDescription:selector];
    if (methodDescription.name == nil) {
        return nil;
    }
    return [NSMethodSignature signatureWithObjCTypes:methodDescription.types];
}

- (void)forwardInvocation:(NSInvocation *)invocation  {
    SEL selector = invocation.selector;
    for (id observer in [_observers copy]) {
        if ([observer respondsToSelector:selector]) {
            @try {
                [invocation invokeWithTarget:observer];
            } @catch (NSException *e) {
                FDFireflyDeviceLogWarn(@"unexpected exception during observer invocation: %@", e);
            }
        }
    }
}

@end
