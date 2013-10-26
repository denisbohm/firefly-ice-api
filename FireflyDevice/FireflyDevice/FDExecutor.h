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
- (void)executorTaskFailed:(FDExecutor *)executor error:(NSError *)error;

@end

enum {
    FDExecutorErrorCodeAbort,
    FDExecutorErrorCodeCancel,
    FDExecutorErrorCodeTimeout,
};

@interface FDExecutor : NSObject

@property(nonatomic) BOOL run;

- (void)execute:(id<FDExecutorTask>)task;
- (void)cancel:(id<FDExecutorTask>)task;
- (NSArray *)allTasks;
@property(readonly) BOOL hasTasks;

- (void)feedWatchdog:(id<FDExecutorTask>)task;
- (void)complete:(id<FDExecutorTask>)task;
- (void)fail:(id<FDExecutorTask>)task error:(NSError *)error;

@end
