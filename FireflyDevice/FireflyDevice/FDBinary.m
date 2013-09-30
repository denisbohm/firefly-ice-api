//
//  FDBinary.m
//  Sync
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDBinary.h"

#include <stdint.h>
#include <string.h>

@interface FDBinary ()

@property NSMutableData *buffer;
@property uint32_t getIndex;

@end

@implementation FDBinary

+ (uint8_t)unpackUInt8:(uint8_t *)buffer {
    return buffer[0];
}

+ (uint16_t)unpackUInt16:(uint8_t *)buffer {
    return (buffer[1] << 8) | buffer[0];
}

+ (uint32_t)unpackUInt32:(uint8_t *)buffer {
    return (buffer[3] << 24) | (buffer[2] << 16) | (buffer[1] << 8) | buffer[0];
}

+ (uint64_t)unpackUInt64:(uint8_t *)buffer {
    uint64_t lo = [FDBinary unpackUInt32:buffer];
    uint64_t hi = [FDBinary unpackUInt32:&buffer[8]];
    return (hi << 32) | lo;
}

typedef union {
    uint32_t asUint32;
    float asFloat32;
} fd_int32_float32_t;

+ (float)unpackFloat32:(uint8_t *)buffer {
    fd_int32_float32_t u;
    u.asUint32 = [FDBinary unpackUInt32:buffer];
    return u.asFloat32;
}

+ (NSTimeInterval)unpackTime64:(uint8_t *)buffer {
    uint32_t seconds = [FDBinary unpackUInt32:buffer];
    uint32_t microseconds = [FDBinary unpackUInt32:&buffer[4]];
    return seconds + microseconds * 1e-6;
}

+ (void)packUInt8:(uint8_t *)buffer value:(uint8_t)value {
    buffer[0] = value;
}

+ (void)packUInt16:(uint8_t *)buffer value:(uint16_t)value {
    buffer[0] = value;
    buffer[1] = value >> 8;
}

+ (void)packUInt32:(uint8_t *)buffer value:(uint32_t)value {
    buffer[0] = value;
    buffer[1] = value >> 8;
    buffer[2] = value >> 16;
    buffer[3] = value >> 24;
}

+ (void)packUInt64:(uint8_t *)buffer value:(uint64_t)value {
    [FDBinary packUInt32:buffer value:(uint32_t)value];
    [FDBinary packUInt32:&buffer[4] value:(uint32_t)(value >> 32)];
}

+ (void)packFloat32:(uint8_t *)buffer value:(float)value {
    fd_int32_float32_t u;
    u.asFloat32 = value;
    [FDBinary packUInt32:buffer value:u.asUint32];
}

+ (void)packTime64:(uint8_t *)buffer value:(NSTimeInterval)value {
    uint32_t seconds = (uint32_t)value;
    uint32_t microseconds = (uint32_t)((value - seconds) * 1e6);
    [FDBinary packUInt32:buffer value:seconds];
    [FDBinary packUInt32:&buffer[4] value:microseconds];
}

- (id)init {
    if (self = [super init]) {
        _buffer = [NSMutableData data];
        _getIndex = 0;
    }
    return self;
}

- (id)initWithData:(NSData *)data {
    if (self = [super init]) {
        _buffer = [NSMutableData dataWithData:data];
        _getIndex = 0;
    }
    return self;
}

- (NSUInteger)length
{
    return _buffer.length;
}

- (NSData *)dataValue {
    return [NSData dataWithData:_buffer];
}

- (NSUInteger)getRemainingLength {
    return _buffer.length - _getIndex;
}

- (NSData *)getRemainingData {
    return [_buffer subdataWithRange:NSMakeRange(_getIndex, _buffer.length - _getIndex)];
}

- (void)checkGet:(NSUInteger)amount {
    if ((_buffer.length - _getIndex) < amount) {
        @throw [NSException exceptionWithName:@"IndexOutOfBounds" reason:@"index out of bounds" userInfo:nil];
    }
}

- (NSData *)getData:(NSUInteger)length {
    [self checkGet:length];
    NSData *data = [_buffer subdataWithRange:NSMakeRange(_getIndex, length)];
    _getIndex += length;
    return data;
}

- (uint8_t)getUInt8 {
    [self checkGet:1];
    uint8_t *buffer = &((uint8_t *)_buffer.bytes)[_getIndex];
    _getIndex += 1;
    return [FDBinary unpackUInt8:buffer];
}

- (uint16_t)getUInt16 {
    [self checkGet:2];
    uint8_t *buffer = &((uint8_t *)_buffer.bytes)[_getIndex];
    _getIndex += 2;
    return [FDBinary unpackUInt16:buffer];
}

- (uint32_t)getUInt32 {
    [self checkGet:4];
    uint8_t *buffer = &((uint8_t *)_buffer.bytes)[_getIndex];
    _getIndex += 4;
    return [FDBinary unpackUInt32:buffer];
}

- (uint64_t)getUInt64 {
    [self checkGet:8];
    uint8_t *buffer = &((uint8_t *)_buffer.bytes)[_getIndex];
    _getIndex += 8;
    return [FDBinary unpackUInt64:buffer];
}

- (float)getFloat32 {
    [self checkGet:4];
    uint8_t *buffer = &((uint8_t *)_buffer.bytes)[_getIndex];
    _getIndex += 4;
    return [FDBinary unpackFloat32:buffer];
}

- (NSTimeInterval)getTime64 {
    [self checkGet:8];
    uint8_t *buffer = &((uint8_t *)_buffer.bytes)[_getIndex];
    _getIndex += 8;
    return [FDBinary unpackTime64:buffer];
}

- (void)putData:(NSData *)data {
    [_buffer appendData:data];
}

- (void)putUInt8:(uint8_t)value {
    [_buffer appendBytes:&value length:1];
}

- (void)putUInt16:(uint16_t)value {
    uint8_t bytes[] = {value, value >> 8};
    [_buffer appendBytes:bytes length:sizeof(bytes)];
}

- (void)putUInt32:(uint32_t)value {
    uint8_t bytes[] = {value, value >> 8, value >> 16, value >> 24};
    [_buffer appendBytes:bytes length:sizeof(bytes)];
}

- (void)putUInt64:(uint64_t)value {
    uint8_t bytes[] = {value, value >> 8, value >> 16, value >> 24, value >> 32, value >> 40, value >> 48, value >> 56};
    [_buffer appendBytes:bytes length:sizeof(bytes)];
}

- (void)putFloat32:(float)value {
    fd_int32_float32_t u;
    u.asFloat32 = value;
    [self putUInt32:u.asUint32];
}

-(void)putTime64:(NSTimeInterval)value {
    uint32_t seconds = (uint32_t)value;
    uint32_t microseconds = (uint32_t)((value - seconds) * 1e6);
    [self putUInt32:seconds];
    [self putUInt32:microseconds];
}

@end

