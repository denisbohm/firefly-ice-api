//
//  FDExecutor.m
//  Sync
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDExecutor.h"

@interface FDExecutor ()

@property NSMutableArray *tasks;
@property NSMutableArray *suspendedTasks;
@property id<FDExecutorTask> currentTask;

@end

@implementation FDExecutor : NSObject

- (id)init
{
    if (self = [super init]) {
        _tasks = [NSMutableArray array];
        _suspendedTasks = [NSMutableArray array];
    }
    return self;
}

- (void)addTask:(id<FDExecutorTask>)task
{
    [_tasks addObject:task];
    [_tasks sortUsingComparator:^NSComparisonResult(id aObject, id bObject) {
        id<FDExecutorTask> a = aObject;
        id<FDExecutorTask> b = bObject;
        NSInteger d = b.priority - a.priority;
        if (d < 0) {
            return NSOrderedAscending;
        }
        if (d > 0) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
}

- (void)schedule
{
    if (_currentTask != nil) {
        if (_tasks.count == 0) {
            return;
        }
        id<FDExecutorTask> task = _tasks[0];
        if (_currentTask.priority >= task.priority) {
            return;
        }
        id<FDExecutorTask> currentTask = _currentTask;
        _currentTask = nil;
        [self addTask:task];
        currentTask.isSuspended = YES;
        [currentTask taskSuspended];
    }
    if (_tasks.count == 0) {
        return;
    }
    _currentTask = _tasks[0];
    [_tasks removeObjectAtIndex:0];
    if (_currentTask.isSuspended) {
        _currentTask.isSuspended = NO;
        [_currentTask taskResumed];
    } else {
        [_currentTask taskStarted];
    }
}

- (void)execute:(id<FDExecutorTask>)task
{
    [self addTask:task];
    
    [self schedule];
}

- (void)complete:(id<FDExecutorTask>)task
{
    if (_currentTask == task) {
        _currentTask = nil;
        [task taskCompleted];
        [self schedule];
    } else {
        NSLog(@"expected current task to be complete...");
    }
}

@end
