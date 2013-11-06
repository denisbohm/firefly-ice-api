//
//  FDFireflyIce.m
//  Sync
//
//  Created by Denis Bohm on 7/18/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDBinary.h"
#import "FDExecutor.h"
#import "FDFireflyIce.h"
#import "FDFireflyIceChannel.h"
#import "FDFireflyIceCoder.h"

#include <ctype.h>

@implementation FDFireflyIceVersion

- (NSString *)description
{
    NSMutableString *s = [NSMutableString stringWithFormat:@"version %u.%u.%u, capabilities 0x%08x, git commit ", _major, _minor, _patch, _capabilities];
    uint8_t *bytes = (uint8_t *)_gitCommit.bytes;
    for (NSUInteger i = 0; i < _gitCommit.length; ++i) {
        [s appendFormat:@"%02x", bytes[i]];
    }
    return s;
}

@end

@implementation FDFireflyIceHardwareId

- (NSString *)description
{
    NSMutableString *s = [NSMutableString stringWithFormat:@"vendor 0x%04x, product 0x%04x, version %u.%u unique ", _vendor, _product, _major, _minor];
    uint8_t *bytes = (uint8_t *)_unique.bytes;
    for (NSUInteger i = 0; i < _unique.length; ++i) {
        [s appendFormat:@"%02x", bytes[i]];
    }
    return s;
}

@end

@implementation FDFireflyIcePower

- (NSString *)description
{
    return [NSString stringWithFormat:@"battery level %0.2f, battery voltage %0.2f V, USB power %@, charging %@, charge current %0.1f mA, temperature %0.1f C", _batteryLevel, _batteryVoltage, _isUSBPowered ? @"YES" : @"NO", _isCharging ? @"YES" : @"NO", _chargeCurrent, _temperature];
}

@end

@implementation FDFireflyIceSectorHash

- (NSString *)description
{
    NSMutableString *string = [NSMutableString stringWithFormat:@"sector %u hash 0x", _sector];
    uint8_t *bytes = (uint8_t *)_hash.bytes;
    for (NSUInteger i = 0; i < _hash.length; ++i) {
        [string appendFormat:@"%02x", bytes[i]];
    }
    return string;
}

@end

@implementation FDFireflyIceReset

- (NSString *)description
{
    if (_cause & 1) {
        return @"Power On Reset";
    }
    if (_cause & 2) {
        return @"Brown Out Detector Unregulated Domain Reset";
    }
    if (_cause & 4) {
        return @"Brown Out Detector Regulated Domain Reset";
    }
    if (_cause & 8) {
        return @"External Pin Reset";
    }
    if (_cause & 16) {
        return @"Watchdog Reset";
    }
    if (_cause & 32) {
        return @"LOCKUP Reset";
    }
    if (_cause & 64) {
        return @"System Request Reset";
    }
    if (_cause == 0) {
        return @"No Reset";
    }
    return [NSString stringWithFormat:@"0x%08x Reset", _cause];
}

@end

@implementation FDFireflyIceStorage

- (NSString *)description
{
    return [NSString stringWithFormat:@"page count %u", _pageCount];
}

@end

@implementation FDFireflyIceDirectTestModeReport
@end

@implementation FDFireflyIceUpdateCommit
@end

@implementation FDFireflyIceSensing
@end

@implementation FDFireflyIceLock

- (NSString *)identifierName
{
    switch (_identifier) {
        case fd_lock_identifier_sync:
            return @"sync";
        case fd_lock_identifier_update:
            return @"update";
        default:
            break;
    }
    return @"invalid";
}

- (NSString *)operationName
{
    switch (_operation) {
        case fd_lock_operation_none:
            return @"none";
        case fd_lock_operation_acquire:
            return @"acquire";
        case fd_lock_operation_release:
            return @"release";
        default:
            break;
    }
    return @"invalid";
}

- (NSString *)ownerName
{
    if (_owner == 0) {
        return @"none";
    }
    
    NSMutableString *name = [NSMutableString string];
    uint8_t bytes[] = {(_owner >> 24) & 0xff, (_owner >> 16) & 0xff, (_owner >> 8) & 0xff, _owner & 0xff};
    for (NSUInteger i = 0; i < sizeof(bytes); ++i) {
        uint8_t byte = bytes[i];
        if (isalnum(byte)) {
            [name appendFormat:@"%c", byte];
        } else
        if (!isspace(byte)) {
            name = nil;
        }
    }
    if (name.length == 0) {
        return [NSString stringWithFormat:@"anon-0x%08x", _owner];
    }
    return name;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"lock identifier %@ operation %@ owner %@", [self identifierName], [self operationName], [self ownerName]];
}

@end

@implementation FDFireflyIceObservable

- (id)init
{
    if (self = [super init:@protocol(FDFireflyIceObserver)]) {
    }
    return self;
}

@end

@interface FDFireflyIce () <FDFireflyIceChannelDelegate, FDFireflyIceObserver>

@end

@implementation FDFireflyIce

- (id)init
{
    if (self = [super init]) {
        _coder = [[FDFireflyIceCoder alloc] init];
        [_coder.observable addObserver:self];
        _executor = [[FDExecutor alloc] init];
        _channels = [NSMutableDictionary dictionary];
        _name = @"anonymous";
    }
    return self;
}

- (NSString *)description
{
    return _name;
}

- (FDFireflyIceObservable *)observable
{
    return _coder.observable;
}

- (void)addChannel:(id<FDFireflyIceChannel>)channel type:(NSString *)type
{
    _channels[type] = channel;
    channel.delegate = self;
}

- (void)removeChannel:(NSString *)type
{
    id<FDFireflyIceChannel> channel = _channels[type];
    channel.delegate = nil;
    [_channels removeObjectForKey:type];
}

- (void)fireflyIceChannel:(id<FDFireflyIceChannel>)channel status:(FDFireflyIceChannelStatus)status
{
    [self.observable fireflyIce:self channel:channel status:status];
    
    _executor.run = (status == FDFireflyIceChannelStatusOpen);
}

- (void)fireflyIceChannelPacket:(id<FDFireflyIceChannel>)channel data:(NSData *)data
{
    @try {
        [_coder fireflyIce:self channel:channel packet:data];
    } @catch (NSException *e) {
        NSLog(@"unexpected exception %@\n%@", e, [e callStackSymbols]);
    }
}

- (void)fireflyIceChannel:(id<FDFireflyIceChannel>)channel detour:(FDDetour *)detour error:(NSError *)error
{
    [self.observable fireflyIce:self channel:channel detour:detour error:error];
}

@end
