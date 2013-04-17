//
//  FDDetour.m
//  Sync
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDBinary.h"
#import "FDDetour.h"

@interface FDDetour ()

@property NSMutableData *buffer;
@property FDDetourState state;
@property uint32_t length;
@property uint32_t sequence_number;
@property uint32_t offset;

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
    _sequence_number = 0;
    _buffer.length = 0;
}

- (void)detourError {
    _state = FDDetourStateError;
}

- (void)detourContinue:(NSData *)data {
    NSUInteger total = _buffer.length + data.length;
    if (total > _length) {
        // ignore any extra data at the end of the transfer
        data = [data subdataWithRange:NSMakeRange(0, _length - _buffer.length)];
    }
    [_buffer appendData:data];
    if (_buffer.length == _length) {
        _state = FDDetourStateSuccess;
    } else {
        ++_sequence_number;
    }
}

- (void)detourStart:(NSData *)data {
    if (data.length < 2) {
        [self detourError];
        return;
    }
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    _state = FDDetourStateIntermediate;
    _length = [binary getUint16];
    _sequence_number = 0;
    _buffer.length = 0;
    [self detourContinue:[binary getRemainingData]];
}

- (void)detourEvent:(NSData *)data {
    if (data.length < 1) {
        [self detourError];
        return;
    }
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    uint8_t sequence_number = [binary getUint8];
    if (sequence_number == 0) {
        if (_sequence_number != 0) {
            [self detourError];
        } else {
            [self detourStart:[binary getRemainingData]];
        }
    } else
    if (sequence_number != _sequence_number) {
        [self detourError];
    } else {
        [self detourContinue:[binary getRemainingData]];
    }
}

@end
