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

+ (nonnull FDFireflyIceChannelBLEPeripheralObservable *)peripheralObservable;

@end

@interface FDFireflyIceChannelBLERSSI : NSObject

@property float value;
@property NSDate * _Nonnull date;

+ (nonnull FDFireflyIceChannelBLERSSI *)RSSI:(float)value date:(nonnull NSDate *)date;
+ (nonnull FDFireflyIceChannelBLERSSI *)RSSI:(float)value;

@end

@interface FDFireflyIceChannelBLE : NSObject <FDFireflyIceChannel>

@property (readonly) CBPeripheral * _Nonnull peripheral;
@property FDFireflyIceChannelBLEPeripheralObservable * _Nonnull peripheralObservable;
@property id <FDFireflyIceChannelDelegate> _Nullable delegate;
@property FDFireflyIceChannelBLERSSI * _Nullable RSSI;
@property BOOL useL2cap;

- (nonnull id)initWithCentralManager:(nonnull CBCentralManager *)centralManager withPeripheral:(nonnull CBPeripheral *)peripheral withServiceUUID:(nonnull CBUUID *)serviceUUID;

- (void)didConnectPeripheral;
- (void)didDisconnectPeripheralError:(nullable NSError *)error;

@end
