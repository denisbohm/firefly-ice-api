//
//  FDCobs.m
//  FireflyDevice
//
//  Created by Denis Bohm on 11/2/18.
//  Copyright © 2018 Firefly Design. All rights reserved.
//

#import "FDCobs.h"

@implementation FDCobs

+ (void)setData:(NSMutableData *)data index:(uint32_t)index byte:(uint8_t)byte {
    while (index >= data.length) {
        uint8_t byte = 0;
        [data appendBytes:&byte length:1];
    }
    [data replaceBytesInRange:NSMakeRange(index, 1) withBytes:&byte length:1];
}

+ (NSData *)encode:(NSData *)srcData {
    NSMutableData *dstData = [NSMutableData data];
    uint32_t dst = 0;
    uint32_t code_index = dst++;
    uint8_t code = 1;
    const uint8_t *src = [srcData bytes];
    const uint8_t *src_end = src + srcData.length;
    while (src < src_end) {
        if (code != 255) {
            uint8_t byte = *src++;
            if (byte != 0) {
                [FDCobs setData:dstData index:dst byte: byte];
                dst++;
                code++;
                continue;
            }
        }
        [FDCobs setData:dstData index:code_index byte:code];
        code_index = dst++;
        code = 1;
    }
    [FDCobs setData:dstData index:code_index byte:code];
    return dstData;
}

+ (NSData *)decode:(NSData *)srcData {
    NSMutableData *dstData = [NSMutableData data];
    uint32_t dst = 0;
    uint8_t code = 255;
    uint8_t copy = 0;
    const uint8_t *src = srcData.bytes;
    const uint8_t *src_end = src + srcData.length;
    for (; src < src_end; copy--) {
        if (copy != 0) {
            if (src >= src_end) {
                return nil;
            }
            uint8_t byte = *src++;
            [dstData appendBytes:&byte length:1];
            dst++;
        } else {
            if (code != 255) {
                uint8_t byte = 0;
                [dstData appendBytes:&byte length:1];
                dst++;
            }
            if (src >= src_end) {
                return nil;
            }
            code = *src++;
            copy = code;
        }
    }
    return dstData;
}

@end
