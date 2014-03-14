//
//  FDFireflyDeviceLogger.h
//  FireflyDevice
//
//  Created by Denis Bohm on 12/21/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <stdarg.h>

#define FDFireflyDeviceLogError(f, ...) [FDFireflyDeviceLogger log:_log file:__FILE__ line:__LINE__ class:[self class] method:NSStringFromSelector(_cmd) format:f, ##__VA_ARGS__]
#define FDFireflyDeviceLogWarn(f, ...) [FDFireflyDeviceLogger log:_log file:__FILE__ line:__LINE__ class:[self class] method:NSStringFromSelector(_cmd) format:f, ##__VA_ARGS__]
#define FDFireflyDeviceLogInfo(f, ...) [FDFireflyDeviceLogger log:_log file:__FILE__ line:__LINE__ class:[self class] method:NSStringFromSelector(_cmd) format:f, ##__VA_ARGS__]
#define FDFireflyDeviceLogDebug(f, ...) [FDFireflyDeviceLogger log:_log file:__FILE__ line:__LINE__ class:[self class] method:NSStringFromSelector(_cmd) format:f, ##__VA_ARGS__]
#define FDFireflyDeviceLogVerbose(f, ...) [FDFireflyDeviceLogger log:_log file:__FILE__ line:__LINE__ class:[self class] method:NSStringFromSelector(_cmd) format:f, ##__VA_ARGS__]

@protocol FDFireflyDeviceLog <NSObject>

- (void)logFile:(char *)file line:(NSUInteger)line class:(Class)class method:(NSString *)method message:(NSString *)message;

@end

@interface FDFireflyDeviceLogger : NSObject

+ (void)setLog:(id<FDFireflyDeviceLog>)log;
+ (id<FDFireflyDeviceLog>)log;

+ (void)log:(id<FDFireflyDeviceLog>)log file:(char *)file line:(NSUInteger)line class:(Class)class method:(NSString *)method format:(NSString *)format, ...;

@end
