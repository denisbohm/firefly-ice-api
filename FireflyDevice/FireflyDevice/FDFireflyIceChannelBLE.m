//
//  FDFireflyIceChannelBLE.m
//  Sync
//
//  Created by Denis Bohm on 4/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDBinary.h"
#import "FDDetour.h"
#import "FDDetourSource.h"
#import "FDFireflyIceChannelBLE.h"
#import "FDFireflyDeviceLogger.h"
#import "FDWeak.h"

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

#define _log self.log

@implementation FDFireflyIceChannelBLERSSI

+ (FDFireflyIceChannelBLERSSI *)RSSI:(float)value date:(NSDate *)date
{
    FDFireflyIceChannelBLERSSI *RSSI = [[FDFireflyIceChannelBLERSSI alloc] init];
    RSSI.value = value;
    RSSI.date = date;
    return RSSI;
}

+ (FDFireflyIceChannelBLERSSI *)RSSI:(float)value
{
    return [FDFireflyIceChannelBLERSSI RSSI:value date:[NSDate date]];
}

@end

@interface FDFireflyIceChannelBLE () <CBPeripheralDelegate>

@property FDFireflyIceChannelStatus status;

@property CBUUID *serviceUUID;
@property CBUUID *characteristicUUID;

@property CBCentralManager *centralManager;
@property CBPeripheral *peripheral;
@property CBCharacteristic *characteristic;
@property FDDetour *detour;
@property NSMutableArray *detourSources;
@property BOOL writePending;

@end

@implementation FDFireflyIceChannelBLE

@synthesize log;

- (id)initWithCentralManager:(CBCentralManager *)centralManager withPeripheral:(CBPeripheral *)peripheral
{
    if (self = [super init]) {
        _serviceUUID = [CBUUID UUIDWithString:@"310a0001-1b95-5091-b0bd-b7a681846399"];
        _characteristicUUID = [CBUUID UUIDWithString:@"310a0002-1b95-5091-b0bd-b7a681846399"];

        _centralManager = centralManager;
        _peripheral = peripheral;
        _peripheral.delegate = self;
        _detour = [[FDDetour alloc] init];
        _detourSources = [NSMutableArray array];
    }
    return self;
}

- (NSString *)name
{
    return @"BLE";
}

- (void)open
{
    [_centralManager connectPeripheral:_peripheral options:nil];
}

- (void)shutdown
{
    if ((_peripheral.state == CBPeripheralStateConnected) && (_characteristic != nil)) {
        [_peripheral setNotifyValue:NO forCharacteristic:_characteristic];
    }
    _characteristic = nil;
    [_detour clear];
    [_detourSources removeAllObjects];
    _writePending = NO;
}

- (void)close
{
    [self shutdown];
    
    [_centralManager cancelPeripheralConnection:_peripheral];
}

- (void)didConnectPeripheral
{
    [_peripheral discoverServices:@[_serviceUUID]];
    self.status = FDFireflyIceChannelStatusOpening;
    if ([_delegate respondsToSelector:@selector(fireflyIceChannel:status:)]) {
        [_delegate fireflyIceChannel:self status:self.status];
    }
}

- (void)didDisconnectPeripheralError:(NSError *)error
{
    [self shutdown];
    
    self.status = FDFireflyIceChannelStatusClosed;
    if ([_delegate respondsToSelector:@selector(fireflyIceChannel:status:)]) {
        [_delegate fireflyIceChannel:self status:self.status];
    }
}

- (void)didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
//    FDFireflyDeviceLogDebug(@"didWriteValueForCharacteristic %@", error);
    _writePending = NO;
    [self checkWrite];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    __FDWeak FDFireflyIceChannelBLE *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf didWriteValueForCharacteristic:characteristic error:error];
    });
}

- (void)didUpdateValueForCharacteristic:(NSData *)value error:(NSError *)error
{
//    FDFireflyDeviceLogDebug(@"didUpdateValueForCharacteristic %@ %@", value, error);
    [_detour detourEvent:value];
    if (_detour.state == FDDetourStateSuccess) {
        if ([_delegate respondsToSelector:@selector(fireflyIceChannelPacket:data:)]) {
            [_delegate fireflyIceChannelPacket:self data:_detour.data];
        }
        [_detour clear];
    } else
    if (_detour.state == FDDetourStateError) {
        if ([_delegate respondsToSelector:@selector(fireflyIceChannel:detour:error:)]) {
            [_delegate fireflyIceChannel:self detour:_detour error:_detour.error];
        }
        [_detour clear];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSData *data = characteristic.value;
    __FDWeak FDFireflyIceChannelBLE *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf didUpdateValueForCharacteristic:data error:error];
    });
}

- (void)checkWrite
{
    while (_detourSources.count > 0) {
        FDDetourSource *detourSource = [_detourSources objectAtIndex:0];
        NSData *subdata = [detourSource next];
        if (subdata != nil) {
            [_peripheral writeValue:subdata forCharacteristic:_characteristic type:CBCharacteristicWriteWithResponse];
            _writePending = YES;
            break;
        }
        [_detourSources removeObjectAtIndex:0];
    }
}

- (void)fireflyIceChannelSend:(NSData *)data
{
    [_detourSources addObject:[[FDDetourSource alloc] initWithSize:20 data:data]];
    [self checkWrite];
}

- (void)didDiscoverServices:(NSError *)error
{
    for (CBService *service in _peripheral.services) {
//        FDFireflyDeviceLogDebug(@"didDiscoverService %@", [FDFireflyIceChannelBLE CBUUIDString:service.UUID]);
        if ([service.UUID isEqual:_serviceUUID]) {
            [_peripheral discoverCharacteristics:nil/*@[_characteristicUUID]*/ forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    __FDWeak FDFireflyIceChannelBLE *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf didDiscoverServices:error];
    });
}

+ (NSString *)CBUUIDString:(CBUUID *)uuid;
{
    NSData *data = uuid.data;
    
    NSUInteger bytesToConvert = [data length];
    const unsigned char *uuidBytes = [data bytes];
    NSMutableString *outputString = [NSMutableString stringWithCapacity:16];
    
    for (NSUInteger currentByteIndex = 0; currentByteIndex < bytesToConvert; currentByteIndex++)
    {
        switch (currentByteIndex)
        {
            case 3:
            case 5:
            case 7:
            case 9:[outputString appendFormat:@"%02x-", uuidBytes[currentByteIndex]]; break;
            default:[outputString appendFormat:@"%02x", uuidBytes[currentByteIndex]];
        }
        
    }
    
    return outputString;
}

- (void)didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
//    FDFireflyDeviceLogDebug(@"didDiscoverCharacteristicsForService %@", service.UUID);
    for (CBCharacteristic *characteristic in service.characteristics) {
        FDFireflyDeviceLogDebug(@"didDiscoverServiceCharacteristic %@", [FDFireflyIceChannelBLE CBUUIDString:characteristic.UUID]);
        if ([_characteristicUUID isEqual:characteristic.UUID]) {
//            FDFireflyDeviceLogDebug(@"found characteristic value");
            _characteristic = characteristic;
            
            [_peripheral setNotifyValue:YES forCharacteristic:_characteristic];
            
            self.status = FDFireflyIceChannelStatusOpen;
            if ([_delegate respondsToSelector:@selector(fireflyIceChannel:status:)]) {
                [_delegate fireflyIceChannel:self status:self.status];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    __FDWeak FDFireflyIceChannelBLE *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf didDiscoverCharacteristicsForService:service error:error];
    });
}

- (void)didUpdateRSSI:(NSError *)error
{
    self.RSSI = [FDFireflyIceChannelBLERSSI RSSI:[_peripheral.RSSI floatValue]];
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    __FDWeak FDFireflyIceChannelBLE *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf didUpdateRSSI:error];
    });
}

@end
