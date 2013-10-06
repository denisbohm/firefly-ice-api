//
//  FDHelloTask.h
//  FireflyDevice
//
//  Created by Denis Bohm on 10/6/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIceTaskSteps.h"

#import <Foundation/Foundation.h>

@class FDHelloTask;

@protocol FDHelloTaskDelegate <NSObject>

- (void)helloTaskComplete:(FDHelloTask *)helloTask;

@end

@interface FDHelloTask : FDFireflyIceTaskSteps

+ (FDHelloTask *)helloTask:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel delegate:(id<FDHelloTaskDelegate>)delegate;

@property id<FDHelloTaskDelegate> delegate;

@end
