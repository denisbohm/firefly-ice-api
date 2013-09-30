//
//  FDFireflyIceManager.m
//  FireflyDevice
//
//  Created by Denis Bohm on 9/30/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIce.h"
#import "FDFireflyIceChannelBLE.h"
#import "FDFireflyIceManager.h"

@interface FDFireflyIceManager () <FDFireflyIceObserver>

@property NSMutableArray *devices;

@end

@implementation FDFireflyIceManager

+ (FDFireflyIceManager *)managerWithDelegate:(id<FDFireflyIceManagerDelegate>)delegate
{
    FDFireflyIceManager *manager = [[FDFireflyIceManager alloc] init];
    manager.delegate = delegate;
    manager.centralManager = [[CBCentralManager alloc] initWithDelegate:manager queue:nil];
    return manager;
}

- (id)init
{
    if (self = [super init]) {
        _devices = [NSMutableArray array];
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

- (NSMutableDictionary *)deviceForPeripheral:(CBPeripheral *)peripheral
{
    for (NSMutableDictionary *device in _devices) {
        if (device[@"peripheral"] == peripheral) {
            return device;
        }
    }
    return nil;
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSMutableDictionary *device = [self deviceForPeripheral:peripheral];
    if (device != nil) {
        return;
    }
    
    FDFireflyIce *fireflyIce = [[FDFireflyIce alloc] init];
    
    [fireflyIce addObserver:self
              forKeyPath:@"hardwareId"
                 options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                 context:NULL];
    
    [fireflyIce.observable addObserver:self];
    FDFireflyIceChannelBLE *channel = [[FDFireflyIceChannelBLE alloc] initWithPeripheral:peripheral];
    [fireflyIce addChannel:channel type:@"BLE"];
    device = [NSMutableDictionary dictionary];
    [device setObject:peripheral forKey:@"peripheral"];
    [device setObject:fireflyIce forKey:@"fireflyIce"];
    [_devices insertObject:device atIndex:0];
    
    [_delegate fireflyIceManager:self discovered:fireflyIce];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSMutableDictionary *device = [self deviceForPeripheral:peripheral];
    FDFireflyIce *fireflyIce = device[@"fireflyIce"];
    FDFireflyIceChannelBLE *channel = fireflyIce.channels[@"BLE"];
    [channel didConnectPeripheral];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSMutableDictionary *device = [self deviceForPeripheral:peripheral];
    FDFireflyIce *fireflyIce = device[@"fireflyIce"];
    FDFireflyIceChannelBLE *channel = fireflyIce.channels[@"BLE"];
    [channel didDisconnectPeripheralError:error];
}

- (void)connectBLE:(FDFireflyIce *)fireflyIce
{
    FDFireflyIceChannelBLE *channel = fireflyIce.channels[@"BLE"];
    [_centralManager connectPeripheral:channel.peripheral options:nil];
}

- (void)disconnectBLE:(FDFireflyIce *)fireflyIce
{
    FDFireflyIceChannelBLE *channel = fireflyIce.channels[@"BLE"];
    [_centralManager cancelPeripheralConnection:channel.peripheral];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel status:(FDFireflyIceChannelStatus)status
{
    switch (status) {
        case FDFireflyIceChannelStatusOpening:
            break;
        case FDFireflyIceChannelStatusOpen:
            [_delegate fireflyIceManager:self openedBLE:fireflyIce];
            break;
        case FDFireflyIceChannelStatusClosed:
            [_delegate fireflyIceManager:self closedBLE:fireflyIce];
            break;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    if ([keyPath isEqual:@"hardwareId"]) {
        id old = [change objectForKey:NSKeyValueChangeOldKey];
        id hardwareId = [change objectForKey:NSKeyValueChangeNewKey];
        if ((old == nil) && (hardwareId != nil)) {
            [_delegate fireflyIceManager:self identified:object];
        }
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
