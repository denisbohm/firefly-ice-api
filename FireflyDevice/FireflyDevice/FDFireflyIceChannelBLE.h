//
//  FDFireflyIceChannelBLE.h
//  FireflyDevice
//
//  Created by Denis Bohm on 4/3/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import "FDFireflyIceChannel.h"

@class CBCentralManager;
@class CBPeripheral;

@interface FDFireflyIceChannelBLERSSI : NSObject

@property float value;
@property NSDate *date;

+ (FDFireflyIceChannelBLERSSI *)RSSI:(float)value date:(NSDate *)date;
+ (FDFireflyIceChannelBLERSSI *)RSSI:(float)value;

@end

@interface FDFireflyIceChannelBLE : NSObject <FDFireflyIceChannel>

@property (readonly) CBPeripheral *peripheral;
@property id<FDFireflyIceChannelDelegate> delegate;
@property FDFireflyIceChannelBLERSSI *RSSI;

- (id)initWithCentralManager:(CBCentralManager *)centralManager withPeripheral:(CBPeripheral *)peripheral;

- (void)didConnectPeripheral;
- (void)didDisconnectPeripheralError:(NSError *)error;

@end
