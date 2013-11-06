//
//  FDUSBHIDMonitor.h
//  Sync
//
//  Created by Denis Bohm on 4/11/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FDUSBHIDDevice;
@class FDUSBHIDMonitor;

@protocol FDUSBHIDDeviceDelegate <NSObject>

- (void)usbHidDevice:(FDUSBHIDDevice *)device inputReport:(NSData *)data;

@end

@interface FDUSBHIDDevice : NSObject

@property id<FDUSBHIDDeviceDelegate> delegate;

- (void)open;
- (void)close;

- (void)setReport:(NSData *)data;

@end

@protocol FDUSBHIDMonitorDelegate <NSObject>

- (void)usbHidMonitor:(FDUSBHIDMonitor *)monitor deviceAdded:(FDUSBHIDDevice *)usbHidDevice;
- (void)usbHidMonitor:(FDUSBHIDMonitor *)monitor deviceRemoved:(FDUSBHIDDevice *)device;

@end

@interface FDUSBHIDMonitor : NSObject

@property UInt16 vendor;
@property UInt16 product;

@property id<FDUSBHIDMonitorDelegate> delegate;

- (void)start;
- (void)stop;

@end
