//
//  FDHelloTask.h
//  FireflyDevice
//
//  Created by Denis Bohm on 10/6/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDFireflyIceTaskSteps.h>

#import <Foundation/Foundation.h>

#define FDHelloTaskErrorDomain @"com.fireflydesign.device.FDHelloTask"

enum {
    FDHelloTaskErrorCodeIncomplete
};

@class FDHelloTask;

@protocol FDHelloTaskDelegate <NSObject>

- (void)helloTaskSuccess:(FDHelloTask *)helloTask;
- (void)helloTask:(FDHelloTask *)helloTask error:(NSError *)error;

@optional

- (NSDate *)helloTaskDate;
- (NSTimeZone *)helloTaskTimeZone;

@end

@interface FDHelloTask : FDFireflyIceTaskSteps

+ (FDHelloTask *)helloTask:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel delegate:(id<FDHelloTaskDelegate>)delegate;

@property id<FDHelloTaskDelegate> delegate;
@property BOOL setTimeEnabled;
@property NSTimeInterval setTimeTolerance;
@property BOOL indicate;

@property NSMutableDictionary *propertyValues;

- (void)queryProperty:(uint32_t)property delegateMethodName:(NSString *)delegateMethodName;

@end
