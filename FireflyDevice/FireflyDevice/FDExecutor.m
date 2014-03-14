//
//  FDExecutor.m
//  FireflyDevice
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import "FDExecutor.h"
#import "FDFireflyDeviceLogger.h"

@interface FDExecutor ()

@property NSMutableArray *tasks;
@property NSMutableArray *appointmentTasks;
@property id<FDExecutorTask> currentTask;
@property NSDate *currentFeedTime;

@property NSTimer *timer;

@end

@implementation FDExecutor : NSObject

- (id)init
{
    if (self = [super init]) {
        _timeoutCheckInterval = 5;
        _tasks = [NSMutableArray array];
        _appointmentTasks = [NSMutableArray array];
    }
    return self;
}

- (void)start
{
    _timer = [NSTimer scheduledTimerWithTimeInterval:_timeoutCheckInterval target:self selector:@selector(check:) userInfo:nil repeats:YES];
    [self schedule];
}

- (void)abortTask:(id<FDExecutorTask>)task
{
    @try {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"executor task was aborted", @"")};
        [task executorTaskFailed:self error:[NSError errorWithDomain:FDExecutorErrorDomain code:FDExecutorErrorCodeAbort userInfo:userInfo]];
    } @catch (NSException *e) {
        [self taskException:e];
    }
}

- (void)abortTasks:(NSMutableArray *)tasks
{
    for (id<FDExecutorTask> task in [tasks copy]) {
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
    
    NSTimeInterval duration = -[_currentFeedTime timeIntervalSinceNow];
    if (duration > _currentTask.timeout) {
        FDFireflyDeviceLogInfo(@"executor task timeout");
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"executor task timed out", @"")};
        [self fail:_currentTask error:[NSError errorWithDomain:FDExecutorErrorDomain code:FDExecutorErrorCodeTimeout userInfo:userInfo]];
    }
}

- (void)check:(NSTimer *)timer
{
    [self checkTimeout:timer];
    [self checkAppointments:timer];
}

- (void)taskException:(NSException *)exception
{
    FDFireflyDeviceLogWarn(@"task exception %@", exception);
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
        currentTask.isSuspended = YES;
        [self addTask:currentTask];
        @try {
            [currentTask executorTaskSuspended:self];
        } @catch (NSException *e) {
            [self taskException:e];
        }
    }
    if (_tasks.count == 0) {
        return;
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
    [self cancel:task];
    [self addTask:task];
    
    [self schedule];
}

- (void)feedWatchdog:(id<FDExecutorTask>)task
{
    if (_currentTask == task) {
        _currentFeedTime = [NSDate date];
    } else {
        FDFireflyDeviceLogWarn(@"expected current task to feed watchdog...");
    }
}

- (void)over:(id<FDExecutorTask>)task error:(NSError *)error
{
    if (_currentTask == task) {
        _currentTask = nil;
        @try {
            if (error == nil) {
                [task executorTaskCompleted:self];
            } else {
                [task executorTaskFailed:self error:error];
            }
        } @catch (NSException *e) {
            [self taskException:e];
        }
        [self schedule];
    } else {
        FDFireflyDeviceLogWarn(@"expected current task to be complete...");
    }
}

- (void)fail:(id<FDExecutorTask>)task error:(NSError *)error
{
    [self over:task error:error];
}

- (void)complete:(id<FDExecutorTask>)task
{
    [self over:task error:nil];
}

- (void)cancel:(id<FDExecutorTask>)task
{
    if (_currentTask == task) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"executor task was canceled", @"")};
        [self fail:task error:[NSError errorWithDomain:FDExecutorErrorDomain code:FDExecutorErrorCodeCancel userInfo:userInfo]];
    }
    [_tasks removeObject:task];
    [_appointmentTasks removeObject:task];
}

- (NSArray *)allTasks
{
    NSMutableArray *tasks = [NSMutableArray array];
    if (_currentTask != nil) {
        [tasks addObject:_currentTask];
    }
    [tasks addObjectsFromArray:_tasks];
    [tasks addObjectsFromArray:_appointmentTasks];
    return tasks;
}

- (BOOL)hasTasks
{
    return (_currentTask != nil) || (_tasks.count > 0) || (_appointmentTasks.count > 0);
}

@end
