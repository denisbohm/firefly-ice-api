//
//  FDFireflyIceManager.m
//  FireflyDevice
//
//  Created by Denis Bohm on 9/30/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDExecutor.h"
#import "FDHelloTask.h"
#import "FDFireflyIce.h"
#import "FDFireflyIceChannelBLE.h"
#import "FDFireflyIceManager.h"
#import "FDFirmwareUpdateTask.h"

@interface FDFireflyIceManager () <FDFireflyIceObserver, FDHelloTaskDelegate>

@property CBUUID *serviceUUID;

@property NSMutableArray *dictionaries;

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
        _serviceUUID = [CBUUID UUIDWithString:@"310a0001-1b95-5091-b0bd-b7a681846399"];
        _dictionaries = [NSMutableArray array];
    }
    return self;
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel status:(FDFireflyIceChannelStatus)status
{
    switch (status) {
        case FDFireflyIceChannelStatusOpening:
            break;
        case FDFireflyIceChannelStatusOpen:
            [fireflyIce.executor execute:[FDHelloTask helloTask:fireflyIce channel:channel delegate:self]];
            if ([_delegate respondsToSelector:@selector(fireflyIceManager:openedBLE:)]) { // !!! should not be BLE specific
                [_delegate fireflyIceManager:self openedBLE:fireflyIce];
            }
            break;
        case FDFireflyIceChannelStatusClosed:
            if ([_delegate respondsToSelector:@selector(fireflyIceManager:closedBLE:)]) { // !!! should not be BLE specific
                [_delegate fireflyIceManager:self closedBLE:fireflyIce];
            }
            break;
    }
}

- (void)helloTaskSuccess:(FDHelloTask *)helloTask
{
    FDFireflyIce *fireflyIce = helloTask.fireflyIce;
    id<FDFireflyIceChannel> channel = helloTask.channel;
    [fireflyIce.executor execute:[FDFirmwareUpdateTask firmwareUpdateTask:fireflyIce channel:channel]];
    
    if ([_delegate respondsToSelector:@selector(fireflyIceManager:identified:)]) {
        [_delegate fireflyIceManager:self identified:fireflyIce];
    }
}

- (void)helloTask:(FDHelloTask *)helloTask error:(NSError *)error
{
    // !!! should have retry limit and decide what to do on failure (close device?)
    FDFireflyIce *fireflyIce = helloTask.fireflyIce;
    id<FDFireflyIceChannel> channel = helloTask.channel;
    [fireflyIce.executor execute:[FDHelloTask helloTask:fireflyIce channel:channel delegate:self]];
}

- (NSMutableDictionary *)dictionaryFor:(id)object key:(NSString *)key
{
    for (NSMutableDictionary *dictionary in _dictionaries) {
        if (dictionary[key] == object) {
            return dictionary;
        }
    }
    return nil;
}

// BLE Specific Methods

- (NSMutableDictionary *)dictionaryForPeripheral:(CBPeripheral *)peripheral
{
    return [self dictionaryFor:peripheral key:@"peripheral"];
}

- (void)scan:(BOOL)allowDuplicates
{
    [_centralManager retrieveConnectedPeripheralsWithServices:@[_serviceUUID]];
    NSDictionary *options = nil;
    if (allowDuplicates) {
        options = @{CBCentralManagerScanOptionAllowDuplicatesKey: @YES};
    }
    [_centralManager scanForPeripheralsWithServices:@[_serviceUUID] options:options];
}

- (void)centralManagerPoweredOn
{
    [self scan:NO];
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

- (NSString *)nameForPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData
{
#if TARGET_OS_IPHONE
    NSString *UUIDString = [peripheral.identifier UUIDString];
#else
    NSString *UUIDString = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, peripheral.UUID));
#endif
    return [NSString stringWithFormat:@"%@ %@", advertisementData[CBAdvertisementDataLocalNameKey], UUIDString];
}

- (BOOL)isFireflyIce:(NSArray *)serviceUUIDs
{
    for (CBUUID *serviceUUID in serviceUUIDs) {
        if ([_serviceUUID isEqual:serviceUUID]) {
            return YES;
        }
    }
    return NO;
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    if (![self isFireflyIce:advertisementData[CBAdvertisementDataServiceUUIDsKey]]) {
        return;
    }
    
    NSMutableDictionary *dictionary = [self dictionaryForPeripheral:peripheral];
    if (dictionary != nil) {
        return;
    }
    
    FDFireflyIce *fireflyIce = [[FDFireflyIce alloc] init];
    
    fireflyIce.name = [self nameForPeripheral:peripheral advertisementData:advertisementData];

    [fireflyIce.observable addObserver:self];
    FDFireflyIceChannelBLE *channel = [[FDFireflyIceChannelBLE alloc] initWithCentralManager:central withPeripheral:peripheral];
    channel.RSSI = [FDFireflyIceChannelBLERSSI RSSI:[RSSI floatValue]];
    [fireflyIce addChannel:channel type:@"BLE"];
    dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:peripheral forKey:@"peripheral"];
    [dictionary setObject:fireflyIce forKey:@"fireflyIce"];
    [_dictionaries insertObject:dictionary atIndex:0];
    
    [_delegate fireflyIceManager:self discovered:fireflyIce];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSMutableDictionary *dictionary = [self dictionaryForPeripheral:peripheral];
    FDFireflyIce *fireflyIce = dictionary[@"fireflyIce"];
    FDFireflyIceChannelBLE *channel = fireflyIce.channels[@"BLE"];
    [channel didConnectPeripheral];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSMutableDictionary *dictionary = [self dictionaryForPeripheral:peripheral];
    FDFireflyIce *fireflyIce = dictionary[@"fireflyIce"];
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

@end
