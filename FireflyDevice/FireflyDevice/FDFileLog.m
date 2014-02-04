//
//  FDFileLog.m
//  FireflyGame
//
//  Created by Denis Bohm on 12/23/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFileLog.h"

//#import "TestFlight.h"

@interface FDFileLog ()

@property NSString *logDirectory;
@property NSString *logFileName;
@property NSString *logFileNameOld;
@property NSObject *logMutex;
@property NSDateFormatter *logDateFormatter;
@property NSFileHandle *logFile;

@end

@implementation FDFileLog

- (id)init {
    if (self = [super init]) {
        _logLimit = 100000;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *libraryDirectory = [paths objectAtIndex:0];
        _logDirectory = libraryDirectory;
        _logFileName = [_logDirectory stringByAppendingPathComponent:@"log.txt"];
        _logFileNameOld = [_logDirectory stringByAppendingPathComponent:@"log-1.txt"];
        _logMutex = [[NSObject alloc] init];
        _logDateFormatter = [[NSDateFormatter alloc] init];
        [_logDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    }
    return self;
}

- (NSString *)content
{
    NSMutableString *string = [NSMutableString string];
    [self getContent:string];
    return string;
}

- (void)appendFile:(NSMutableString *)string fileName:(NSString *)fileName
{
    NSString *content = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil];
    if (content != nil) {
        [string appendString:content];
    }
}

- (void)getContent:(NSMutableString *)string
{
    @synchronized(_logMutex) {
        [self close];
        
        [self appendFile:string fileName:_logFileNameOld];
        [self appendFile:string fileName:_logFileName];
    }
}

- (void)close
{
    [_logFile closeFile];
    _logFile = nil;
}

- (NSString *)now
{
    return [_logDateFormatter stringFromDate:[NSDate date]];
}

- (void)log:(NSString *)message
{
    @synchronized(_logMutex) {
        if (_logFile == nil) {
            _logFile = [NSFileHandle fileHandleForWritingAtPath:_logFileName];
            if (_logFile == nil) {
                [[NSFileManager defaultManager] createFileAtPath:_logFileName contents:nil attributes:nil];
                _logFile = [NSFileHandle fileHandleForWritingAtPath:_logFileName];
            }
            [_logFile seekToEndOfFile];
        }
        if (_logFile != nil) {
            NSString *line = [NSString stringWithFormat:@"%@ %@\n", [self now], message];
            [_logFile writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
            [_logFile synchronizeFile];
            unsigned long long length = [_logFile offsetInFile];
            if (length > _logLimit) {
                [self close];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                [fileManager removeItemAtPath:_logFileNameOld error:nil];
                [fileManager moveItemAtPath:_logFileName toPath:_logFileNameOld error:nil];
            }
        }
    }
}

- (char *)lastPathComponent:(char *)path
{
    char *component = strrchr(path, '/');
    if (component != nil) {
        return component + 1;
    }
    return path;
}

- (void)logFile:(char *)file line:(NSUInteger)line class:(Class)class method:(NSString *)method message:(NSString *)message
{
    NSString *fullMessage = [NSString stringWithFormat:@"%s:%lu %@.%@ %@", [self lastPathComponent:file], (unsigned long)line, NSStringFromClass(class), method, message];

    NSLog(@"%@", fullMessage);
    [self log:fullMessage];

//    TFLogPreFormatted(fullMessage);
}

@end
