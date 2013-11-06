//
//  FDUSBHIDMonitor.m
//  Sync
//
//  Created by Denis Bohm on 4/11/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDUSBHIDMonitor.h"

#import <IOKit/hid/IOHIDManager.h>

@interface FDUSBHIDDevice ()

@property (weak) FDUSBHIDMonitor *monitor;
@property IOHIDDeviceRef hidDeviceRef;
@property NSMutableData *inputData;
@property NSMutableData *outputData;
@property bool isOpen;

@end

@interface FDUSBHIDMonitor ()

@property IOHIDManagerRef hidManagerRef;
@property NSThread *hidRunLoopThread;
@property CFRunLoopRef runLoopRef;
@property BOOL run;
@property NSMutableArray *devices;

@end

@implementation FDUSBHIDDevice

- (id)init
{
    if (self = [super init]) {
        _inputData = [NSMutableData data];
        [_inputData setLength:64];
        _outputData = [NSMutableData data];
        [_outputData setLength:64];
    }
    return self;
}

- (void)setReport:(NSData *)data
{
    if (!_isOpen) {
        @throw [NSException exceptionWithName:@"USBDeviceNotOpen" reason:@"USB device not open" userInfo:nil];
    }
    [_outputData resetBytesInRange:NSMakeRange(0, _outputData.length)];
    [data getBytes:(void *)_outputData.bytes length:_outputData.length];
    IOReturn ioReturn = IOHIDDeviceSetReport(_hidDeviceRef, kIOHIDReportTypeOutput, 0x81, _outputData.bytes, _outputData.length);
    if (ioReturn != kIOReturnSuccess) {
        
    }
}

- (void)inputReport:(NSData *)data
{
    [_delegate usbHidDevice:self inputReport:data];
}

static
void FDUSBHIDDeviceInputReportCallback(void *context, IOReturn result, void *sender, IOHIDReportType type, uint32_t reportID, uint8_t *report, CFIndex reportLength)
{
    FDUSBHIDDevice *device = (__bridge FDUSBHIDDevice *)context;
    [device inputReport:[NSData dataWithBytes:report length:reportLength]];
}

- (void)open
{
    if (_isOpen) {
        return;
    }
    
    IOReturn ioReturn = IOHIDDeviceOpen(_hidDeviceRef, kIOHIDOptionsTypeSeizeDevice);
    if (ioReturn != kIOReturnSuccess) {
        
    }
    IOHIDDeviceScheduleWithRunLoop(_hidDeviceRef, _monitor.runLoopRef, kCFRunLoopDefaultMode);
    IOHIDDeviceRegisterInputReportCallback(_hidDeviceRef, (uint8_t *)_inputData.bytes, _inputData.length, FDUSBHIDDeviceInputReportCallback, (__bridge void *)self);
    
    _isOpen = true;
}

- (void)close
{
    if (!_isOpen) {
        return;
    }
    
    IOHIDDeviceUnscheduleFromRunLoop(_hidDeviceRef, _monitor.runLoopRef, kCFRunLoopDefaultMode);
    IOHIDDeviceRegisterInputReportCallback(_hidDeviceRef, NULL, 0, NULL, (__bridge void *)self);
    IOHIDDeviceClose(_hidDeviceRef, kIOHIDOptionsTypeNone);
    
    _isOpen = false;
}

@end

@implementation FDUSBHIDMonitor

- (id)init
{
    if (self = [super init]) {
        _devices = [NSMutableArray array];
    }
    return self;
}

- (void)removal:(FDUSBHIDDevice *)device
{
    [device close];
    IOHIDDeviceRegisterRemovalCallback(device.hidDeviceRef, NULL, (__bridge void *)device);
    
    [_devices removeObject:device];
    [_delegate usbHidMonitor:self deviceRemoved:device];
}

static
void FDUSBHIDMonitorRemovalCallback(void *context, IOReturn result, void *sender)
{
    FDUSBHIDDevice *device = (__bridge FDUSBHIDDevice *)context;
    [device.monitor removal:device];
}

- (void)deviceMatching:(IOHIDDeviceRef)hidDeviceRef
{
    FDUSBHIDDevice *device = [[FDUSBHIDDevice alloc] init];
    device.monitor = self;
    device.hidDeviceRef = hidDeviceRef;
    [_devices addObject:device];
    
    IOHIDDeviceRegisterRemovalCallback(hidDeviceRef, FDUSBHIDMonitorRemovalCallback, (__bridge void*)device);
    
    [_delegate usbHidMonitor:self deviceAdded:device];
}

static
void FDUSBHIDMonitorDeviceMatchingCallback(void *context, IOReturn result, void *sender, IOHIDDeviceRef hidDeviceRef)
{
    FDUSBHIDMonitor *monitor = (__bridge FDUSBHIDMonitor *)context;
    [monitor deviceMatching:hidDeviceRef];
}

- (void)start
{
    _run = YES;
    _hidManagerRef = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    _hidRunLoopThread = [[NSThread alloc] initWithTarget:self selector:@selector(hidRunLoop) object:nil];
    [_hidRunLoopThread start];
}

- (void)stop
{
    _run = NO;
    BOOL done = NO;
    for (NSUInteger i = 0; i < 100; ++i) {
        if (!_hidRunLoopThread.isExecuting) {
            done = YES;
            break;
        }
    }
    if (!done) {
        NSLog(@"usb test thread failed to stop");
    }
    _hidRunLoopThread = nil;
    IOHIDManagerClose(_hidManagerRef, 0);
    _hidManagerRef = nil;
    _runLoopRef = nil;
    _devices = [NSMutableArray array];
}

- (void)hidRunLoop
{
    _runLoopRef = CFRunLoopGetCurrent();
    IOHIDManagerScheduleWithRunLoop(_hidManagerRef, _runLoopRef, kCFRunLoopDefaultMode);
    IOReturn ioReturn = IOHIDManagerOpen(_hidManagerRef, 0);
    if (ioReturn != kIOReturnSuccess) {
        
    }
    NSString *vendorKey = [NSString stringWithCString:kIOHIDVendorIDKey encoding:NSUTF8StringEncoding];
    NSString *productKey = [NSString stringWithCString:kIOHIDProductIDKey encoding:NSUTF8StringEncoding];
    NSNumber *vendor = [NSNumber numberWithInt:_vendor];
    NSNumber *product = [NSNumber numberWithInt:_product];
    IOHIDManagerSetDeviceMatchingMultiple(_hidManagerRef, (__bridge CFArrayRef)@[@{vendorKey: vendor, productKey: product}]);
    IOHIDManagerRegisterDeviceMatchingCallback(_hidManagerRef, FDUSBHIDMonitorDeviceMatchingCallback, (__bridge void *)self);
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    while (_run) {
        [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
}

@end
