//
//  FDFireflyIce.m
//  Sync
//
//  Created by Denis Bohm on 7/18/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDExecutor.h"
#import "FDFireflyIce.h"
#import "FDFireflyIceChannel.h"
#import "FDFireflyIceCoder.h"

#import <FireflyProduction/FDBinary.h>

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

@synthesize channelBLE = _channelBLE;
@synthesize channelUSB = _channelUSB;

- (id)init
{
    if (self = [super init]) {
        _coder = [[FDFireflyIceCoder alloc] init];
        [_coder.observable addObserver:self];
        _executor = [[FDExecutor alloc] init];
    }
    return self;
}

- (FDFireflyIceObservable *)observable
{
    return _coder.observable;
}

- (void)setChannelBLE:(FDFireflyIceChannelBLE *)channelBLE
{
    _channelBLE = channelBLE;
    channelBLE.delegate = self;
}

- (FDFireflyIceChannelBLE *)channelBLE
{
    return _channelBLE;
}

- (void)setChannelUSB:(FDFireflyIceChannelUSB *)channelUSB
{
    _channelUSB = channelUSB;
    channelUSB.delegate = self;
}

- (FDFireflyIceChannelUSB *)channelUSB
{
    return _channelUSB;
}

- (void)fireflyIceChannelOpen:(id<FDFireflyIceChannel>)channel;
{
    [_coder sendGetProperties:channel properties:
     FD_CONTROL_PROPERTY_VERSION |
     FD_CONTROL_PROPERTY_HARDWARE_ID |
     FD_CONTROL_PROPERTY_POWER |
     FD_CONTROL_PROPERTY_RTC |
     FD_CONTROL_PROPERTY_SITE];
}

- (void)fireflyIceChannelPacket:(id<FDFireflyIceChannel>)channel data:(NSData *)data
{
    [_coder fireflyIceChannelPacket:channel data:data];
}

- (void)fireflyIceProperty:(id<FDFireflyIceChannel>)channel version:(FDFireflyIceVersion *)version
{
    _version = version;
    NSLog(@"device version %@", _version);
}

- (void)fireflyIceProperty:(id<FDFireflyIceChannel>)channel hardwareId:(FDFireflyIceHardwareId *)hardwareId
{
    _hardwareId = hardwareId;
    NSLog(@"device hardware id %@", _hardwareId);
}

- (void)fireflyIceProperty:(id<FDFireflyIceChannel>)channel time:(NSDate *)date
{
    NSLog(@"device date %@", date);
}

- (void)fireflyIceProperty:(id<FDFireflyIceChannel>)channel power:(FDFireflyIcePower *)power
{
    NSLog(@"device power %@", power);
}

- (void)fireflyIceProperty:(id<FDFireflyIceChannel>)channel site:(NSString *)site
{
    _site = site;
    NSLog(@"device site %@", _site);
}

- (void)fireflyIceSyncData:(id<FDFireflyIceChannel>)channel data:(NSData *)data
{
    NSLog(@"sync data for %@", _site);
    
    NSString *url = [NSString stringWithFormat:@"%@/sync", _site];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%ld", (unsigned long)data.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *type = response.MIMEType;
    if (![@"application/octet-stream" isEqual:[type lowercaseString]]) {
        NSLog(@"sync data response: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        return;
    }
    NSLog(@"sending sync response");
    [channel fireflyIceChannelSend:responseData];    
}

@end
