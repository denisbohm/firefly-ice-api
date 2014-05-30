//
//  FDFireflyIceTaskSteps.h
//  FireflyDevice
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDExecutor.h>
#import <FireflyDevice/FDFireflyIce.h>

@interface FDFireflyIceTaskSteps : NSObject <FDExecutorTask, FDFireflyIceObserver>

@property FDFireflyIce *fireflyIce;
@property id<FDFireflyIceChannel> channel;

- (void)next:(SEL)selector;
- (void)done;

@end
