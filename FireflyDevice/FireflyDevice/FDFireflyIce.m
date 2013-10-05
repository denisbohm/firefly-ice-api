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
@end

@implementation FDFireflyIceStorage
@end

@implementation FDFireflyIceDirectTestModeReport
@end

@implementation FDFireflyIceUpdateCommit
@end

@implementation FDFireflyIceSensing
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

- (void)fireflyIceChannelOpen:(id<FDFireflyIceChannel>)channel;
{
    [_coder sendGetProperties:channel properties:FD_CONTROL_PROPERTY_VERSION | FD_CONTROL_PROPERTY_HARDWARE_ID];
}

- (void)fireflyIceChannelPacket:(id<FDFireflyIceChannel>)channel data:(NSData *)data
{
    @try {
        [_coder fireflyIce:self channel:channel packet:data];
    } @catch (NSException *e) {
        NSLog(@"unexpected exception %@\n%@", e, [e callStackSymbols]);
    }
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel version:(FDFireflyIceVersion *)version
{
    _version = version;
    NSLog(@"device version %@", _version);
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel hardwareId:(FDFireflyIceHardwareId *)hardwareId
{
    _hardwareId = hardwareId;
    NSLog(@"device hardware id %@", _hardwareId);
}

@end
