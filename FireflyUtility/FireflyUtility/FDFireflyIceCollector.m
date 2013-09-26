//
//  FDFireflyIceCollector.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/25/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

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
                                               @"fireflyIce:channel:hardwareId:",
                                               @"fireflyIce:channel:debugLock:",
                                               @"fireflyIce:channel:time:",
                                               @"fireflyIce:channel:power:",
                                               @"fireflyIce:channel:site:",
                                               @"fireflyIce:channel:reset:",
                                               @"fireflyIce:channel:storage:",
                                               @"fireflyIce:channel:directTestModeReport:",
                                               @"fireflyIce:channel:sensing:",
                          ]];
        _dictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)objectForKey:(NSString *)key
{
    FDFireflyIceCollectorEntry *entry = _dictionary[key];
    return entry.object;
}

- (BOOL)respondsToSelector:(SEL)selector {
    NSString *selectorName = NSStringFromSelector(selector);
    return [_selectorNames containsObject:selectorName];
}

- (void)forwardInvocation:(NSInvocation *)invocation  {
    SEL selector = invocation.selector;
    NSString *selectorName = NSStringFromSelector(selector);
    NSArray *parts = [selectorName componentsSeparatedByString:@":"];
    NSString *key = parts[3];
    NSObject *object;
    [invocation getArgument:&object atIndex:4];
    FDFireflyIceCollectorEntry *entry = [[FDFireflyIceCollectorEntry alloc] init];
    entry.date = [NSDate date];
    entry.object = object;
    _dictionary[key] = entry;
    
    [_delegate fireflyIceCollectorEntry:(FDFireflyIceCollectorEntry *)entry];
}

@end
