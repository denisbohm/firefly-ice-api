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
@property NSMutableArray *appointmentTasks;
@property NSMutableArray *suspendedTasks;
@property id<FDExecutorTask> currentTask;
@property NSDate *currentFeedTime;

@property NSTimer *timer;

@end

@implementation FDExecutor : NSObject

- (id)init
{
    if (self = [super init]) {
        _tasks = [NSMutableArray array];
        _appointmentTasks = [NSMutableArray array];
        _suspendedTasks = [NSMutableArray array];
    }
    return self;
}

- (void)start
{
    _timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(checkAppointments:) userInfo:nil repeats:YES];
    [self schedule];
}

- (void)abortTask:(id<FDExecutorTask>)task
{
    @try {
        [task executorTaskCompleted:self];
    } @catch (NSException *e) {
        [self taskException:e];
    }
}

- (void)abortTasks:(NSMutableArray *)tasks
{
    for (id<FDExecutorTask> task in tasks) {
        [self abortTask:task];
    }
    [tasks removeAllObjects];
}

- (void)stop
{
    [_timer invalidate];
    _timer = nil;
    
    if (_currentTask != nil) {
        [self abortTask:_currentTask];
        _currentTask = nil;
    }
    [self abortTasks:_appointmentTasks];
    [self abortTasks:_suspendedTasks];
    [self abortTasks:_tasks];
}

- (void)setRun:(BOOL)run
{
    if (_run == run) {
        return;
    }
    
    _run = run;
    if (_run) {
        [self start];
    } else {
        [self stop];
    }
}

- (void)sortTasksByPriority
{
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

- (void)checkAppointments:(NSTimer *)timer
{
    NSArray *tasks = [NSArray arrayWithArray:_appointmentTasks];
    NSDate *now = [NSDate date];
    for (id<FDExecutorTask> task in tasks) {
        if ([now timeIntervalSinceDate:task.appointment] >= 0) {
            task.appointment = nil;
            [_appointmentTasks removeObject:task];
            [_tasks addObject:task];
        }
    }
    [self sortTasksByPriority];
    [self schedule];
}

- (void)addTask:(id<FDExecutorTask>)task
{
    if (task.appointment != nil) {
        [_appointmentTasks addObject:task];
        return;
    }
    
    [_tasks addObject:task];
    [self sortTasksByPriority];
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
            [currentTask executorTaskSuspended:self];
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
            [_currentTask executorTaskResumed:self];
        } @catch (NSException *e) {
            [self taskException:e];
        }
    } else {
        @try {
            [_currentTask executorTaskStarted:self];
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
            [task executorTaskCompleted:self];
        } @catch (NSException *e) {
            [self taskException:e];
        }
        [self schedule];
    } else {
        NSLog(@"expected current task to be complete...");
    }
}

@end
