//
//  FDSyncTask.h
//  FireflyDevice
//
//  Created by Denis Bohm on 9/25/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIceTaskSteps.h"

#import <Foundation/Foundation.h>

@interface FDSyncTask : FDFireflyIceTaskSteps

+ (FDSyncTask *)syncTask:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel;

@end
