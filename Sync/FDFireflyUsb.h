//
//  FDFireflyUsb.h
//  Sync
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFirefly.h"

@class FDUSBHIDDevice;

@interface FDFireflyUsb : NSObject <FDFirefly>

@property (readonly) FDUSBHIDDevice *device;
@property id<FDFireflyDelegate> delegate;

- (id)initWithDevice:(FDUSBHIDDevice *)device;

- (void)open;
- (void)close;

@end
