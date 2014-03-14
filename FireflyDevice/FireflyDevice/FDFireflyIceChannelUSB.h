//
//  FDFireflyIceChannelUSB.h
//  FireflyDevice
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import "FDFireflyIceChannel.h"

@class FDUSBHIDDevice;

@interface FDFireflyIceChannelUSB : NSObject <FDFireflyIceChannel>

@property (readonly) FDUSBHIDDevice *device;
@property id<FDFireflyIceChannelDelegate> delegate;

- (id)initWithDevice:(FDUSBHIDDevice *)device;

@end
