//
//  FDFireflyIceCoder.m
//  Sync
//
//  Created by Denis Bohm on 7/19/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIce.h"
#import "FDFireflyIceChannel.h"
#import "FDFireflyIceCoder.h"

#import <FireflyProduction/FDBinary.h>

#define FD_CONTROL_PING 1

#define FD_CONTROL_GET_PROPERTIES 2
#define FD_CONTROL_SET_PROPERTIES 3

#define FD_CONTROL_PROVISION 4
#define FD_CONTROL_RESET 5

#define FD_CONTROL_UPDATE_GET_SECTOR_HASHES 6
#define FD_CONTROL_UPDATE_ERASE_SECTORS 7
#define FD_CONTROL_UPDATE_WRITE_PAGE 8
#define FD_CONTROL_UPDATE_COMMIT 9

#define FD_CONTROL_RADIO_DIRECT_TEST_MODE_ENTER 10
#define FD_CONTROL_RADIO_DIRECT_TEST_MODE_EXIT 11
#define FD_CONTROL_RADIO_DIRECT_TEST_MODE_REPORT 12

#define FD_CONTROL_DISCONNECT 13

#define FD_CONTROL_INDICATOR_OVERRIDE 14

#define FD_CONTROL_SYNC_START 15
#define FD_CONTROL_SYNC_DATA 16
#define FD_CONTROL_SYNC_ACK 17

#define FD_CONTROL_RESET_SYSTEM_REQUEST 1
#define FD_CONTROL_RESET_WATCHDOG 2
#define FD_CONTROL_RESET_HARD_FAULT 3

#define HASH_SIZE 20

@implementation FDFireflyIceCoder

- (id)init
{
    if (self = [super init]) {
        _observable = [[FDFireflyIceObservable alloc] init];
    }
    return self;
}

- (void)sendPing:(id<FDFireflyIceChannel>)channel data:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_PING];
    [binary putUInt16:data.length];
    [binary putData:data];
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)ping:(id<FDFireflyIceChannel>)channel data:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    uint16_t length = [binary getUInt16];
    NSData *pingData = [binary getData:length];
    
    [_observable fireflyIcePing:channel data:pingData];
}

#define FD_MAP_TYPE_STRING 1

// binary dictionary format:
// - uint16_t number of dictionary entries
// - for each dictionary entry:
//   - uint8_t length of key
//   - uint8_t type of value
//   - uint16_t length of value
//   - uint16_t offset of key, value bytes
- (NSData *)dictionaryMap:(NSDictionary *)dictionary
{
    FDBinary *map = [[FDBinary alloc] init];
    NSMutableData *content = [NSMutableData data];
    [map putUInt16:dictionary.count];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id keyId, id valueId, BOOL *stop) {
        NSString *key = keyId;
        NSString *value = valueId;
        NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
        NSData *valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
        [map putUInt8:(uint8_t)keyData.length];
        [map putUInt8:FD_MAP_TYPE_STRING];
        [map putUInt16:(uint16_t)valueData.length];
        NSUInteger offset = content.length;
        [map putUInt16:offset];
        [content appendData:keyData];
        [content appendData:valueData];
    }];
    [map putData:content];
    return map.dataValue;
}

- (void)sendProvision:(id<FDFireflyIceChannel>)channel dictionary:(NSDictionary *)dictionary options:(uint32_t)options
{
    NSData *data = [self dictionaryMap:dictionary];
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_PROVISION];
    [binary putUInt32:options];
    [binary putUInt16:data.length];
    [binary putData:data];
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendReset:(id<FDFireflyIceChannel>)channel type:(uint8_t)type
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_RESET];
    [binary putUInt8:type];
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendGetProperties:(id<FDFireflyIceChannel>)channel properties:(uint32_t)properties
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_GET_PROPERTIES];
    [binary putUInt32:properties];
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)getPropertyVersion:(id<FDFireflyIceChannel>)channel binary:(FDBinary *)binary
{
    FDFireflyIceVersion *version = [[FDFireflyIceVersion alloc] init];
    version.major = [binary getUInt16];
    version.minor = [binary getUInt16];
    version.patch = [binary getUInt16];
    version.capabilities = [binary getUInt32];
    version.gitCommit = [binary getData:20];
    
    [_observable fireflyIceProperty:channel version:version];
}

- (void)getPropertyHardwareId:(id<FDFireflyIceChannel>)channel binary:(FDBinary *)binary
{
    FDFireflyIceHardwareId *hardwareId = [[FDFireflyIceHardwareId alloc] init];
    hardwareId.vendor = [binary getUInt16];
    hardwareId.product = [binary getUInt16];
    hardwareId.major = [binary getUInt16];
    hardwareId.minor = [binary getUInt16];
    hardwareId.unique = [binary getData:8];
    
    [_observable fireflyIceProperty:channel hardwareId:hardwareId];
}

- (void)getPropertyDebugLock:(id<FDFireflyIceChannel>)channel binary:(FDBinary *)binary
{
    BOOL debugLock = [binary getUInt8] ? YES : NO;
    
    [_observable fireflyIceProperty:channel debugLock:debugLock];
}

- (void)getPropertyRTC:(id<FDFireflyIceChannel>)channel binary:(FDBinary *)binary
{
    NSTimeInterval time = [binary getTime64];
    
    [_observable fireflyIceProperty:channel time:[NSDate dateWithTimeIntervalSince1970:time]];
}

- (void)getPropertyPower:(id<FDFireflyIceChannel>)channel binary:(FDBinary *)binary
{
    FDFireflyIcePower *power = [[FDFireflyIcePower alloc] init];
    power.batteryLevel = [binary getFloat32];
    power.batteryVoltage = [binary getFloat32];
    power.isUSBPowered = [binary getUInt8] ? YES : NO;
    power.isCharging = [binary getUInt8] ? YES : NO;
    power.chargeCurrent = [binary getFloat32];
    power.temperature = [binary getFloat32];
    
    [_observable fireflyIceProperty:channel power:power];
}

- (void)getPropertySite:(id<FDFireflyIceChannel>)channel binary:(FDBinary *)binary
{
    uint16_t length = [binary getUInt16];
    NSData *data = [binary getData:length];
    NSString *site = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [_observable fireflyIceProperty:channel site:site];
}

- (void)getProperties:(id<FDFireflyIceChannel>)channel data:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    uint32_t properties = [binary getUInt32];
    if (properties & FD_CONTROL_PROPERTY_VERSION) {
        [self getPropertyVersion:channel binary:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_HARDWARE_ID) {
        [self getPropertyHardwareId:channel binary:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_DEBUG_LOCK) {
        [self getPropertyDebugLock:channel binary:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_RTC) {
        [self getPropertyRTC:channel binary:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_POWER) {
        [self getPropertyPower:channel binary:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_SITE) {
        [self getPropertySite:channel binary:binary];
    }
}

- (void)sendSetPropertyTime:(id<FDFireflyIceChannel>)channel time:(NSDate *)time
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_SET_PROPERTIES];
    [binary putUInt32:FD_CONTROL_PROPERTY_RTC];
    [binary putTime64:[time timeIntervalSince1970]];
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendUpdateGetSectorHashes:(id<FDFireflyIceChannel>)channel sectors:(NSArray *)sectors
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_UPDATE_GET_SECTOR_HASHES];
    [binary putUInt8:sectors.count];
    for (NSNumber *number in sectors) {
        uint16_t sector = (uint16_t)[number unsignedShortValue];
        [binary putUInt16:sector];
    }
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendUpdateEraseSectors:(id<FDFireflyIceChannel>)channel sectors:(NSArray *)sectors
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_UPDATE_ERASE_SECTORS];
    [binary putUInt8:sectors.count];
    for (NSNumber *number in sectors) {
        uint16_t sector = (uint16_t)[number unsignedShortValue];
        [binary putUInt16:sector];
    }
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendUpdateWritePage:(id<FDFireflyIceChannel>)channel page:(uint16_t)page data:(NSData *)data
{
    // !!! assert that data.length == page size -denis
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_UPDATE_WRITE_PAGE];
    [binary putUInt16:page];
    [binary putData:data];
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendUpdateCommit:(id<FDFireflyIceChannel>)channel
                   flags:(uint32_t)flags
                  length:(uint32_t)length
                    hash:(NSData *)hash
               cryptHash:(NSData *)cryptHash
                 cryptIv:(NSData *)cryptIv
{
    // !!! assert that data lengths are correct -denis
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_UPDATE_COMMIT];
    [binary putUInt32:flags];
    [binary putUInt32:length];
    [binary putData:hash]; // 20 bytes
    [binary putData:cryptHash]; // 20 bytes
    [binary putData:cryptIv]; // 16 bytes
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)updateCommit:(id<FDFireflyIceChannel>)channel data:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    uint8_t result = [binary getUInt8];
    
    [_observable fireflyIceUpdateCommit:channel result:result];
}

- (void)radioDirectTestModeReport:(id<FDFireflyIceChannel>)channel data:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    uint16_t result = [binary getUInt16];
    
    [_observable fireflyIceDirectTestModeReport:channel result:result];
}

- (void)updateGetSectorHashes:(id<FDFireflyIceChannel>)channel data:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    uint8_t sectorCount = [binary getUInt8];
    NSMutableArray *sectorHashes = [NSMutableArray array];
    for (NSUInteger i = 0; i < sectorCount; ++i) {
        uint16_t sector = [binary getUInt16];
        NSData *hash = [binary getData:HASH_SIZE];
        FDFireflyIceSectorHash *sectorHash = [[FDFireflyIceSectorHash alloc] init];
        sectorHash.sector = sector;
        sectorHash.hash = hash;
        [sectorHashes addObject:sectorHash];
    }
    
    [_observable fireflyIceSectorHashes:channel sectorHashes:sectorHashes];
}

static
void putColor(FDBinary *binary, uint32_t color) {
    [binary putUInt8:color >> 16];
    [binary putUInt8:color >> 8];
    [binary putUInt8:color];
}

- (void)sendIndicatorOverride:(id<FDFireflyIceChannel>)channel
                    usbOrange:(uint8_t)usbOrange
                     usbGreen:(uint8_t)usbGreen
                           d0:(uint8_t)d0
                           d1:(uint32_t)d1
                           d2:(uint32_t)d2
                           d3:(uint32_t)d3
                           d4:(uint8_t)d4
                     duration:(NSTimeInterval)duration
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_INDICATOR_OVERRIDE];

    [binary putUInt8:usbOrange];
    [binary putUInt8:usbGreen];
    [binary putUInt8:d0];
    putColor(binary, d1);
    putColor(binary, d2);
    putColor(binary, d3);
    [binary putUInt8:d4];
    [binary putTime64:duration];

    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendSyncStart:(id<FDFireflyIceChannel>)channel
{
    uint8_t bytes[] = {FD_CONTROL_SYNC_START};
    [channel fireflyIceChannelSend:[NSData dataWithBytes:&bytes length:sizeof(bytes)]];
}

- (void)syncData:(id<FDFireflyIceChannel>)channel data:(NSData *)data
{
    [_observable fireflyIceSyncData:channel data:data];
}

- (void)sensing:(id<FDFireflyIceChannel>)channel data:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    float ax = [binary getFloat32];
    float ay = [binary getFloat32];
    float az = [binary getFloat32];
    float mx = [binary getFloat32];
    float my = [binary getFloat32];
    float mz = [binary getFloat32];
    
    [_observable fireflyIceSensing:channel ax:ax ay:ay az:az mx:mx my:my mz:mz];
}

- (void)fireflyIceChannelPacket:(id<FDFireflyIceChannel>)channel data:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    uint8_t code = [binary getUInt8];
    NSData *remaining = [data subdataWithRange:NSMakeRange(1, data.length - 1)];
    switch (code) {
        case FD_CONTROL_PING:
            [self ping:channel data:remaining];
            break;
        case FD_CONTROL_GET_PROPERTIES:
            [self getProperties:channel data:remaining];
            break;
        case FD_CONTROL_UPDATE_COMMIT:
            [self updateCommit:channel data:remaining];
            break;
        case FD_CONTROL_RADIO_DIRECT_TEST_MODE_REPORT:
            [self radioDirectTestModeReport:channel data:remaining];
            break;

        case FD_CONTROL_UPDATE_GET_SECTOR_HASHES:
            [self updateGetSectorHashes:channel data:remaining];
            break;
            
        case FD_CONTROL_SYNC_DATA:
            [self syncData:channel data:remaining];
            break;

        case 0xff:
            [self sensing:channel data:remaining];
            break;
    }
}

@end
