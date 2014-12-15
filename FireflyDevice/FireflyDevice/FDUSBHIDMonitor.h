//
//  FDUSBHIDMonitor.h
//  FireflyDevice
//
//  Created by Denis Bohm on 4/11/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <IOKit/hid/IOHIDManager.h>

@protocol FDFireflyDeviceLog;
@class FDUSBHIDDevice;
@class FDUSBHIDMonitor;

@protocol FDUSBHIDDeviceDelegate <NSObject>

- (void)usbHidDevice:(FDUSBHIDDevice *)device inputReport:(NSData *)data;

@end

@interface FDUSBHIDDevice : NSObject

@property id<FDUSBHIDDeviceDelegate> delegate;

@property (readonly) IOHIDDeviceRef deviceRef;
@property (readonly) NSObject *location;

- (void)open;
- (void)close;

- (void)setReport:(NSData *)data;

@end

@protocol FDUSBHIDMonitorDelegate <NSObject>

- (void)usbHidMonitor:(FDUSBHIDMonitor *)monitor deviceAdded:(FDUSBHIDDevice *)device;
- (void)usbHidMonitor:(FDUSBHIDMonitor *)monitor deviceRemoved:(FDUSBHIDDevice *)device;

@end

@protocol FDUSBHIDMonitorMatcher <NSObject>

- (BOOL)matches:(IOHIDDeviceRef)deviceRef;

@end

@interface FDUSBHIDMonitorMatcherVidPid : NSObject<FDUSBHIDMonitorMatcher>

+ (FDUSBHIDMonitorMatcherVidPid *)matcher:(NSString *)name vid:(uint16_t)vid pid:(uint16_t)pid;

@property NSString *name;
@property uint16_t vid;
@property uint16_t pid;

@end

@interface FDUSBHIDMonitor : NSObject

@property id<FDFireflyDeviceLog> log;

@property NSArray *matchers;
@property UInt16 vendor;
@property UInt16 product;

@property id<FDUSBHIDMonitorDelegate> delegate;

@property (readonly) NSArray *devices;

- (void)start;
- (void)stop;

- (FDUSBHIDDevice *)deviceWithLocation:(NSObject *)location;

@end
