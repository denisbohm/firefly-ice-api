//
//  FDFireflyIce.m
//  FireflyDevice
//
//  Created by Denis Bohm on 7/18/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDBinary.h>
#import <FireflyDevice/FDExecutor.h>
#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceChannel.h>
#import <FireflyDevice/FDFireflyIceCoder.h>
#import <FireflyDevice/FDFireflyDeviceLogger.h>

#include <ctype.h>

@implementation FDFireflyIceVersion

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[FDFireflyIceVersion class]]) {
        return NO;
    }
    FDFireflyIceVersion *o = (FDFireflyIceVersion *)object;
    return (self.major == o.major) && (self.minor == o.minor) && (self.patch == o.patch);
}

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

@implementation FDFireflyIceHardwareVersion

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[FDFireflyIceVersion class]]) {
        return NO;
    }
    FDFireflyIceVersion *o = (FDFireflyIceVersion *)object;
    return (self.major == o.major) && (self.minor == o.minor);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"version %u.%u", _major, _minor];
}

@end

@implementation FDFireflyIceUpdateBinary
@end

@implementation FDFireflyIceUpdateMetadata
@end

@implementation FDFireflyIceUpdateVersion
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
    return [NSString stringWithFormat:@"battery level %0.2f, battery voltage %0.2f V, USB power %@, charging %@, charge current %0.1f mA, temperature %0.1f C", _batteryLevel, _batteryVoltage, _isUSBPowered ? @"YES" : @"NO", _isCharging ? @"YES" : @"NO", _chargeCurrent * 1000.0, _temperature];
}

@end

@implementation FDFireflyIceSectorHash

- (NSString *)description
{
    NSMutableString *string = [NSMutableString stringWithFormat:@"sector %u hash 0x", _sector];
    uint8_t *bytes = (uint8_t *)_hashValue.bytes;
    for (NSUInteger i = 0; i < _hashValue.length; ++i) {
        [string appendFormat:@"%02x", bytes[i]];
    }
    return string;
}

@end

@implementation FDFireflyIceReset

+ (NSString *)causeDescription:(uint32_t)cause
{
#ifdef FD_MCU_STM32
    if (cause & 1) {
        return @"Power On Reset";
    }
    if (cause & 2) {
        return @"Brown Out Detector Unregulated Domain Reset";
    }
    if (cause & 4) {
        return @"Brown Out Detector Regulated Domain Reset";
    }
    if (cause & 8) {
        return @"External Pin Reset";
    }
    if (cause & 16) {
        return @"Watchdog Reset";
    }
    if (cause & 32) {
        return @"LOCKUP Reset";
    }
    if (cause & 64) {
        return @"System Request Reset";
    }
#else
//#ifdef FD_MCU_NRF52
    if (cause & 0b0001) {
        return @"External Pin Reset";
    }
    if (cause & 0b0010) {
        return @"Watchdog Reset";
    }
    if (cause & 0b0100) {
        return @"System Request Reset";
    }
    if (cause & 0b1000) {
        return @"LOCKUP Reset";
    }
    if (cause & 0x010000) {
        return @"Detect from System Off";
    }
    if (cause & 0x020000) {
        return @"Analog Detect from System Off";
    }
    if (cause & 0x040000) {
        return @"Debug from System Off";
    }
    if (cause & 0x080000) {
        return @"NFC from System Off";
    }
    if (cause & 0x100000) {
        return @"VBUS from System Off";
    }
#endif
    if (cause == 0) {
        return @"No Reset";
    }
    return [NSString stringWithFormat:@"0x%08x Reset", cause];
}

- (NSString *)description
{
    return [FDFireflyIceReset causeDescription:_cause];
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
        case FDLockIdentifierSync:
            return @"sync";
        case FDLockIdentifierUpdate:
            return @"update";
        default:
            break;
    }
    return @"invalid";
}

- (NSString *)operationName
{
    switch (_operation) {
        case FDLockOperationNone:
            return @"none";
        case FDLockOperationAcquire:
            return @"acquire";
        case FDLockOperationRelease:
            return @"release";
        default:
            break;
    }
    return @"invalid";
}

+ (NSString *)formatOwnerName:(uint32_t)owner
{
    if (owner == 0) {
        return @"none";
    }
    
    NSMutableString *name = [NSMutableString string];
    uint8_t bytes[] = {(owner >> 24) & 0xff, (owner >> 16) & 0xff, (owner >> 8) & 0xff, owner & 0xff};
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
        return [NSString stringWithFormat:@"anon-0x%08x", owner];
    }
    return name;
}


- (NSString *)ownerName
{
    return [FDFireflyIceLock formatOwnerName:_owner];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"lock identifier %@ operation %@ owner %@", [self identifierName], [self operationName], [self ownerName]];
}

@end

@implementation FDFireflyIceLogging

- (NSString *)description
{
    NSMutableString *string = [NSMutableString stringWithString:@"logging"];
    if (_flags & FD_CONTROL_LOGGING_STATE) {
        [string appendFormat:@" storage=%@", _state & FD_CONTROL_LOGGING_STORAGE ? @"YES" : @"NO"];
    }
    if (_flags & FD_CONTROL_LOGGING_COUNT) {
        [string appendFormat:@" count=%u", _count];
    }
    return string;
}

@end

#define FD_BLUETOOTH_DID_SETUP        0x01
#define FD_BLUETOOTH_DID_ADVERTISE    0x02
#define FD_BLUETOOTH_DID_CONNECT      0x04
#define FD_BLUETOOTH_DID_OPEN_PIPES   0x08
#define FD_BLUETOOTH_DID_RECEIVE_DATA 0x10

@implementation FDFireflyIceDiagnosticsBLE

- (NSString *)description
{
    NSMutableString *string = [NSMutableString stringWithString:@"BLE("];
    [string appendFormat:@" version=%u", _version];
    [string appendFormat:@" systemSteps=%u", _systemSteps];
    [string appendFormat:@" dataSteps=%u", _dataSteps];
    [string appendFormat:@" systemCredits=%u", _systemCredits];
    [string appendFormat:@" dataCredits=%u", _dataCredits];
    [string appendFormat:@" txPower=%u", _txPower];
    [string appendFormat:@" operatingMode=%u", _operatingMode];
    [string appendFormat:@" idle=%@", _idle ? @"YES" : @"NO"];
    [string appendFormat:@" dtm=%@", _dtm ? @"YES" : @"NO"];
    [string appendFormat:@" did=%02x", _did];
    [string appendFormat:@" disconnectAction=%u", _disconnectAction];
    [string appendFormat:@" pipesOpen=%016llx", _pipesOpen];
    [string appendFormat:@" dtmRequest=%u", _dtmRequest];
    [string appendFormat:@" dtmData=%u", _dtmData];
    [string appendFormat:@" bufferCount=%u", _bufferCount];
    [string appendString:@")"];
    return string;
}

@end

@implementation FDFireflyIceDiagnostics

- (NSString *)description
{
    NSMutableString *string = [NSMutableString stringWithString:@"diagnostics"];
    for (id value in _values) {
        [string appendFormat:@" %@", [value description]];
    }
    return string;
}

@end

@implementation FDFireflyIceRetained

- (NSString *)description
{
    return [NSString stringWithFormat:@"retained %@ %@", _retained ? @"YES" : @"NO", _data];
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
        FDFireflyDeviceLogWarn(@"FD010201", @"unexpected exception %@\n%@", e, [e callStackSymbols]);
    }
}

- (void)fireflyIceChannel:(id<FDFireflyIceChannel>)channel detour:(FDDetour *)detour error:(NSError *)error
{
    [self.observable fireflyIce:self channel:channel detour:detour error:error];
}

@end
