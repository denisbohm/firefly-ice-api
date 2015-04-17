//
//  FDDetour.m
//  FireflyDevice
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDBinary.h>
#import <FireflyDevice/FDDetour.h>
#import <FireflyDevice/FDFireflyDeviceLogger.h>

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
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: NSLocalizedString(@"Out of sequence data when communicating with the device", @""),
                               NSLocalizedRecoveryOptionsErrorKey: NSLocalizedString(@"Make sure the device stays in close range", @""),
                               @"com.fireflydesign.device.detail": [NSString stringWithFormat:@"detour error %@: state %u, length %u, sequence %u, data %@", reason, _state, _length, _sequenceNumber, _buffer]
                               };
    _error = [NSError errorWithDomain:FDDetourErrorDomain code:FDDetourErrorCodeOutOfSequence userInfo:userInfo];
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
        _endDate = [NSDate date];
        _state = FDDetourStateSuccess;
        
        NSUInteger rate = 0;
        NSTimeInterval duration = [_endDate timeIntervalSinceDate:_startDate];
        if (duration > 0.0) {
            rate = (NSUInteger)(_buffer.length / duration);
        }
        NSLog(@"detour success: %lu B (%lu B/s)", (unsigned long)_buffer.length, (unsigned long)rate);
    } else {
        ++_sequenceNumber;
    }
}

- (void)detourStart:(NSData *)data {
    if (data.length < 2) {
        [self detourError:@"data.length < 2"];
        return;
    }
    _startDate = [NSDate date];
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
        [self detourError:[NSString stringWithFormat:@"out of sequence found %u but expected %u", sequenceNumber, _sequenceNumber]];
    } else {
        [self detourContinue:[binary getRemainingData]];
    }
}

@end
