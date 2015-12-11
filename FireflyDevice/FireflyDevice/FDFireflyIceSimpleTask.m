//
//  FDFireflyIceSimpleTask.m
//  FireflyDevice
//
//  Created by Denis Bohm on 10/17/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDFireflyIceSimpleTask.h>

@implementation FDFireflyIceSimpleTask

+ (FDFireflyIceSimpleTask *)simpleTask:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel comment:(NSString *)comment wait:(BOOL)wait block:(void (^)(void))block
{
    FDFireflyIceSimpleTask *task = [[FDFireflyIceSimpleTask alloc] init];
    task.fireflyIce = fireflyIce;
    task.channel = channel;
    task.comment = comment;
    task.wait = wait;
    task.block = block;
    return task;
}

+ (FDFireflyIceSimpleTask *)simpleTask:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel block:(void (^)(void))block
{
    return [FDFireflyIceSimpleTask simpleTask:fireflyIce channel:channel comment:nil wait:YES block:block];
}

- (void)executorTaskStarted:(FDExecutor *)executor
{
    [super executorTaskStarted:executor];
    _block();
    if (self.wait) {
        [self next:@selector(complete)];
    } else {
        [self complete];
    }
}

- (void)complete
{
    [self done];
}

- (NSString *)description
{
    if (self.comment) {
        return self.comment;
    }
    return [super description];
}

@end
