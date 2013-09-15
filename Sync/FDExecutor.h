//
//  FDExecutor.h
//  Sync
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FDExecutorTask <NSObject>

@property NSInteger priority;
@property BOOL isSuspended;

- (void)taskStarted;
- (void)taskSuspended;
- (void)taskResumed;
- (void)taskCompleted;

@end

@class FDExecutor;

@interface FDExecutor : NSObject

- (void)execute:(id<FDExecutorTask>)task;

- (void)complete:(id<FDExecutorTask>)task;

@end
