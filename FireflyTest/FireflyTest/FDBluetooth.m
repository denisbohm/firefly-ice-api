//
//  FDBluetooth.m
//  FireflyTest
//
//  Created by Denis Bohm on 9/18/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDBluetooth.h"

#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceChannelBLE.h>

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

@interface FDBluetooth () <CBCentralManagerDelegate>

@property CBCentralManager *centralManager;
@property NSMutableArray *fireflyDevices;

@end

@implementation FDBluetooth

- (id)init
{
    if (self = [super init]) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _fireflyDevices = [NSMutableArray array];
    }
    return self;
}

- (void)centralManagerPoweredOn
{
    [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"310a0001-1b95-5091-b0bd-b7a681846399"]] options:nil];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStateUnknown:
        case CBCentralManagerStateResetting:
        case CBCentralManagerStateUnsupported:
        case CBCentralManagerStateUnauthorized:
            break;
        case CBCentralManagerStatePoweredOff:
            break;
        case CBCentralManagerStatePoweredOn:
            [self centralManagerPoweredOn];
            break;
    }
}

- (FDFireflyIceChannelBLE *)getFireflyDeviceByPeripheral:(CBPeripheral *)peripheral
{
    for (FDFireflyIceChannelBLE *fireflyDevice in _fireflyDevices) {
        if (fireflyDevice.peripheral == peripheral) {
            return fireflyDevice;
        }
    }
    return nil;
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    FDFireflyIceChannelBLE *fireflyDevice = [self getFireflyDeviceByPeripheral:peripheral];
    if (fireflyDevice != nil) {
        return;
    }
    
    NSLog(@"didDiscoverPeripheral %@ ad=%@", peripheral, advertisementData);
    FDFireflyIce *fireflyIce = [[FDFireflyIce alloc] init];
    [fireflyIce.observable addObserver:self];
    FDFireflyIceChannelBLE *channelBLE = [[FDFireflyIceChannelBLE alloc] initWithPeripheral:peripheral];
    [fireflyIce addChannel:channelBLE type:@"BLE"];
    [_fireflyDevices addObject:channelBLE];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"didConnectPeripheral %@", peripheral.name);
    FDFireflyIceChannelBLE *fireflyDevice = [self getFireflyDeviceByPeripheral:peripheral];
    [fireflyDevice didConnectPeripheral];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didDisconnectPeripheral %@ : %@", peripheral.name, error);
    FDFireflyIceChannelBLE *fireflyDevice = [self getFireflyDeviceByPeripheral:peripheral];
    [fireflyDevice didDisconnectPeripheralError:error];
}

@end
