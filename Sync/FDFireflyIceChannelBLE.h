//
//  FDFireflyIceChannelBLE.h
//  Sync
//
//  Created by Denis Bohm on 4/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIceChannel.h"

@class CBPeripheral;

@interface FDFireflyIceChannelBLE : NSObject <FDFireflyIceChannel>

@property (readonly) CBPeripheral *peripheral;
@property id<FDFireflyIceChannelDelegate> delegate;

- (id)initWithPeripheral:(CBPeripheral *)peripheral;

- (void)didConnectPeripheral;
- (void)didDisconnectPeripheralError:(NSError *)error;

@end
