//
//  FDFireflyIceChannelBLE.m
//  Sync
//
//  Created by Denis Bohm on 4/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetour.h"
#import "FDDetourSource.h"
#import "FDFireflyIceChannelBLE.h"

#import <FireflyProduction/FDBinary.h>

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

@interface FDFireflyIceChannelBLE () <CBPeripheralDelegate>

@property CBPeripheral *peripheral;
@property CBCharacteristic *characteristic;
@property FDDetour *detour;
@property NSMutableArray *detourSources;
@property BOOL writePending;

@end

@implementation FDFireflyIceChannelBLE

- (id)initWithPeripheral:(CBPeripheral *)peripheral
{
    if (self = [super init]) {
        _peripheral = peripheral;
        _peripheral.delegate = self;
        _detour = [[FDDetour alloc] init];
        _detourSources = [NSMutableArray array];
    }
    return self;
}

- (void)didConnectPeripheral
{
    [_peripheral discoverServices:nil];
}

- (void)didDisconnectPeripheralError:(NSError *)error
{
    [_detour clear];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"didWriteValueForCharacteristic %@", error);
    _writePending = NO;
    [self checkWrite];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"didUpdateValueForCharacteristic %@ %@", characteristic.value, error);
    [_detour detourEvent:characteristic.value];
    if (_detour.state == FDDetourStateSuccess) {
        [_delegate fireflyIceChannelPacket:self data:_detour.data];
        [_detour clear];
    } else
    if (_detour.state == FDDetourStateError) {
        NSLog(@"detour error");
        [_detour clear];
    }
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
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:@"310a0002-1b95-5091-b0bd-b7a681846399"];
    NSLog(@"didDiscoverCharacteristicsForService %@", service.UUID);
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"didDiscoverServiceCharacteristic %@", characteristic.UUID);
        if ([characteristicUUID isEqualTo:characteristic.UUID]) {
            NSLog(@"found characteristic value");
            _characteristic = characteristic;
            
            [_peripheral setNotifyValue:YES forCharacteristic:_characteristic];
            
            [_delegate fireflyIceChannelOpen:self];
        }
    }
}

@end
