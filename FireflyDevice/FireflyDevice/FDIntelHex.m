//
//  FDIntelHex.m
//  FireflyDevice
//
//  Created by Denis Bohm on 9/18/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDIntelHex.h>
#import <FireflyDevice/FDJSON.h>

@implementation FDIntelHex

+ (FDIntelHex *)intelHex:(NSString *)hex address:(uint32_t)address length:(uint32_t)length
{
    FDIntelHex *intelHex = [[FDIntelHex alloc] init];
    [intelHex read:hex address:address length:length];
    return intelHex;
}

+ (NSData *)parse:(NSString *)content address:(uint32_t)address length:(uint32_t)length
{
    return [FDIntelHex intelHex:content address:address length:length].data;
}

+ (uint32_t)hex:(NSString *)line index:(int *)index length:(int)length crc:(uint8_t *)crc
{
    NSString *string = [line substringWithRange:NSMakeRange(*index, length)];
    *index += length;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    unsigned int value = 0;
    [scanner scanHexInt:&value];
    if (length == 2) {
        *crc += value;
    } else
    if (length == 4) {
        *crc += (value >> 8);
        *crc += value & 0xff;
    }
    return value;
}

- (uint32_t)getHexProperty:(NSString *)key fallback:(uint32_t)fallback
{
    NSObject *object = [_properties valueForKey:key];
    if (object) {
        NSScanner *scanner = [NSScanner scannerWithString:(NSString *)object];
        unsigned int value = 0;
        if ([scanner scanHexInt:&value]) {
            return value;
        }
    }
    return fallback;
}

- (void)read:(NSString *)content address:(uint32_t)address length:(uint32_t)length
{
    _properties = [NSMutableDictionary dictionary];
    NSArray *lines = [content componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        if ([line hasPrefix:@"#! "]) {
            NSDictionary *dictionary = [FDJSON JSONObjectWithData:[[line substringFromIndex:2] dataUsingEncoding:NSUTF8StringEncoding]];
            [_properties addEntriesFromDictionary:dictionary];
        }
    }
    
    address = [self getHexProperty:@"address" fallback:address];
    length = [self getHexProperty:@"length" fallback:length];
    
    NSMutableData *firmware = [NSMutableData data];
    uint32_t extendedAddress = 0;
    bool done = false;
    for (NSString *line in lines) {
        if (![line hasPrefix:@":"]) {
            continue;
        }
        if (done) {
            continue;
        }
        int index = 1;
        uint8_t crc = 0;
        uint32_t byteCount = [FDIntelHex hex:line index:&index length:2 crc:&crc];
        uint32_t recordAddress = [FDIntelHex hex:line index:&index length:4 crc:&crc];
        uint32_t recordType = [FDIntelHex hex:line index:&index length:2 crc:&crc];
        NSMutableData *data = [NSMutableData data];
        for (int i = 0; i < byteCount; ++i) {
            uint8_t byte = [FDIntelHex hex:line index:&index length:2 crc:&crc];
            [data appendBytes:&byte length:1];
        }
        uint8_t ignore = 0;
        uint8_t checksum = [FDIntelHex hex:line index:&index length:2 crc:&ignore];
        crc = 256 - crc;
        if (checksum != crc) {
            @throw [NSException exceptionWithName:@"checksum mismatch" reason:@"checksum mismatch" userInfo:nil];
        }
        switch (recordType) {
            case 0: { // Data Record
                uint32_t targetAddress = extendedAddress + recordAddress;
                if (targetAddress >= address) {
                    uint32_t dataAddress = targetAddress - address;
                    uint32_t length = dataAddress + (uint32_t)data.length;
                    if (length > firmware.length) {
                        firmware.length = length;
                    }
                    uint8_t *bytes = (uint8_t *)firmware.bytes;
                    memcpy(&bytes[dataAddress], data.bytes, data.length);
                }
            } break;
            case 1: { // End Of File Record
                done = true;
            } break;
            case 2: { // Extended Segment Address Record
                uint8_t *bytes = (uint8_t *)data.bytes;
                extendedAddress = ((bytes[0] << 8) | (bytes[1]) << 4);
            } break;
            case 3: { // Start Segment Address Record
                // ignore
            } break;
            case 4: { // Extended Linear Address Record
                uint8_t *bytes = (uint8_t *)data.bytes;
                extendedAddress = ((bytes[0] << 24) | (bytes[1]) << 16);
            } break;
            case 5: { // Start Linear Address Record
                // ignore
            } break;
        }
    }
    _data = firmware;
}

@end
