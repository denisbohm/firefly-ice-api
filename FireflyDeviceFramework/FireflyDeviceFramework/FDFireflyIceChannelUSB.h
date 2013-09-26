//
//  FDFireflyIceChannelUSB.h
//  Sync
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIceChannel.h"

@class FDUSBHIDDevice;

@interface FDFireflyIceChannelUSB : NSObject <FDFireflyIceChannel>

@property (readonly) FDUSBHIDDevice *device;
@property id<FDFireflyIceChannelDelegate> delegate;

- (id)initWithDevice:(FDUSBHIDDevice *)device;

- (void)open;
- (void)close;

@end
