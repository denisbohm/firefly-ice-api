//
//  FDDetour.m
//  Sync
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDBinary.h"
#import "FDDetour.h"
#import "FDFireflyDeviceLogger.h"

@interface FDDetour ()

@property NSMutableData *buffer;
@property FDDetourState state;
@property uint32_t length;
@property uint32_t sequenceNumber;

@end

@implementation FDDetour

- (id)init {
    if (self = [super init]) {
        _buffer = [NSMutableData data];
        _state = FDDetourStateClear;
    }
    return self;
}

- (NSData *)data {
    return _buffer;
}

- (void)clear {
    _state = FDDetourStateClear;
    _length = 0;
    _sequenceNumber = 0;
    _buffer.length = 0;
    _error = nil;
}

- (void)detourError:(NSString *)reason {
    _error = [NSError errorWithDomain:@"FDDetour" code:0 userInfo:@{ @"detail":[NSString stringWithFormat:@"detour error %@: state %u, length %u, sequence %u, data %@", reason, _state, _length, _sequenceNumber, _buffer]}];
    _state = FDDetourStateError;
}

- (void)detourContinue:(NSData *)data {
    NSUInteger total = _buffer.length + data.length;
    if (total > _length) {
        // ignore any extra data at the end of the transfer
        data = [data subdataWithRange:NSMakeRange(0, _length - _buffer.length)];
    }
    [_buffer appendData:data];
    if (_buffer.length >= _length) {
        _state = FDDetourStateSuccess;
//        FDFireflyDeviceLogInfo(@"detour success: %d %ld %@", _length, (unsigned long)_buffer.length, _buffer);
    } else {
        ++_sequenceNumber;
    }
}

- (void)detourStart:(NSData *)data {
    if (data.length < 2) {
        [self detourError:@"data.length < 2"];
        return;
    }
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    _state = FDDetourStateIntermediate;
    _length = [binary getUInt16];
    _sequenceNumber = 0;
    _buffer.length = 0;
    [self detourContinue:[binary getRemainingData]];
}

- (void)detourEvent:(NSData *)data {
    if (data.length < 1) {
        [self detourError:@"data.length < 1"];
        return;
    }
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    uint8_t sequenceNumber = [binary getUInt8];
    if (sequenceNumber == 0) {
        if (_sequenceNumber != 0) {
            [self detourError:@"unexpected start"];
        } else {
            [self detourStart:[binary getRemainingData]];
        }
    } else
    if (sequenceNumber != _sequenceNumber) {
        [self detourError:[NSString stringWithFormat:@"out of sequence %u != %u", sequenceNumber, _sequenceNumber]];
    } else {
        [self detourContinue:[binary getRemainingData]];
    }
}

@end
