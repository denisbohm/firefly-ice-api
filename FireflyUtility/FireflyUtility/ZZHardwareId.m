//
//  ZZHardwareId.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/30/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "ZZHardwareId.h"

#import <FireflyDevice/FDFireflyIce.h>

@implementation ZZHardwareId

+ (NSString *)hardwareId:(NSData *)unique
{
    NSMutableString *hardwareId = [NSMutableString stringWithString:@"ZM1001-1.3-"];
    uint8_t *bytes = (uint8_t *)unique.bytes;
    for (NSUInteger i = 0; i < unique.length; ++i) {
		uint8_t byte = bytes[i];
        [hardwareId appendFormat:@"%02X", byte];
	}
    return hardwareId;
}

@end
