//
//  FDFireflyDeviceLogger.m
//  FireflyDevice
//
//  Created by Denis Bohm on 12/21/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDFireflyDeviceLogger.h>

#include <string.h>

static id<FDFireflyDeviceLog> fireflyDeviceLogger;

@implementation FDFireflyDeviceLogger

+ (void)setLog:(id<FDFireflyDeviceLog>)log
{
    fireflyDeviceLogger = log;
}

+ (id<FDFireflyDeviceLog>)log
{
    return fireflyDeviceLogger;
}

+ (void)log:(id<FDFireflyDeviceLog>)log file:(char *)file line:(NSUInteger)line class:(Class)class method:(NSString *)method format:(NSString *)format, ...
{
    char *short_file = strrchr(file, '/');
    if (short_file != NULL) {
        file = short_file + 1;
    }
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    if (log == nil) {
        log = fireflyDeviceLogger;
    }
    if (log != nil) {
        [log logFile:file line:line class:class method:method message:message];
    } else {
        NSLog(@"log: %s:%lu %@.%@ %@", file, (unsigned long)line, NSStringFromClass(class), method, message);
    }
}

@end
