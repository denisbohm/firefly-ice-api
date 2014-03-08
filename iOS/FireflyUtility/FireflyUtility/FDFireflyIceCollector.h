//
//  FDFireflyIceCollector.h
//  FireflyUtility
//
//  Created by Denis Bohm on 9/25/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <FireflyDevice/FDExecutor.h>
#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceTaskSteps.h>

#import <Foundation/Foundation.h>

@interface FDFireflyIceCollectorEntry : NSObject
@property NSDate *date;
@property id object;
@end

@class FDFireflyIceCollector;

@protocol FDFireflyIceCollectorDelegate <NSObject>

- (void)fireflyIceCollectorEntry:(FDFireflyIceCollectorEntry *)entry;

@end

@interface FDFireflyIceCollector : FDFireflyIceTaskSteps

@property id<FDFireflyIceCollectorDelegate> delegate;
@property NSMutableDictionary *dictionary;

- (id)objectForKey:(NSString *)key;
- (void)setEntry:(NSString *)key object:(id)object;

@end
