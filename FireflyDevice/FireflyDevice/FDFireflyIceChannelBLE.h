//
//  FDFireflyIceChannelBLE.h
//  FireflyDevice
//
//  Created by Denis Bohm on 4/3/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDFireflyIceChannel.h>
#import <FireflyDevice/FDObservable.h>

#import <CoreBluetooth/CoreBluetooth.h>

@interface FDFireflyIceChannelBLEPeripheralObservable : FDObservable <CBPeripheralDelegate>

+ (FDFireflyIceChannelBLEPeripheralObservable *)peripheralObservable;

@end

@interface FDFireflyIceChannelBLERSSI : NSObject

@property float value;
@property NSDate *date;

+ (FDFireflyIceChannelBLERSSI *)RSSI:(float)value date:(NSDate *)date;
+ (FDFireflyIceChannelBLERSSI *)RSSI:(float)value;

@end

@interface FDFireflyIceChannelBLE : NSObject <FDFireflyIceChannel>

@property (readonly) CBPeripheral *peripheral;
@property FDFireflyIceChannelBLEPeripheralObservable *peripheralObservable;
@property id<FDFireflyIceChannelDelegate> delegate;
@property FDFireflyIceChannelBLERSSI *RSSI;

- (id)initWithCentralManager:(CBCentralManager *)centralManager withPeripheral:(CBPeripheral *)peripheral withServiceUUID:(CBUUID *)serviceUUID;

- (void)didConnectPeripheral;
- (void)didDisconnectPeripheralError:(NSError *)error;

@end
