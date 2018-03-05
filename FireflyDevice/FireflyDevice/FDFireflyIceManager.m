//
//  FDFireflyIceManager.m
//  FireflyDevice
//
//  Created by Denis Bohm on 9/30/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDExecutor.h>
#import <FireflyDevice/FDHelloTask.h>
#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceChannelBLE.h>
#import <FireflyDevice/FDFireflyIceManager.h>
#import <FireflyDevice/FDFirmwareUpdateTask.h>
#import <FireflyDevice/FDWeak.h>

@interface FDFireflyIceManager () <FDFireflyIceObserver, FDHelloTaskDelegate>

@property NSMutableArray *dictionaries;

@end

@implementation FDFireflyIceManager

+ (FDFireflyIceManager *)managerWithServiceUUID:(CBUUID *)serviceUUID withDelegate:(id<FDFireflyIceManagerDelegate>)delegate
{
    FDFireflyIceManager *manager = [[FDFireflyIceManager alloc] init];
    manager.serviceUUID = serviceUUID;
    manager.delegate = delegate;
    manager.active = YES;
    manager.discovery = YES;
    return manager;
}

+ (FDFireflyIceManager *)managerWithDelegate:(id<FDFireflyIceManagerDelegate>)delegate
{
    FDFireflyIceManager *manager = [[FDFireflyIceManager alloc] init];
    manager.delegate = delegate;
    manager.active = YES;
    manager.discovery = YES;
    return manager;
}

+ (FDFireflyIceManager *)manager
{
    return [[FDFireflyIceManager alloc] init];
}

- (id)init
{
    if (self = [super init]) {
        _serviceUUID = [CBUUID UUIDWithString:@"310a0001-1b95-5091-b0bd-b7a681846399"];
        
        _dictionaries = [NSMutableArray array];
        _identifier = @"com.fireflydesign.device.centralManagerDispatchQueue";
    }
    return self;
}

- (void)activate
{
    if (_centralManager == nil) {
        const char *cIdentifier = [_identifier UTF8String];
        _centralManagerDispatchQueue = dispatch_queue_create(cIdentifier, DISPATCH_QUEUE_SERIAL);
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        if ([[_centralManager class] instancesRespondToSelector:@selector(initWithDelegate:queue:options:)]) {
#if TARGET_OS_IPHONE
            [options setObject:_identifier forKey:CBCentralManagerOptionRestoreIdentifierKey];
#endif
            [options setObject:@YES forKey:CBCentralManagerOptionShowPowerAlertKey];
            _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:_centralManagerDispatchQueue options:options];
        } else {
            _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:_centralManagerDispatchQueue];
        }
        
    }
}

- (void)deactivate
{
    [_centralManager stopScan];
    _centralManager.delegate = nil;
    _centralManager = nil;
}

- (void)setActive:(BOOL)active
{
    if (active == _active) {
        return;
    }
    
    _active = active;
    
    if (_active) {
        [self activate];
    } else {
        [self deactivate];
    }
}

- (void)setDiscovery:(BOOL)discovery
{
    if (_discovery == discovery) {
        return;
    }
    
    _discovery = discovery;
    
    if (_centralManager.state == CBManagerStatePoweredOn) {
        if (_discovery) {
            [self scan:YES];
        } else {
            [_centralManager stopScan];
        }
    }
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
        case FDFireflyIceChannelStatusClosing:
            if ([_delegate respondsToSelector:@selector(fireflyIceManager:closedBLE:)]) { // !!! should not be BLE specific
                [_delegate fireflyIceManager:self closingBLE:fireflyIce];
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
    
    FDFirmwareUpdateTask *firmwareUpdateTask = nil;
    if ([_delegate respondsToSelector:@selector(fireflyIceManager:firmwareUpdateTask:)]) {
        firmwareUpdateTask = [_delegate fireflyIceManager:self firmwareUpdateTask:fireflyIce];
    } else {
        firmwareUpdateTask = [FDFirmwareUpdateTask firmwareUpdateTask:fireflyIce channel:channel];
    }
    if (firmwareUpdateTask != nil) {
        [fireflyIce.executor execute:firmwareUpdateTask];
    }
    
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
    if (_discovery) {
        [self scan:YES];
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBManagerStateUnknown:
        case CBManagerStateResetting:
        case CBManagerStateUnsupported:
        case CBManagerStateUnauthorized:
            break;
        case CBManagerStatePoweredOff:
            break;
        case CBManagerStatePoweredOn:
            [self centralManagerPoweredOn];
            break;
    }
}

- (NSString *)nameForPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData
{
    NSString *UUIDString = nil;
    UUIDString = [peripheral.identifier UUIDString];
    NSString *name = advertisementData[CBAdvertisementDataLocalNameKey];
    if (name == nil) {
        name = @"anonymous";
    }
    return [NSString stringWithFormat:@"%@ %@", name, UUIDString];
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

#if TARGET_OS_IPHONE
- (void)centralManager:(CBCentralManager *)centralManager willRestoreState:(NSDictionary *)state
{
    NSArray *peripherals = state[CBCentralManagerRestoredStatePeripheralsKey];
    for (CBPeripheral *peripheral in peripherals) {
        [self onMainCentralManager:_centralManager didDiscoverPeripheral:peripheral advertisementData:nil RSSI:peripheral.RSSI];
    }
}
#endif

- (void)onMainCentralManager:(CBCentralManager *)central
       didDiscoverPeripheral:(CBPeripheral *)peripheral
           advertisementData:(NSDictionary *)advertisementData
                        RSSI:(NSNumber *)RSSI
{
    NSMutableDictionary *dictionary = [self dictionaryForPeripheral:peripheral];
    if (dictionary != nil) {
        FDFireflyIce *fireflyIce = dictionary[@"fireflyIce"];
        FDFireflyIceChannelBLE *channel = (FDFireflyIceChannelBLE *)fireflyIce.channels[@"BLE"];
        channel.RSSI = [FDFireflyIceChannelBLERSSI RSSI:[RSSI floatValue]];
        if ([_delegate respondsToSelector:@selector(fireflyIceManager:advertisement:)]) {
            [_delegate fireflyIceManager:self advertisement:fireflyIce];
        }
        
        if (advertisementData != nil) {
            NSDictionary *previousAdvertisementData = dictionary[@"advertisementData"];
            NSMutableDictionary *newAdvertisementData = [NSMutableDictionary dictionaryWithDictionary:previousAdvertisementData];
            [newAdvertisementData addEntriesFromDictionary:advertisementData];
            if (![newAdvertisementData isEqualToDictionary:previousAdvertisementData]) {
                [dictionary setObject:newAdvertisementData forKey:@"advertisementData"];
                FDFireflyIce *fireflyIce = dictionary[@"fireflyIce"];
                fireflyIce.name = [self nameForPeripheral:peripheral advertisementData:newAdvertisementData];
                if ([_delegate respondsToSelector:@selector(fireflyIceManager:advertisementDataHasChanged:)]) {
                    [_delegate fireflyIceManager:self advertisementDataHasChanged:fireflyIce];
                }
            }
        }
        return;
    }
    
    if (![self isFireflyIce:advertisementData[CBAdvertisementDataServiceUUIDsKey]]) {
        return;
    }
    
    FDFireflyIce *fireflyIce = [[FDFireflyIce alloc] init];
    
    fireflyIce.name = [self nameForPeripheral:peripheral advertisementData:advertisementData];

    [fireflyIce.observable addObserver:self];
    FDFireflyIceChannelBLE *channel = [[FDFireflyIceChannelBLE alloc] initWithCentralManager:central withPeripheral:peripheral withServiceUUID:_serviceUUID];
    channel.RSSI = [FDFireflyIceChannelBLERSSI RSSI:[RSSI floatValue]];
    [fireflyIce addChannel:channel type:@"BLE"];
    dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:advertisementData forKey:@"advertisementData"];
    [dictionary setObject:peripheral forKey:@"peripheral"];
    [dictionary setObject:fireflyIce forKey:@"fireflyIce"];
    [_dictionaries insertObject:dictionary atIndex:0];
    
    [_delegate fireflyIceManager:self discovered:fireflyIce];
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    __FDWeak FDFireflyIceManager *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf onMainCentralManager:central didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    });
}

- (void)onMainCentralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSMutableDictionary *dictionary = [self dictionaryForPeripheral:peripheral];
    FDFireflyIce *fireflyIce = dictionary[@"fireflyIce"];
    FDFireflyIceChannelBLE *channel = fireflyIce.channels[@"BLE"];
    [channel didConnectPeripheral];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    __FDWeak FDFireflyIceManager *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf onMainCentralManager:central didConnectPeripheral:peripheral];
    });
}

- (void)onMainCentralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSMutableDictionary *dictionary = [self dictionaryForPeripheral:peripheral];
    FDFireflyIce *fireflyIce = dictionary[@"fireflyIce"];
    FDFireflyIceChannelBLE *channel = fireflyIce.channels[@"BLE"];
    [channel didDisconnectPeripheralError:error];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    __FDWeak FDFireflyIceManager *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf onMainCentralManager:central didDisconnectPeripheral:peripheral error:error];
    });
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
