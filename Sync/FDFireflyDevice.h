//
//  FDFireflyDevice.h
//  Sync
//
//  Created by Denis Bohm on 4/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FDFireflyDevice;
@class CBPeripheral;

@protocol FDFireflyDeviceDelegate <NSObject>

- (void)fireflyDeviceDiscovered:(FDFireflyDevice *)fireflyDevice peripheral:(CBPeripheral *)peripheral;

@end

@interface FDFireflyDevice : NSObject

@property (readonly) CBPeripheral *peripheral;

- (id)initWithPeripheral:(CBPeripheral *)peripheral;

- (void)didConnectPeripheral;
- (void)didDisconnectPeripheralError:(NSError *)error;

- (void)write;

@end
