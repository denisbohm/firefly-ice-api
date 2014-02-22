//
//  FDFireflyIceChannelMock.m
//  FireflyDevice
//
//  Created by Denis Bohm on 2/22/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDBinary.h"
#import "FDCrypto.h"
#import "FDFireflyIce.h"
#import "FDFireflyIceCoder.h"
#import "FDFireflyIceChannelMock.h"

@interface FDFireflyIceChannelMock ()

@property FDFireflyIceChannelStatus status;

@end

@implementation FDFireflyIceChannelMock

@synthesize log;

- (NSString *)name
{
    return @"Mock";
}

- (void)open
{
    self.status = FDFireflyIceChannelStatusOpening;
    if ([_delegate respondsToSelector:@selector(fireflyIceChannel:status:)]) {
        [_delegate fireflyIceChannel:self status:self.status];
    }
    self.status = FDFireflyIceChannelStatusOpen;
    if ([_delegate respondsToSelector:@selector(fireflyIceChannel:status:)]) {
        [_delegate fireflyIceChannel:self status:self.status];
    }
}

- (void)close
{
    self.status = FDFireflyIceChannelStatusClosed;
    if ([_delegate respondsToSelector:@selector(fireflyIceChannel:status:)]) {
        [_delegate fireflyIceChannel:self status:self.status];
    }
}

- (void)fireflyIceChannelSend:(NSData *)data
{
    [self processCommand:data];
}

- (FDBinary *)sendStart:(uint8_t)type
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt8:type];
    return binary;
}

- (void)sendComplete:(FDBinary *)binary
{
    if ([_delegate respondsToSelector:@selector(fireflyIceChannelPacket:data:)]) {
        [_delegate fireflyIceChannelPacket:self data:binary.dataValue];
    }
}

- (void)ping:(FDBinary *)binary
{
    uint16_t pingLength = [binary getUInt16];
    NSData *pingData = [binary getData:pingLength];
    
    FDBinary *binaryOut = [self sendStart:FD_CONTROL_PING];
    [binaryOut putUInt16:pingLength];
    [binaryOut putData:pingData];
    [self sendComplete:binaryOut];
}

- (void)provision:(FDBinary *)binary {
    uint32_t options = [binary getUInt32];
    uint32_t provision_data_length = [binary getUInt16];
    _device.provisionData = [binary getData:provision_data_length];
    
    if (options & FD_CONTROL_PROVISION_OPTION_DEBUG_LOCK) {
        _device.debugLock = YES;
    }
    if (options & FD_CONTROL_PROVISION_OPTION_RESET) {
        _device.resetLastCause = 64; // system request reset
        _device.resetLastTime = [NSDate date];
    }
}

- (void)reset:(FDBinary *)binary {
    uint8_t type = [binary getUInt8];
    switch (type) {
        case FD_CONTROL_RESET_SYSTEM_REQUEST: {
            _device.resetLastCause = 64; // system request reset
            _device.resetLastTime = [NSDate date];
        } break;
        case FD_CONTROL_RESET_WATCHDOG: {
            _device.resetLastCause = 16; // watchdog reset
            _device.resetLastTime = [NSDate date];
        } break;
        case FD_CONTROL_RESET_HARD_FAULT: {
            _device.resetLastCause = 32; // lockup reset
            _device.resetLastTime = [NSDate date];
        } break;
    }
}

- (void)getPropertyVersion:(FDBinary *)binary
{
    [binary putUInt16:_device.versionMajor];
    [binary putUInt16:_device.versionMinor];
    [binary putUInt16:_device.versionPatch];
    [binary putUInt32:_device.versionCapabilities];
    [binary putData:_device.versionGitCommit];
}

- (void)getPropertyHardwareId:(FDBinary *)binary
{
    // 16 byte hardware id: vendor, product, version (major, minor), unique id
    [binary putUInt16:_device.hardwareVendor];
    [binary putUInt16:_device.hardwareProduct];
    [binary putUInt16:_device.hardwareMajor];
    [binary putUInt16:_device.hardwareMinor];
    [binary putData:_device.hardwareUUID];
}

- (void)getPropertySite:(FDBinary *)binary
{
    [binary putUInt16:_device.site.length];
    [binary putData:[_device.site dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)getPropertyReset:(FDBinary *)binary
{
    [binary putUInt32:_device.resetLastCause];
    [binary putTime64:[_device.resetLastTime timeIntervalSince1970]];
}

- (void)getPropertyRetained:(FDBinary *)binary
{
    NSLog(@"mock get property retained");
    /*
    [binary putUInt8:fd_reset_retained_was_valid_on_startup());
    [binary putUInt32:sizeof(fd_reset_retained_at_initialize));
    fd_binary_put_bytes(binary, (uint8_t *)&fd_reset_retained_at_initialize, sizeof(fd_reset_retained_at_initialize));
     */
}

- (void)getPropertyStorage:(FDBinary *)binary
{
    [binary putUInt32:0];
}

- (void)getPropertyDebugLock:(FDBinary *)binary
{
    [binary putUInt8:_device.debugLock ? 1 : 0];
}

- (void)setPropertyDebugLock:(FDBinary *)binary
{
    _device.debugLock = YES;
}

- (void)getPropertyRtc:(FDBinary *)binary
{
    [binary putTime64:[[NSDate date] timeIntervalSince1970]];
}

- (void)setPropertyRtc:(FDBinary *)binary
{
    NSTimeInterval time = [binary getTime64];
    NSLog(@"mock set time %0.6f", time);
}

- (void)getPropertyPower:(FDBinary *)binary
{
    [binary putFloat32:_device.power.batteryLevel];
    [binary putFloat32:_device.power.batteryVoltage];
    [binary putUInt8:_device.power.isUSBPowered];
    [binary putUInt8:_device.power.isCharging];
    [binary putFloat32:_device.power.chargeCurrent];
    [binary putFloat32:_device.power.temperature];
}

- (void)setPropertyPower:(FDBinary *)binary
{
    _device.power.batteryLevel = [binary getFloat32];
}

- (void)getPropertyMode:(FDBinary *)binary
{
    [binary putUInt8:0]; // run mode
}

- (void)setPropertyMode:(FDBinary *)binary
{
    uint8_t mode = [binary getUInt8];
    NSLog(@"mock set mode %u", mode);
}

- (void)getPropertyTxPower:(FDBinary *)binary
{
    [binary putUInt8:_device.txPower];
}

- (void)setPropertyTxPower:(FDBinary *)binary
{
    _device.txPower = [binary getUInt8];
}

- (void)getPropertyBootVersion:(FDBinary *)binary
{
    [binary putUInt16:_device.bootMajor];
    [binary putUInt16:_device.bootMinor];
    [binary putUInt16:_device.bootPatch];
    [binary putUInt32:_device.bootCapabilities];
    [binary putData:_device.bootGitCommit];
}

- (void)getPropertyLogging:(FDBinary *)binary
{
    [binary putUInt32:FD_CONTROL_LOGGING_STATE | FD_CONTROL_LOGGING_COUNT];
    [binary putUInt32:_device.logStorage ? FD_CONTROL_LOGGING_STORAGE : 0];
    [binary putUInt32:_device.logCount];
}

- (void)setPropertyLogging:(FDBinary *)binary
{
    uint32_t flags = [binary getUInt32];
    if (flags & FD_CONTROL_LOGGING_STATE) {
        uint32_t state = [binary getUInt32];
        _device.logStorage = (state & FD_CONTROL_LOGGING_STORAGE) != 0;
    }
    if (flags & FD_CONTROL_LOGGING_COUNT) {
        _device.logCount = [binary getUInt32];
    }
}

- (void)getPropertyName:(FDBinary *)binary
{
    [binary putUInt8:_device.name.length];
    [binary putData:[_device.name dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)setPropertyName:(FDBinary *)binary
{
    uint8_t length = [binary getUInt8];
    _device.name = [[NSString alloc] initWithData:[binary getData:length] encoding:NSUTF8StringEncoding];
}

#define GET_PROPERTY_MASK \
(FD_CONTROL_PROPERTY_VERSION |\
FD_CONTROL_PROPERTY_HARDWARE_ID |\
FD_CONTROL_PROPERTY_DEBUG_LOCK |\
FD_CONTROL_PROPERTY_RTC |\
FD_CONTROL_PROPERTY_POWER |\
FD_CONTROL_PROPERTY_SITE |\
FD_CONTROL_PROPERTY_RESET |\
FD_CONTROL_PROPERTY_STORAGE |\
FD_CONTROL_PROPERTY_MODE |\
FD_CONTROL_PROPERTY_TX_POWER |\
FD_CONTROL_PROPERTY_BOOT_VERSION |\
FD_CONTROL_PROPERTY_LOGGING |\
FD_CONTROL_PROPERTY_NAME |\
FD_CONTROL_PROPERTY_RETAINED)

- (void)getProperties:(FDBinary *)binary
{
    uint32_t properties = [binary getUInt32];
    
    FDBinary *binaryOut = [self sendStart:FD_CONTROL_GET_PROPERTIES];
    [binaryOut putUInt32:properties & GET_PROPERTY_MASK];
    for (uint32_t property = 1; property != 0; property <<= 1) {
        if (property & properties) {
            switch (property) {
                case FD_CONTROL_PROPERTY_VERSION: {
                    [self getPropertyVersion:binaryOut];
                } break;
                case FD_CONTROL_PROPERTY_HARDWARE_ID: {
                    [self getPropertyHardwareId:binaryOut];
                } break;
                case FD_CONTROL_PROPERTY_DEBUG_LOCK: {
                    [self getPropertyDebugLock:binaryOut];
                } break;
                case FD_CONTROL_PROPERTY_RTC: {
                    [self getPropertyRtc:binaryOut];
                } break;
                case FD_CONTROL_PROPERTY_POWER: {
                    [self getPropertyPower:binaryOut];
                } break;
                case FD_CONTROL_PROPERTY_SITE: {
                    [self getPropertySite:binaryOut];
                } break;
                case FD_CONTROL_PROPERTY_RESET: {
                    [self getPropertyReset:binaryOut];
                } break;
                case FD_CONTROL_PROPERTY_STORAGE: {
                    [self getPropertyStorage:binaryOut];
                } break;
                case FD_CONTROL_PROPERTY_MODE: {
                    [self getPropertyMode:binaryOut];
                } break;
                case FD_CONTROL_PROPERTY_TX_POWER: {
                    [self getPropertyTxPower:binaryOut];
                } break;
                case FD_CONTROL_PROPERTY_BOOT_VERSION: {
                    [self getPropertyBootVersion:binaryOut];
                } break;
                case FD_CONTROL_PROPERTY_LOGGING: {
                    [self getPropertyLogging:binaryOut];
                } break;
                case FD_CONTROL_PROPERTY_NAME: {
                    [self getPropertyName:binaryOut];
                } break;
                case FD_CONTROL_PROPERTY_RETAINED: {
                    [self getPropertyRetained:binaryOut];
                } break;
            }
        }
    }
    [self sendComplete:binaryOut];
}

- (void)setProperties:(FDBinary *)binary {
    uint32_t properties = [binary getUInt32];
    for (uint32_t property = 1; property != 0; property <<= 1) {
        if (property & properties) {
            switch (property) {
                case FD_CONTROL_PROPERTY_DEBUG_LOCK: {
                    [self setPropertyDebugLock:binary];
                } break;
                case FD_CONTROL_PROPERTY_RTC: {
                    [self setPropertyRtc:binary];
                } break;
                case FD_CONTROL_PROPERTY_POWER: {
                    [self setPropertyPower:binary];
                } break;
                case FD_CONTROL_PROPERTY_MODE: {
                    [self setPropertyMode:binary];
                } break;
                case FD_CONTROL_PROPERTY_TX_POWER: {
                    [self setPropertyTxPower:binary];
                } break;
                case FD_CONTROL_PROPERTY_LOGGING: {
                    [self setPropertyLogging:binary];
                } break;
                case FD_CONTROL_PROPERTY_NAME: {
                    [self setPropertyName:binary];
                } break;
            }
        }
    }
}

- (void)updateGetExternalHash:(FDBinary *)binary
{
    uint32_t external_address = [binary getUInt32];
    uint32_t external_length = [binary getUInt32];
    NSData *data = [_device.externalData subdataWithRange:NSMakeRange(external_address, external_length)];
    NSData *hash = [FDCrypto sha1:data];
    FDBinary *binaryOut = [self sendStart:FD_CONTROL_UPDATE_GET_EXTERNAL_HASH];
    [binaryOut putData:hash];
    [self sendComplete:binaryOut];
}

- (void)updateReadPage:(FDBinary *)binary
{
    uint32_t page = [binary getUInt32];
    NSData *page_data = [_device.externalData subdataWithRange:NSMakeRange(page * 256, 256)];
    FDBinary *binaryOut = [self sendStart:FD_CONTROL_UPDATE_READ_PAGE];
    [binaryOut putData:page_data];
    [self sendComplete:binaryOut];
}

- (void)updateGetSectorHashes:(FDBinary *)binary
{
    uint32_t sector_count = [binary getUInt8];
    
    FDBinary *binaryOut = [self sendStart:FD_CONTROL_UPDATE_GET_SECTOR_HASHES];
    [binaryOut putUInt8:sector_count];
    for (uint32_t i = 0; i < sector_count; ++i) {
        uint32_t sector = [binary getUInt16];
        NSData *data = [_device.externalData subdataWithRange:NSMakeRange(sector * 16 * 256, 16 * 256)];
        NSData *hash = [FDCrypto sha1:data];
        [binaryOut putUInt16:sector];
        [binaryOut putData:hash];
    }
    [self sendComplete:binaryOut];
}

- (void)updateEraseSectors:(FDBinary *)binary
{
    uint32_t sector_count = [binary getUInt8];
    for (uint32_t i = 0; i < sector_count; ++i) {
        uint32_t sector = [binary getUInt16];
        NSUInteger index = sector * 16 * 256;
        NSMutableData *data = [NSMutableData data];
        data.length = 16 * 256;
        [_device.externalData replaceBytesInRange:NSMakeRange(index, data.length) withBytes:data.bytes];
    }
}

- (void)updateWritePage:(FDBinary *)binary
{
    uint32_t page = [binary getUInt16];
    NSData *page_data = [binary getData:256];
    [_device.externalData replaceBytesInRange:NSMakeRange(page * 256, 256) withBytes:page_data.bytes];
}

#define FD_SHA_HASH_SIZE 20

- (void)updateCommit:(FDBinary *)binary
{
//    uint32_t flags = [binary getUInt32];
//    uint32_t length = [binary getUInt32];
//    NSData *hash = [binary getData:FD_SHA_HASH_SIZE];
//    NSData *crypt_hash = [binary getData:FD_SHA_HASH_SIZE];
//    NSData *crypt_iv = [binary getData:16];
    
    uint8_t result = FD_UPDATE_COMMIT_SUCCESS;
    
    FDBinary *binaryOut = [self sendStart:FD_CONTROL_UPDATE_COMMIT];
    [binaryOut putUInt8:result];
    [self sendComplete:binaryOut];
}

- (void)radioDirectTestModeEnter:(FDBinary *)binary
{
    uint16_t request = [binary getUInt16];
//    NSTimeInterval duration = [binary getTime64];
    
    switch ((request >> 14) & 0x03) {
        case FDDirectTestModeCommandReset:
            _device.directTestModeReport = 0;
            break;
        case FDDirectTestModeCommandReceiverTest:
            _device.directTestModeReport = 0x8000 | 43;
            break;
        case FDDirectTestModeCommandTransmitterTest:
            _device.directTestModeReport = 0;
            break;
        case FDDirectTestModeCommandTestEnd:
            _device.directTestModeReport = 0;
            break;
    }
}

- (void)radioDirectTestModeExit:(FDBinary *)binary
{
}

- (void)radioDirectTestModeReport:(FDBinary *)binary
{
    FDBinary *binaryOut = [self sendStart:FD_CONTROL_RADIO_DIRECT_TEST_MODE_REPORT];
    [binaryOut putUInt16:_device.directTestModeReport];
    [self sendComplete:binaryOut];
}

- (void)disconnect:(FDBinary *)binary {
}

- (void)ledOverride:(FDBinary *)binary {
}

- (void)identify:(FDBinary *)binary {
}

- (void)syncStart:(FDBinary *)binary {
}

- (void)syncAck:(FDBinary *)binary {
}

- (void)lock:(FDBinary *)binary
{
    fd_lock_identifier_t identifier = [binary getUInt8];
    fd_lock_operation_t operation = [binary getUInt8];
    fd_lock_owner_t lock_owner = fd_lock_owner_ble;
    
    FDBinary *binaryOut = [self sendStart:FD_CONTROL_LOCK];
    [binaryOut putUInt8:identifier];
    [binaryOut putUInt8:operation];
    [binaryOut putUInt32:lock_owner];
    [self sendComplete:binaryOut];
}

#define FD_CONTROL_DIAGNOSTICS_FLAGS (FD_CONTROL_DIAGNOSTICS_BLE | FD_CONTROL_DIAGNOSTICS_BLE_TIMING)

- (void)diagnostics:(FDBinary *)binary
{
    uint32_t flags = [binary getUInt32];
    
    FDBinary *binaryOut = [self sendStart:FD_CONTROL_DIAGNOSTICS];
    [binaryOut putUInt32:flags & FD_CONTROL_DIAGNOSTICS_FLAGS];
    if (flags & FD_CONTROL_DIAGNOSTICS_BLE) {
//        fd_bluetooth_diagnostics(binaryOut);
    }
    if (flags & FD_CONTROL_DIAGNOSTICS_BLE_TIMING) {
//        fd_bluetooth_diagnostics_timing(binaryOut);
    }
    [self sendComplete:binaryOut];
}

- (void)processCommand:(NSData *)data {
    if (data.length < 1) {
        return;
    }
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    uint8_t code = [binary getUInt8];
    switch (code) {
        case FD_CONTROL_PING:
            [self ping:binary];
            break;
            
        case FD_CONTROL_GET_PROPERTIES:
            [self getProperties:binary];
            break;
        case FD_CONTROL_SET_PROPERTIES:
            [self setProperties:binary];
            break;
            
        case FD_CONTROL_PROVISION:
            [self provision:binary];
            break;
        case FD_CONTROL_RESET:
            [self reset:binary];
            break;
            
        case FD_CONTROL_UPDATE_GET_EXTERNAL_HASH:
            [self updateGetExternalHash:binary];
            break;
        case FD_CONTROL_UPDATE_READ_PAGE:
            [self updateReadPage:binary];
            break;
            
        case FD_CONTROL_UPDATE_GET_SECTOR_HASHES:
            [self updateGetSectorHashes:binary];
            break;
        case FD_CONTROL_UPDATE_ERASE_SECTORS:
            [self updateEraseSectors:binary];
            break;
        case FD_CONTROL_UPDATE_WRITE_PAGE:
            [self updateWritePage:binary];
            break;
        case FD_CONTROL_UPDATE_COMMIT:
            [self updateCommit:binary];
            break;
            
        case FD_CONTROL_RADIO_DIRECT_TEST_MODE_ENTER:
            [self radioDirectTestModeEnter:binary];
            break;
        case FD_CONTROL_RADIO_DIRECT_TEST_MODE_EXIT:
            [self radioDirectTestModeExit:binary];
            break;
        case FD_CONTROL_RADIO_DIRECT_TEST_MODE_REPORT:
            [self radioDirectTestModeReport:binary];
            break;
            
        case FD_CONTROL_DISCONNECT:
            [self disconnect:binary];
            break;
            
        case FD_CONTROL_LED_OVERRIDE:
            [self ledOverride:binary];
            break;
            
        case FD_CONTROL_IDENTIFY:
            [self identify:binary];
            break;
            
        case FD_CONTROL_SYNC_START:
            [self syncStart:binary];
            break;
        case FD_CONTROL_SYNC_ACK:
            [self syncAck:binary];
            break;
            
        case FD_CONTROL_LOCK:
            [self lock:binary];
            break;
            
        case FD_CONTROL_DIAGNOSTICS:
            [self diagnostics:binary];
            break;
    }
}

@end
