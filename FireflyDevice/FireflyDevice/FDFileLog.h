//
//  FDFileLog.h
//  FireflyGame
//
//  Created by Denis Bohm on 12/23/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <FireflyDevice/FDFireflyDeviceLogger.h>

@interface FDFileLog : NSObject <FDFireflyDeviceLog>

@property NSUInteger logLimit;

- (void)getContent:(NSMutableString *)string;
- (NSString *)content;

@end
