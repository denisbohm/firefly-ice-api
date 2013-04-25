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

- (void)fireflyDevice:(FDFireflyDevice *)fireflyDevice
                   ax:(float)ax ay:(float)ay az:(float)az
                   mx:(float)mx my:(float)my mz:(float)mz;

@end

@interface FDFireflyDevice : NSObject

@property (readonly) CBPeripheral *peripheral;
@property id<FDFireflyDeviceDelegate> delegate;

- (id)initWithPeripheral:(CBPeripheral *)peripheral;

- (void)didConnectPeripheral;
- (void)didDisconnectPeripheralError:(NSError *)error;

- (void)write;

@end
