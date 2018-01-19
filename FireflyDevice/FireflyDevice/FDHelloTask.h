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

- (void)helloTaskSuccess:(nonnull FDHelloTask *)helloTask;
- (void)helloTask:(nonnull FDHelloTask *)helloTask error:(nullable NSError *)error;

@optional

- (nullable NSDate *)helloTaskDate;
- (nullable NSTimeZone *)helloTaskTimeZone;

@end

@interface FDHelloTask : FDFireflyIceTaskSteps

+ (nonnull FDHelloTask *)helloTask:(nonnull FDFireflyIce *)fireflyIce channel:(nonnull id<FDFireflyIceChannel>)channel delegate:(nullable id<FDHelloTaskDelegate>)delegate;

@property id <FDHelloTaskDelegate> _Nullable delegate;
@property BOOL setTimeEnabled;
@property NSTimeInterval setTimeTolerance;
@property BOOL indicate;

@property NSMutableDictionary * _Nonnull propertyValues;

- (void)queryProperty:(uint32_t)property delegateMethodName:(nonnull NSString *)delegateMethodName;

@end
