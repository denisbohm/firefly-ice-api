//
//  FDFirmwareUpdateTask.h
//  Sync
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIceTaskSteps.h"

@class FDExecutable;

@interface FDFirmwareUpdateTaskDelegate : NSObject

- (void)firmwareUpdateTaskComplete:(BOOL)isFirmwareUpToDate;

@end

@interface FDFirmwareUpdateTask : FDFireflyIceTaskSteps

@property FDExecutable *executable;
@property FDFirmwareUpdateTaskDelegate *delegate;

@end
