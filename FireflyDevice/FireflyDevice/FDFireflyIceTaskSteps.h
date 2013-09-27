//
//  FDFireflyIceTaskSteps.h
//  Sync
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDExecutor.h"
#import "FDFireflyIce.h"

@interface FDFireflyIceTaskSteps : NSObject <FDExecutorTask, FDFireflyIceObserver>

@property FDFireflyIce *fireflyIce;
@property id<FDFireflyIceChannel> channel;

- (void)next:(SEL)selector;
- (void)done;

@end
