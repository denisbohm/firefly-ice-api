//
//  FDFireflyIceCoder.m
//  Sync
//
//  Created by Denis Bohm on 7/19/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDBinary.h"
#import "FDFireflyIce.h"
#import "FDFireflyIceChannel.h"
#import "FDFireflyIceCoder.h"

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

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel ping:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    uint16_t length = [binary getUInt16];
    NSData *pingData = [binary getData:length];
    
    [_observable fireflyIce:fireflyIce channel:channel ping:pingData];
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

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel getPropertyVersion:(FDBinary *)binary
{
    FDFireflyIceVersion *version = [[FDFireflyIceVersion alloc] init];
    version.major = [binary getUInt16];
    version.minor = [binary getUInt16];
    version.patch = [binary getUInt16];
    version.capabilities = [binary getUInt32];
    version.gitCommit = [binary getData:20];
    
    [_observable fireflyIce:fireflyIce channel:channel version:version];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel getPropertyBootVersion:(FDBinary *)binary
{
    FDFireflyIceVersion *version = [[FDFireflyIceVersion alloc] init];
    version.major = [binary getUInt16];
    version.minor = [binary getUInt16];
    version.patch = [binary getUInt16];
    version.capabilities = [binary getUInt32];
    version.gitCommit = [binary getData:20];
    
    [_observable fireflyIce:fireflyIce channel:channel bootVersion:version];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel getPropertyHardwareId:(FDBinary *)binary
{
    FDFireflyIceHardwareId *hardwareId = [[FDFireflyIceHardwareId alloc] init];
    hardwareId.vendor = [binary getUInt16];
    hardwareId.product = [binary getUInt16];
    hardwareId.major = [binary getUInt16];
    hardwareId.minor = [binary getUInt16];
    hardwareId.unique = [binary getData:8];
    
    [_observable fireflyIce:fireflyIce channel:channel hardwareId:hardwareId];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel getPropertyDebugLock:(FDBinary *)binary
{
    NSNumber *debugLock = [binary getUInt8] ? @YES : @NO;
    
    [_observable fireflyIce:fireflyIce channel:channel debugLock:debugLock];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel getPropertyRTC:(FDBinary *)binary
{
    NSTimeInterval time = [binary getTime64];
    
    [_observable fireflyIce:fireflyIce channel:channel time:[NSDate dateWithTimeIntervalSince1970:time]];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel getPropertyPower:(FDBinary *)binary
{
    FDFireflyIcePower *power = [[FDFireflyIcePower alloc] init];
    power.batteryLevel = [binary getFloat32];
    power.batteryVoltage = [binary getFloat32];
    power.isUSBPowered = [binary getUInt8] ? YES : NO;
    power.isCharging = [binary getUInt8] ? YES : NO;
    power.chargeCurrent = [binary getFloat32];
    power.temperature = [binary getFloat32];
    
    [_observable fireflyIce:fireflyIce channel:channel power:power];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel getPropertySite:(FDBinary *)binary
{
    uint16_t length = [binary getUInt16];
    NSData *data = [binary getData:length];
    NSString *site = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [_observable fireflyIce:fireflyIce channel:channel site:site];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel getPropertyReset:(FDBinary *)binary
{
    FDFireflyIceReset *reset = [[FDFireflyIceReset alloc] init];
    reset.cause = [binary getUInt32];
    reset.date = [NSDate dateWithTimeIntervalSince1970:[binary getTime64]];
    
    [_observable fireflyIce:fireflyIce channel:channel reset:reset];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel getPropertyStorage:(FDBinary *)binary
{
    FDFireflyIceStorage *storage = [[FDFireflyIceStorage alloc] init];
    storage.pageCount = [binary getUInt32];
    
    [_observable fireflyIce:fireflyIce channel:channel storage:storage];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel getPropertyMode:(FDBinary *)binary
{
    NSNumber *mode = [NSNumber numberWithUnsignedChar:[binary getUInt8]];
    
    [_observable fireflyIce:fireflyIce channel:channel mode:mode];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel getPropertyTxPower:(FDBinary *)binary
{
    NSNumber *level = [NSNumber numberWithUnsignedChar:[binary getUInt8]];
    
    [_observable fireflyIce:fireflyIce channel:channel txPower:level];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel getPropertyLogging:(FDBinary *)binary
{
    FDFireflyIceLogging *logging = [[FDFireflyIceLogging alloc] init];
    logging.flags = [binary getUInt32];
    if (logging.flags & FD_CONTROL_LOGGING_STATE) {
        logging.state = [binary getUInt32];
    }
    if (logging.flags & FD_CONTROL_LOGGING_COUNT) {
        logging.count = [binary getUInt32];
    }
    
    [_observable fireflyIce:fireflyIce channel:channel logging:logging];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel getPropertyName:(FDBinary *)binary
{
    uint8_t length = [binary getUInt8];
    NSData *data = [binary getData:length];
    NSString *name = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [_observable fireflyIce:fireflyIce channel:channel name:name];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel getPropertyRetained:(FDBinary *)binary
{
    FDFireflyIceRetained *retained = [[FDFireflyIceRetained alloc] init];
    retained.retained = [binary getUInt8] != 0;
    uint32_t length = [binary getUInt32];
    retained.data = [binary getData:length];
    
    [_observable fireflyIce:fireflyIce channel:channel retained:retained];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel getProperties:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    uint32_t properties = [binary getUInt32];
    if (properties & FD_CONTROL_PROPERTY_VERSION) {
        [self fireflyIce:fireflyIce channel:channel getPropertyVersion:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_HARDWARE_ID) {
        [self fireflyIce:fireflyIce channel:channel getPropertyHardwareId:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_DEBUG_LOCK) {
        [self fireflyIce:fireflyIce channel:channel getPropertyDebugLock:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_RTC) {
        [self fireflyIce:fireflyIce channel:channel getPropertyRTC:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_POWER) {
        [self fireflyIce:fireflyIce channel:channel getPropertyPower:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_SITE) {
        [self fireflyIce:fireflyIce channel:channel getPropertySite:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_RESET) {
        [self fireflyIce:fireflyIce channel:channel getPropertyReset:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_STORAGE) {
        [self fireflyIce:fireflyIce channel:channel getPropertyStorage:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_MODE) {
        [self fireflyIce:fireflyIce channel:channel getPropertyMode:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_TX_POWER) {
        [self fireflyIce:fireflyIce channel:channel getPropertyTxPower:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_BOOT_VERSION) {
        [self fireflyIce:fireflyIce channel:channel getPropertyBootVersion:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_LOGGING) {
        [self fireflyIce:fireflyIce channel:channel getPropertyLogging:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_NAME) {
        [self fireflyIce:fireflyIce channel:channel getPropertyName:binary];
    }
    if (properties & FD_CONTROL_PROPERTY_RETAINED) {
        [self fireflyIce:fireflyIce channel:channel getPropertyRetained:binary];
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

- (void)sendSetPropertyMode:(id<FDFireflyIceChannel>)channel mode:(uint8_t)mode
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_SET_PROPERTIES];
    [binary putUInt32:FD_CONTROL_PROPERTY_MODE];
    [binary putUInt8:mode];
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendSetPropertyTxPower:(id<FDFireflyIceChannel>)channel level:(uint8_t)level
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_SET_PROPERTIES];
    [binary putUInt32:FD_CONTROL_PROPERTY_TX_POWER];
    [binary putUInt8:level];
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendSetPropertyLogging:(id<FDFireflyIceChannel>)channel storage:(BOOL)storage
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_SET_PROPERTIES];
    [binary putUInt32:FD_CONTROL_PROPERTY_LOGGING];
    [binary putUInt32:FD_CONTROL_LOGGING_STATE];
    [binary putUInt32:FD_CONTROL_LOGGING_STORAGE];
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendSetPropertyName:(id<FDFireflyIceChannel>)channel name:(NSString *)name
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_SET_PROPERTIES];
    [binary putUInt32:FD_CONTROL_PROPERTY_NAME];
    NSData *data = [name dataUsingEncoding:NSUTF8StringEncoding];
    [binary putUInt8:data.length];
    [binary putData:data];
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendUpdateGetExternalHash:(id<FDFireflyIceChannel>)channel address:(uint32_t)address length:(uint32_t)length
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_UPDATE_GET_EXTERNAL_HASH];
    [binary putUInt32:address];
    [binary putUInt32:length];
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendUpdateReadPage:(id<FDFireflyIceChannel>)channel page:(uint32_t)page
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_UPDATE_READ_PAGE];
    [binary putUInt32:page];
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

+ (uint16_t)makeDirectTestModePacket:(FDDirectTestModeCommand)command
                           frequency:(uint8_t)frequency
                              length:(uint8_t)length
                                type:(FDDirectTestModePacketType)type
{
    return (command << 14) | ((frequency & 0x3f) << 8) | ((length & 0x3f) << 2) | type;
}

- (void)sendDirectTestModeEnter:(id<FDFireflyIceChannel>)channel
                         packet:(uint16_t)packet
                       duration:(NSTimeInterval)duration
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_RADIO_DIRECT_TEST_MODE_ENTER];
    [binary putUInt16:packet];
    [binary putTime64:duration];
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendDirectTestModeExit:(id<FDFireflyIceChannel>)channel
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_RADIO_DIRECT_TEST_MODE_EXIT];
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendDirectTestModeReport:(id<FDFireflyIceChannel>)channel
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_RADIO_DIRECT_TEST_MODE_REPORT];
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendDirectTestModeReset:(id<FDFireflyIceChannel>)channel
{
    [self sendDirectTestModeEnter:channel packet:[FDFireflyIceCoder makeDirectTestModePacket:FDDirectTestModeCommandReset frequency:0 length:0 type:0] duration:0];
}

- (void)sendDirectTestModeReceiverTest:(id<FDFireflyIceChannel>)channel
                             frequency:(uint8_t)frequency
                                length:(uint8_t)length
                                  type:(FDDirectTestModePacketType)type
                              duration:(NSTimeInterval)duration
{
    [self sendDirectTestModeEnter:channel packet:[FDFireflyIceCoder makeDirectTestModePacket:FDDirectTestModeCommandReceiverTest frequency:frequency length:length type:type] duration:duration];
}

- (void)sendDirectTestModeTransmitterTest:(id<FDFireflyIceChannel>)channel
                                frequency:(uint8_t)frequency
                                   length:(uint8_t)length
                                     type:(FDDirectTestModePacketType)type
                                 duration:(NSTimeInterval)duration
{
    [self sendDirectTestModeEnter:channel packet:[FDFireflyIceCoder makeDirectTestModePacket:FDDirectTestModeCommandTransmitterTest frequency:frequency length:length type:type] duration:duration];
}

- (void)sendDirectTestModeEnd:(id<FDFireflyIceChannel>)channel
{
    [self sendDirectTestModeEnter:channel packet:[FDFireflyIceCoder makeDirectTestModePacket:FDDirectTestModeCommandTestEnd frequency:0 length:0 type:0] duration:0];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel updateCommit:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    FDFireflyIceUpdateCommit *updateCommit = [[FDFireflyIceUpdateCommit alloc] init];
    updateCommit.result = [binary getUInt8];
    
    [_observable fireflyIce:fireflyIce channel:channel updateCommit:updateCommit];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel radioDirectTestModeReport:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    FDFireflyIceDirectTestModeReport *report = [[FDFireflyIceDirectTestModeReport alloc] init];
    report.packetCount = [binary getUInt16];
    
    [_observable fireflyIce:fireflyIce channel:channel directTestModeReport:report];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel updateGetSectorHashes:(NSData *)data
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
    
    [_observable fireflyIce:fireflyIce channel:channel sectorHashes:sectorHashes];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel updateGetExternalHash:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    NSData *externalHash = [binary getData:HASH_SIZE];
    
    [_observable fireflyIce:fireflyIce channel:channel externalHash:externalHash];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel updateReadPage:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    NSData *pageData = [binary getData:256];
    
    [_observable fireflyIce:fireflyIce channel:channel pageData:pageData];
}

static
void putColor(FDBinary *binary, uint32_t color) {
    [binary putUInt8:color >> 16];
    [binary putUInt8:color >> 8];
    [binary putUInt8:color];
}

- (void)sendLEDOverride:(id<FDFireflyIceChannel>)channel
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
    [binary putUInt8:FD_CONTROL_LED_OVERRIDE];

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

- (void)sendIdentify:(id<FDFireflyIceChannel>)channel duration:(NSTimeInterval)duration
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_IDENTIFY];
    
    [binary putUInt8:1];
    [binary putTime64:duration];
    
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendLock:(id<FDFireflyIceChannel>)channel identifier:(fd_lock_identifier_t)identifier operation:(fd_lock_operation_t)operation
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_LOCK];
    
    [binary putUInt8:identifier];
    [binary putUInt8:operation];
    
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendSyncStart:(id<FDFireflyIceChannel>)channel
{
    uint8_t bytes[] = {FD_CONTROL_SYNC_START};
    [channel fireflyIceChannelSend:[NSData dataWithBytes:&bytes length:sizeof(bytes)]];
}

- (void)sendSyncStart:(id<FDFireflyIceChannel>)channel offset:(uint32_t)offset
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_SYNC_START];
    [binary putUInt32:FD_CONTROL_SYNC_AHEAD];
    [binary putUInt32:offset];
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)sendDiagnostics:(id<FDFireflyIceChannel>)channel flags:(uint32_t)flags
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:FD_CONTROL_DIAGNOSTICS];
    [binary putUInt32:flags];
    [channel fireflyIceChannelSend:binary.dataValue];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel diagnostics:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    FDFireflyIceDiagnostics *diagnostics = [[FDFireflyIceDiagnostics alloc] init];
    diagnostics.flags = [binary getUInt32];
    NSMutableArray *values = [NSMutableArray array];
    if (diagnostics.flags & FD_CONTROL_DIAGNOSTICS_BLE) {
        FDFireflyIceDiagnosticsBLE *value = [[FDFireflyIceDiagnosticsBLE alloc] init];
        uint32_t length = [binary getUInt32];
        NSUInteger position = binary.getIndex;
        value.version = [binary getUInt32];
        value.systemSteps = [binary getUInt32];
        value.dataSteps = [binary getUInt32];
        value.systemCredits = [binary getUInt32];
        value.dataCredits = [binary getUInt32];
        value.txPower = [binary getUInt8];
        value.operatingMode = [binary getUInt8];
        value.idle = [binary getUInt8] != 0;
        value.dtm = [binary getUInt8] != 0;
        value.did = [binary getUInt8];
        value.disconnectAction = [binary getUInt8];
        value.pipesOpen = [binary getUInt64];
        value.dtmRequest = [binary getUInt16];
        value.dtmData = [binary getUInt16];
        value.bufferCount = [binary getUInt32];
        binary.getIndex = (uint32_t)(position + length);
        [values addObject:value];
    }
    if (diagnostics.flags & FD_CONTROL_DIAGNOSTICS_BLE_TIMING) {
        uint16_t connectionInterval = [binary getUInt16];
        uint16_t slaveLatency = [binary getUInt16];
        uint16_t supervisionTimeout = [binary getUInt16];
        NSLog(@"BLE timing: %u %u %u", connectionInterval, slaveLatency, supervisionTimeout);
    }
    diagnostics.values = values;
    [_observable fireflyIce:fireflyIce channel:channel diagnostics:diagnostics];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel lock:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    FDFireflyIceLock *lock = [[FDFireflyIceLock alloc] init];
    lock.identifier = [binary getUInt8];
    lock.operation = [binary getUInt8];
    lock.owner = [binary getUInt32];
    
    [_observable fireflyIce:fireflyIce channel:channel lock:lock];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel syncData:(NSData *)data
{
    [_observable fireflyIce:fireflyIce channel:channel syncData:data];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel sensing:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    FDFireflyIceSensing *sensing = [[FDFireflyIceSensing alloc] init];
    sensing.ax = [binary getFloat32];
    sensing.ay = [binary getFloat32];
    sensing.az = [binary getFloat32];
    sensing.mx = [binary getFloat32];
    sensing.my = [binary getFloat32];
    sensing.mz = [binary getFloat32];
    
    [_observable fireflyIce:fireflyIce channel:channel sensing:sensing];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel packet:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    uint8_t code = [binary getUInt8];
    NSData *remaining = [data subdataWithRange:NSMakeRange(1, data.length - 1)];
    switch (code) {
        case FD_CONTROL_PING:
            [self fireflyIce:fireflyIce channel:channel ping:remaining];
            break;
        case FD_CONTROL_GET_PROPERTIES:
            [self fireflyIce:fireflyIce channel:channel getProperties:remaining];
            break;
        case FD_CONTROL_UPDATE_COMMIT:
            [self fireflyIce:fireflyIce channel:channel updateCommit:remaining];
            break;
        case FD_CONTROL_RADIO_DIRECT_TEST_MODE_REPORT:
            [self fireflyIce:fireflyIce channel:channel radioDirectTestModeReport:remaining];
            break;

        case FD_CONTROL_UPDATE_GET_EXTERNAL_HASH:
            [self fireflyIce:fireflyIce channel:channel updateGetExternalHash:remaining];
            break;
        case FD_CONTROL_UPDATE_READ_PAGE:
            [self fireflyIce:fireflyIce channel:channel updateReadPage:remaining];
            break;
            
        case FD_CONTROL_UPDATE_GET_SECTOR_HASHES:
            [self fireflyIce:fireflyIce channel:channel updateGetSectorHashes:remaining];
            break;
            
        case FD_CONTROL_LOCK:
            [self fireflyIce:fireflyIce channel:channel lock:remaining];
            break;
            
        case FD_CONTROL_SYNC_DATA:
            [self fireflyIce:fireflyIce channel:channel syncData:remaining];
            break;
            
        case FD_CONTROL_DIAGNOSTICS:
            [self fireflyIce:fireflyIce channel:channel diagnostics:remaining];
            break;
            
        case 0xff:
            [self fireflyIce:fireflyIce channel:channel sensing:remaining];
            break;
    }
}

@end
