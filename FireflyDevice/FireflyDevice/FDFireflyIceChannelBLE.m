//
//  FDFireflyIceChannelBLE.m
//  FireflyDevice
//
//  Created by Denis Bohm on 4/3/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDBinary.h>
#import <FireflyDevice/FDDetour.h>
#import <FireflyDevice/FDDetourSource.h>
#import <FireflyDevice/FDFireflyIceChannelBLE.h>
#import <FireflyDevice/FDFireflyDeviceLogger.h>
#import <FireflyDevice/FDWeak.h>

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

@implementation FDFireflyIceChannelBLEPeripheralObservable

+ (FDFireflyIceChannelBLEPeripheralObservable *)peripheralObservable
{
    FDFireflyIceChannelBLEPeripheralObservable *peripheralObservable = [[FDFireflyIceChannelBLEPeripheralObservable alloc] init];
    return peripheralObservable;
}

- (id)init
{
    if (self = [super init:@protocol(CBPeripheralDelegate)]) {
    }
    return self;
}

@end

@interface FDFireflyIceChannelBLE () <CBPeripheralDelegate>

@property FDFireflyIceChannelStatus status;

@property CBUUID *serviceUUID;
@property CBUUID *characteristicUUID;
@property CBUUID *characteristicNoResponseUUID;

@property CBCentralManager *centralManager;
@property CBPeripheral *peripheral;
@property CBCharacteristic *characteristic;
@property CBCharacteristic *characteristicNoResponse;
@property FDDetour *detour;
@property NSMutableArray *detourSources;
@property NSUInteger writePending;
@property NSUInteger writePendingLimit;

@end

@implementation FDFireflyIceChannelBLE

@synthesize log;

- (id)initWithCentralManager:(CBCentralManager *)centralManager withPeripheral:(CBPeripheral *)peripheral withServiceUUID:(CBUUID *)serviceUUID
{
    if (self = [super init]) {
        _serviceUUID = serviceUUID;
        NSString *baseUUID = [FDFireflyIceChannelBLE CBUUIDString:serviceUUID];
        _characteristicUUID = [CBUUID UUIDWithString:[baseUUID stringByReplacingCharactersInRange:NSMakeRange(4, 4) withString:@"0002"]];
        _characteristicNoResponseUUID = [CBUUID UUIDWithString:[baseUUID stringByReplacingCharactersInRange:NSMakeRange(4, 4) withString:@"0003"]];

        _peripheralObservable = [FDFireflyIceChannelBLEPeripheralObservable peripheralObservable];
        [_peripheralObservable addObserver:self];

        _centralManager = centralManager;
        _peripheral = peripheral;
        _peripheral.delegate = _peripheralObservable;
        _detour = [[FDDetour alloc] init];
        _detourSources = [NSMutableArray array];
        
        switch (_peripheral.state) {
            case CBPeripheralStateConnected:
                _status = FDFireflyIceChannelStatusOpen;
                break;
            case CBPeripheralStateConnecting:
                _status = FDFireflyIceChannelStatusOpening;
                break;
#if TARGET_OS_IPHONE
            case CBPeripheralStateDisconnecting:
                // add disconnecting status? -denis
                break;
#endif
            case CBPeripheralStateDisconnected:
                _status = FDFireflyIceChannelStatusClosed;
                break;
            
        }
        
        _writePendingLimit = 1;
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
    if (
        (![_peripheral respondsToSelector:@selector(state)] || (_peripheral.state == CBPeripheralStateConnected)) &&
        (_characteristic != nil)
    ) {
        [_peripheral setNotifyValue:NO forCharacteristic:_characteristic];
    }
    _characteristic = nil;
    _characteristicNoResponse = nil;
    [_detour clear];
    [_detourSources removeAllObjects];
    _writePending = 0;
    _writePendingLimit = 1;
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
    _writePending = 0;
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
    if (characteristic == _characteristic) {
        NSData *data = characteristic.value;
        __FDWeak FDFireflyIceChannelBLE *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf didUpdateValueForCharacteristic:data error:error];
        });
    }
}

- (void)checkWrite
{
    while ((_writePending < _writePendingLimit) && (_detourSources.count > 0)) {
        FDDetourSource *detourSource = [_detourSources objectAtIndex:0];
        NSData *subdata = [detourSource next];
        if (subdata != nil) {
            ++_writePending;
            if (_writePending < _writePendingLimit) {
                [_peripheral writeValue:subdata forCharacteristic:_characteristicNoResponse type:CBCharacteristicWriteWithoutResponse];
            } else {
                [_peripheral writeValue:subdata forCharacteristic:_characteristic type:CBCharacteristicWriteWithResponse];
            }
        } else {
            [_detourSources removeObjectAtIndex:0];
        }
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

- (void)didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
//    NSLog(@"didUpdateNotificationStateForCharacteristic");
    
    if (characteristic == _characteristic) {
        self.status = FDFireflyIceChannelStatusOpen;
        if ([_delegate respondsToSelector:@selector(fireflyIceChannel:status:)]) {
            [_delegate fireflyIceChannel:self status:self.status];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    __FDWeak FDFireflyIceChannelBLE *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf didUpdateNotificationStateForCharacteristic:characteristic error:error];
    });
}

- (void)didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
//    FDFireflyDeviceLogDebug(@"didDiscoverCharacteristicsForService %@", service.UUID);
    for (CBCharacteristic *characteristic in service.characteristics) {
//        FDFireflyDeviceLogDebug(@"didDiscoverServiceCharacteristic %@", [FDFireflyIceChannelBLE CBUUIDString:characteristic.UUID]);
        if ([_characteristicUUID isEqual:characteristic.UUID]) {
//            FDFireflyDeviceLogDebug(@"found characteristic");
            _characteristic = characteristic;
            
            [_peripheral setNotifyValue:YES forCharacteristic:_characteristic];
        } else
        if ([_characteristicNoResponseUUID isEqual:characteristic.UUID]) {
            NSLog(@"found characteristic no response");
            _characteristicNoResponse = characteristic;
        }
    }
    if ((_characteristic != nil) && (_characteristicNoResponse != nil)) {
        _writePendingLimit = 12;
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
