//
//  FDExecutor.m
//  Sync
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDExecutor.h"

@interface FDExecutor ()

@property NSTimer *watchdogTimer;
@property NSMutableArray *tasks;
@property NSMutableArray *suspendedTasks;
@property id<FDExecutorTask> currentTask;
@property NSDate *currentFeedTime;

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

- (void)setRun:(BOOL)run
{
    _run = run;
    
    [self schedule];
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

- (void)checkTimeout:(NSTimer *)timer
{
    if (_currentTask == nil) {
        return;
    }
    
    NSTimeInterval duration = [_currentFeedTime timeIntervalSinceNow];
    if (duration > _currentTask.timeout) {
        NSLog(@"executor task timeout");
        [self complete:_currentTask];
    }
}

- (void)taskException:(NSException *)exception
{
    NSLog(@"task exception %@", exception);
}

- (void)schedule
{
    if (!_run) {
        return;
    }
    
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
        @try {
            [currentTask taskSuspended];
        } @catch (NSException *e) {
            [self taskException:e];
        }
    }
    if (_tasks.count == 0) {
        return;
    }
    
    if (_watchdogTimer == nil) {
        _watchdogTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkTimeout:) userInfo:nil repeats:YES];
    }
    
    _currentTask = _tasks[0];
    [_tasks removeObjectAtIndex:0];
    _currentFeedTime = [NSDate date];
    if (_currentTask.isSuspended) {
        _currentTask.isSuspended = NO;
        @try {
            [_currentTask taskResumed];
        } @catch (NSException *e) {
            [self taskException:e];
        }
    } else {
        @try {
            [_currentTask taskStarted];
        } @catch (NSException *e) {
            [self taskException:e];
        }
    }
}

- (void)execute:(id<FDExecutorTask>)task
{
    [self addTask:task];
    
    [self schedule];
}

- (void)feedWatchdog:(id<FDExecutorTask>)task
{
    if (_currentTask == task) {
        _currentFeedTime = [NSDate date];
    } else {
        NSLog(@"expected current task to feed watchdog...");
    }
}

- (void)complete:(id<FDExecutorTask>)task
{
    if (_currentTask == task) {
        _currentTask = nil;
        @try {
            [task taskCompleted];
        } @catch (NSException *e) {
            [self taskException:e];
        }
        [self schedule];
    } else {
        NSLog(@"expected current task to be complete...");
    }
}

@end
