//
//  FDFireflyIceCollector.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/25/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <FireflyDevice/FDFireflyIceChannel.h>
#import <FireflyDevice/FDFireflyIceCoder.h>
#import "FDFireflyIceCollector.h"

@implementation FDFireflyIceCollectorEntry

@end

@interface FDFireflyIceCollector ()

@property NSSet *selectorNames;

@end

@implementation FDFireflyIceCollector

- (id)init
{
    if (self = [super init]) {
        _selectorNames = [NSSet setWithArray:@[
                                               @"fireflyIce:channel:version:",
                                               @"fireflyIce:channel:bootVersion:",
                                               @"fireflyIce:channel:hardwareId:",
                                               @"fireflyIce:channel:debugLock:",
                                               @"fireflyIce:channel:time:",
                                               @"fireflyIce:channel:power:",
                                               @"fireflyIce:channel:site:",
                                               @"fireflyIce:channel:reset:",
                                               @"fireflyIce:channel:storage:",
                                               @"fireflyIce:channel:directTestModeReport:",
                                               @"fireflyIce:channel:sensing:",
                                               @"fireflyIce:channel:txPower:",
                                               @"fireflyIce:channel:regulator:",
                                               @"fireflyIce:channel:name:",
                                               @"fireflyIce:channel:retained:",
                          ]];
        _dictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)complete
{
    [self done];
}

- (void)executorTaskStarted:(FDExecutor *)executor
{
    [super executorTaskStarted:executor];
    
    [self.fireflyIce.coder sendGetProperties:self.channel properties:
     FD_CONTROL_PROPERTY_VERSION |
     FD_CONTROL_PROPERTY_BOOT_VERSION |
     FD_CONTROL_PROPERTY_HARDWARE_ID |
     FD_CONTROL_PROPERTY_DEBUG_LOCK |
     FD_CONTROL_PROPERTY_RTC |
     FD_CONTROL_PROPERTY_POWER |
     FD_CONTROL_PROPERTY_SITE |
     FD_CONTROL_PROPERTY_RESET |
     FD_CONTROL_PROPERTY_STORAGE |
     FD_CONTROL_PROPERTY_TX_POWER |
     FD_CONTROL_PROPERTY_REGULATOR |
     FD_CONTROL_PROPERTY_NAME |
     FD_CONTROL_PROPERTY_RETAINED];
    [self.fireflyIce.coder sendDirectTestModeReport:self.channel];
    
    [self next:@selector(complete)];
}

- (id)objectForKey:(NSString *)key
{
    FDFireflyIceCollectorEntry *entry = _dictionary[key];
    return entry.object;
}

- (BOOL)respondsToSelector:(SEL)selector {
    if ([super respondsToSelector:selector]) {
        return YES;
    }
    
    NSString *selectorName = NSStringFromSelector(selector);
    return [_selectorNames containsObject:selectorName];
}

- (void)setEntry:(NSString *)key object:(id)object {
    FDFireflyIceCollectorEntry *entry = [[FDFireflyIceCollectorEntry alloc] init];
    entry.date = [NSDate date];
    entry.object = object;
    _dictionary[key] = entry;
    
    [_delegate fireflyIceCollectorEntry:(FDFireflyIceCollectorEntry *)entry];
}

- (void)forwardInvocation:(NSInvocation *)invocation  {
    SEL selector = invocation.selector;
    NSString *selectorName = NSStringFromSelector(selector);
    NSArray *parts = [selectorName componentsSeparatedByString:@":"];
    NSString *key = parts[2];
    __unsafe_unretained id object;
    [invocation getArgument:&object atIndex:4];
    
    [self setEntry:key object:object];
}

@end
