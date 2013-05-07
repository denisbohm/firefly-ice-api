//
//  FDFireflyBle.h
//  Sync
//
//  Created by Denis Bohm on 4/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFirefly.h"

@class CBPeripheral;

@interface FDFireflyBle : NSObject <FDFirefly>

@property (readonly) CBPeripheral *peripheral;
@property id<FDFireflyDelegate> delegate;

- (id)initWithPeripheral:(CBPeripheral *)peripheral;

- (void)didConnectPeripheral;
- (void)didDisconnectPeripheralError:(NSError *)error;

@end
