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

@property NSData *buffer;
@property uint32_t putIndex;
@property uint32_t getIndex;

@end

@implementation FDBinary

+ (uint8_t)unpackUint8:(uint8_t *)buffer {
    return buffer[0];
}

+ (uint16_t)unpackUint16:(uint8_t *)buffer {
    return (buffer[1] << 8) | buffer[0];
}

+ (uint32_t)unpackUint32:(uint8_t *)buffer {
    return (buffer[3] << 24) | (buffer[2] << 16) | (buffer[1] << 8) | buffer[0];
}

+ (uint64_t)unpackUint64:(uint8_t *)buffer {
    uint64_t lo = [FDBinary unpackUint32:buffer];
    uint64_t hi = [FDBinary unpackUint32:&buffer[8]];
    return (hi << 32) | lo;
}

typedef union {
    uint32_t asUint32;
    float asFloat32;
} fd_int32_float32_t;

+ (float)unpackFloat32:(uint8_t *)buffer {
    fd_int32_float32_t u;
    u.asUint32 = [FDBinary unpackUint32:buffer];
    return u.asFloat32;
}

+ (NSTimeInterval)unpackTime:(uint8_t *)buffer {
    uint32_t seconds = [FDBinary unpackUint32:buffer];
    uint32_t microseconds = [FDBinary unpackUint32:buffer];
    return seconds + microseconds * 1e-6;
}

+ (void)pack_uint8:(uint8_t *)buffer value:(uint8_t)value {
    buffer[0] = value;
}

+ (void)pack_uint16:(uint8_t *)buffer value:(uint16_t)value {
    buffer[0] = value;
    buffer[1] = value >> 8;
}

+ (void)pack_uint32:(uint8_t *)buffer value:(uint32_t)value {
    buffer[0] = value;
    buffer[1] = value >> 8;
    buffer[2] = value >> 16;
    buffer[3] = value >> 24;
}

+ (void)pack_uint64:(uint8_t *)buffer value:(uint64_t)value {
    [FDBinary pack_uint32:buffer value:(uint32_t)value];
    [FDBinary pack_uint32:&buffer[4] value:(uint32_t)(value >> 32)];
}

+ (void)pack_float32:(uint8_t *)buffer value:(float)value {
    fd_int32_float32_t u;
    u.asFloat32 = value;
    [FDBinary pack_uint32:buffer value:u.asUint32];
}

+ (void)pack_time:(uint8_t *)buffer value:(NSTimeInterval)value {
    uint32_t seconds = (uint32_t)value;
    uint32_t microseconds = (uint32_t)((value - seconds) * 1e6);
    [FDBinary pack_uint32:buffer value:seconds];
    [FDBinary pack_uint32:&buffer[4] value:microseconds];
}

- (id)initWithData:(NSData *)data {
    if (self = [super init]) {
        _buffer = data;
        _putIndex = 0;
        _getIndex = 0;
    }
    return self;
}

- (NSData *)getRemainingData {
    return [_buffer subdataWithRange:NSMakeRange(_getIndex, _buffer.length - _getIndex)];
}

- (void)checkGet:(NSUInteger)amount {
    if ((_buffer.length - _getIndex) < amount) {
        @throw [NSException exceptionWithName:@"IndexOutOfBounds" reason:@"index out of bounds" userInfo:nil];
    }
}

- (uint8_t)getUint8 {
    [self checkGet:1];
    uint8_t *buffer = &((uint8_t *)_buffer.bytes)[_getIndex];
    _getIndex += 1;
    return [FDBinary unpackUint8:buffer];
}

- (uint16_t)getUint16 {
    [self checkGet:2];
    uint8_t *buffer = &((uint8_t *)_buffer.bytes)[_getIndex];
    _getIndex += 2;
    return [FDBinary unpackUint16:buffer];
}

- (uint32_t)getUint32 {
    [self checkGet:4];
    uint8_t *buffer = &((uint8_t *)_buffer.bytes)[_getIndex];
    _getIndex += 4;
    return [FDBinary unpackUint32:buffer];
}

- (uint64_t)getUint64 {
    [self checkGet:8];
    uint8_t *buffer = &((uint8_t *)_buffer.bytes)[_getIndex];
    _getIndex += 8;
    return [FDBinary unpackUint64:buffer];
}

- (float)getFloat32 {
    [self checkGet:4];
    uint8_t *buffer = &((uint8_t *)_buffer.bytes)[_getIndex];
    _getIndex += 4;
    return [FDBinary unpackFloat32:buffer];
}

- (NSTimeInterval)getTime {
    [self checkGet:8];
    uint8_t *buffer = &((uint8_t *)_buffer.bytes)[_getIndex];
    _getIndex += 8;
    return [FDBinary unpackTime:buffer];
}

/*
void fd_binary_put_bytes(fd_binary_t *binary, uint8_t *data, uint32_t length) {
    memcpy(data, &_buffer[_putIndex], length);
    _putIndex += length;
}

void fd_binary_put_uint8(fd_binary_t *binary, uint8_t value) {
    uint8_t *buffer = &_buffer[_putIndex];
    _putIndex += 1;
    fd_binary_pack_uint8(buffer, value);
}

void fd_binary_put_uint16(fd_binary_t *binary, uint16_t value) {
    uint8_t *buffer = &_buffer[_putIndex];
    _putIndex += 2;
    fd_binary_pack_uint16(buffer, value);
}

void fd_binary_put_uint32(fd_binary_t *binary, uint32_t value) {
    uint8_t *buffer = &_buffer[_putIndex];
    _putIndex += 4;
    fd_binary_pack_uint32(buffer, value);
}

void fd_binary_put_uint64(fd_binary_t *binary, uint64_t value) {
    uint8_t *buffer = &_buffer[_putIndex];
    _putIndex += 8;
    fd_binary_pack_uint64(buffer, value);
}

void fd_binary_put_float32(fd_binary_t *binary, float value) {
    uint8_t *buffer = &_buffer[_putIndex];
    _putIndex += 4;
    fd_binary_pack_float32(buffer, value);
}

void fd_binary_put_time(fd_binary_t *binary, NSTimeInterval value) {
    uint8_t *buffer = &_buffer[_putIndex];
    _putIndex += 8;
    fd_binary_pack_time(buffer, value);
}
*/

@end
