//
//  FDFireflyIceChannelUSB.h
//  FireflyDevice
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDFireflyIceChannel.h>

@class FDUSBHIDDevice;

@interface FDFireflyIceChannelUSB : NSObject <FDFireflyIceChannel>

@property (readonly) FDUSBHIDDevice *device;
@property id<FDFireflyIceChannelDelegate> delegate;

- (id)initWithDevice:(FDUSBHIDDevice *)device;

- (void)changeDevice:(FDUSBHIDDevice *)device;

@end
