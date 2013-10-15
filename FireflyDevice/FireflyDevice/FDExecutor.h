//
//  FDExecutor.h
//  Sync
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FDExecutor;

@protocol FDExecutorTask <NSObject>

@property NSTimeInterval timeout;
@property NSInteger priority;
@property BOOL isSuspended;
@property NSDate *appointment;

- (void)executorTaskStarted:(FDExecutor *)executor;
- (void)executorTaskSuspended:(FDExecutor *)executor;
- (void)executorTaskResumed:(FDExecutor *)executor;
- (void)executorTaskCompleted:(FDExecutor *)executor;

@end

@interface FDExecutor : NSObject

@property(nonatomic) BOOL run;

- (void)execute:(id<FDExecutorTask>)task;
- (void)cancel:(id<FDExecutorTask>)task;
- (NSArray *)allTasks;

- (void)feedWatchdog:(id<FDExecutorTask>)task;
- (void)complete:(id<FDExecutorTask>)task;

@end
