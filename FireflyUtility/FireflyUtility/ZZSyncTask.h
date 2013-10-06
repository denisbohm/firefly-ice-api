//
//  ZZSyncTask.h
//  FireflyUtility
//
//  Created by Denis Bohm on 9/28/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <FireflyDevice/FDExecutor.h>
#import <FireflyDevice/FDFireflyIce.h>

#import <Foundation/Foundation.h>

@interface ZZSyncTask : NSObject <FDExecutorTask, FDFireflyIceObserver>

+ (ZZSyncTask *)syncTask:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel;

@property FDFireflyIce *fireflyIce;
@property id<FDFireflyIceChannel> channel;

@end
