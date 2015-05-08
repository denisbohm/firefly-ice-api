//
//  FDVMADecoder.m
//  FireflyDevice
//
//  Created by Denis Bohm on 5/8/15.
//  Copyright (c) 2015 Firefly Design. All rights reserved.
//

#import "FDVMADecoder.h"

#import "FDPullTask.h"

@implementation FDVMAItem
@end

@implementation FDVMADecoder

- (id)decode:(uint32_t)type data:(NSData *)data responseData:(NSData *)responseData
{
    const int floatBytes = 2; // FDV2 uses float16
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    NSTimeInterval time = [binary getUInt32]; // 4-byte time
    uint16_t interval = [binary getUInt16];
    NSUInteger n = [binary getRemainingLength] / floatBytes; // 4 bytes == sizeof(float32), 2 bytes == sizeof(float16)
    FDFireflyDeviceLogInfo(@"FD010715", @"sync VMAs: %lu values", (unsigned long)n);
    NSMutableArray *vmas = [NSMutableArray array];
    for (NSUInteger i = 0; i < n; ++i) {
        float value = (floatBytes == 2) ? [binary getFloat16] : [binary getFloat32];
        [vmas addObject:[NSNumber numberWithFloat:value]];
    }
    FDVMAItem *item = [[FDVMAItem alloc] init];
    item.time = time;
    item.interval = interval;
    item.vmas = vmas;
    return item;
}

@end
