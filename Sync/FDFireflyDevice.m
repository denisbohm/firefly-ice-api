//
//  FDFireflyDevice.m
//  Sync
//
//  Created by Denis Bohm on 4/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyDevice.h"

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

@interface FDFireflyDevice () <CBPeripheralDelegate>

@property CBPeripheral *peripheral;
@property CBCharacteristic *characteristic;

@end

@implementation FDFireflyDevice

- (id)initWithPeripheral:(CBPeripheral *)peripheral
{
    if (self = [super init]) {
        _peripheral = peripheral;
        _peripheral.delegate = self;
    }
    return self;
}

- (void)didConnectPeripheral
{
    [_peripheral discoverServices:nil];
}

- (void)didDisconnectPeripheralError:(NSError *)error
{
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"didWriteValueForCharacteristic %@", error);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"didUpdateValueForCharacteristic %@ %@", characteristic.value, error);
}

- (void)write
{
    uint8_t sequence_number = 0x00;
    uint16_t length = 1;
    uint8_t bytes[] = {sequence_number, length, length >> 8, 0x5a};
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    [_peripheral writeValue:data forCharacteristic:_characteristic type:CBCharacteristicWriteWithResponse];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"didDiscoverServices %@", peripheral.name);
    for (CBService *service in peripheral.services) {
        NSLog(@"didDiscoverService %@", service.UUID);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    CBUUID *ledUUID = [CBUUID UUIDWithString:@"310a0002-1b95-5091-b0bd-b7a681846399"];
    NSLog(@"didDiscoverCharacteristicsForService %@", service.UUID);
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"didDiscoverServiceCharacteristic %@", characteristic.UUID);
        if ([ledUUID isEqualTo:characteristic.UUID]) {
            NSLog(@"found characteristic value");
            _characteristic = characteristic;
            
            [_peripheral setNotifyValue:YES forCharacteristic:_characteristic];
        }
    }
}

@end
