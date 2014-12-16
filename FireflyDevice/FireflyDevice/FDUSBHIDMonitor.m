//
//  FDUSBHIDMonitor.m
//  FireflyDevice
//
//  Created by Denis Bohm on 4/11/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDUSBHIDMonitor.h>
#import <FireflyDevice/FDFireflyDeviceLogger.h>
#import <FireflyDevice/FDWeak.h>

#import <IOKit/hid/IOHIDManager.h>

static long get_long_property(IOHIDDeviceRef device, CFStringRef key)
{
    CFTypeRef ref = IOHIDDeviceGetProperty(device, key);
    if (ref) {
        if (CFGetTypeID(ref) == CFNumberGetTypeID()) {
            long value;
            CFNumberGetValue((CFNumberRef) ref, kCFNumberSInt32Type, &value);
            return value;
        }
    }
    return 0;
}

static unsigned short get_vendor_id(IOHIDDeviceRef device)
{
    return get_long_property(device, CFSTR(kIOHIDVendorIDKey));
}

static unsigned short get_product_id(IOHIDDeviceRef device)
{
    return get_long_property(device, CFSTR(kIOHIDProductIDKey));
}

@interface FDUSBHIDDevice ()

@property (FDWeak) FDUSBHIDMonitor *monitor;
@property IOHIDDeviceRef hidDeviceRef;
@property NSMutableData *inputData;
@property NSMutableData *outputData;
@property bool isOpen;
@property NSNumber *locationID;

@end

@interface FDUSBHIDMonitor ()

@property IOHIDManagerRef hidManagerRef;
@property NSThread *hidRunLoopThread;
@property CFRunLoopRef runLoopRef;
@property NSMutableArray *hidDevices;

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

- (IOHIDDeviceRef)deviceRef
{
    return _hidDeviceRef;
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

-(NSObject *)location
{
    if (_locationID == nil) {
        CFTypeRef typeRef = IOHIDDeviceGetProperty(_hidDeviceRef, CFSTR(kIOHIDLocationIDKey));
        if (typeRef && (CFGetTypeID(typeRef) == CFNumberGetTypeID())) {
            CFNumberRef locationRef = (CFNumberRef)typeRef;
            long location = 0;
            if (CFNumberGetValue(locationRef, kCFNumberLongType, &location)) {
                _locationID = [NSNumber numberWithLong:location];
            }
        }
    }
    return _locationID;
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

@implementation FDUSBHIDMonitorMatcherVidPid

+ (FDUSBHIDMonitorMatcherVidPid *)matcher:(NSString *)name vid:(uint16_t)vid pid:(uint16_t)pid
{
    FDUSBHIDMonitorMatcherVidPid *matcher = [[FDUSBHIDMonitorMatcherVidPid alloc] init];
    matcher.name = name;
    matcher.vid = vid;
    matcher.pid = pid;
    return matcher;
}

- (BOOL)matches:(IOHIDDeviceRef)deviceRef
{
    return (get_vendor_id(deviceRef) == self.vid) && (get_product_id(deviceRef) == self.pid);
}

@end

@implementation FDUSBHIDMonitor

- (id)init
{
    if (self = [super init]) {
        _hidDevices = [NSMutableArray array];
    }
    return self;
}

- (NSArray *)devices
{
    return [NSArray arrayWithArray:_hidDevices];
}

- (void)removal:(FDUSBHIDDevice *)device
{
    [device close];
    IOHIDDeviceRegisterRemovalCallback(device.hidDeviceRef, NULL, (__bridge void *)device);
    
    [_hidDevices removeObject:device];
    [_delegate usbHidMonitor:self deviceRemoved:device];
    CFRelease(device.hidDeviceRef);
    device.hidDeviceRef = 0;
}

static
void FDUSBHIDMonitorRemovalCallback(void *context, IOReturn result, void *sender)
{
    FDUSBHIDDevice *device = (__bridge FDUSBHIDDevice *)context;
    dispatch_async(dispatch_get_main_queue(), ^{
        [device.monitor removal:device];
    });
}

- (BOOL)matches:(IOHIDDeviceRef)deviceRef
{
    for (id<FDUSBHIDMonitorMatcher> matcher in self.matchers) {
        if ([matcher matches:deviceRef]) {
            return YES;
        }
    }
    return NO;
}

- (void)deviceMatching:(IOHIDDeviceRef)hidDeviceRef
{
    if ((self.matchers != nil) && ![self matches:hidDeviceRef]) {
        return;
    }
    
    FDUSBHIDDevice *device = [[FDUSBHIDDevice alloc] init];
    device.monitor = self;
    device.hidDeviceRef = hidDeviceRef;
    CFRetain(hidDeviceRef);
    [_hidDevices addObject:device];
    
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
    _hidRunLoopThread = [[NSThread alloc] initWithTarget:self selector:@selector(hidRunLoop) object:nil];
    [_hidRunLoopThread start];
}

- (void)stop
{
    [_hidRunLoopThread cancel];
    BOOL done = NO;
    for (NSUInteger i = 0; i < 25; ++i) {
        [NSThread sleepForTimeInterval:0.1];
        if (!_hidRunLoopThread.isExecuting) {
            done = YES;
            break;
        }
    }
    if (!done) {
        FDFireflyDeviceLogWarn(@"FD010801", @"usb test thread failed to stop");
    }
    _hidRunLoopThread = nil;
    _hidDevices = [NSMutableArray array];
}

- (FDUSBHIDDevice *)deviceWithLocation:(NSObject *)location
{
    for (FDUSBHIDDevice *device in _hidDevices) {
        if ([device.location isEqualTo:location]) {
            return device;
        }
    }
    return nil;
}

- (void)hidRunLoop
{
    @autoreleasepool {
        _hidManagerRef = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
        _runLoopRef = CFRunLoopGetCurrent();
        IOHIDManagerScheduleWithRunLoop(_hidManagerRef, _runLoopRef, kCFRunLoopDefaultMode);
        IOReturn ioReturn = IOHIDManagerOpen(_hidManagerRef, 0);
        if (ioReturn != kIOReturnSuccess) {
            
        }
        if (self.matchers == nil) {
            NSString *vendorKey = [NSString stringWithCString:kIOHIDVendorIDKey encoding:NSUTF8StringEncoding];
            NSString *productKey = [NSString stringWithCString:kIOHIDProductIDKey encoding:NSUTF8StringEncoding];
            NSNumber *vendor = [NSNumber numberWithInt:_vendor];
            NSNumber *product = [NSNumber numberWithInt:_product];
            IOHIDManagerSetDeviceMatchingMultiple(_hidManagerRef, (__bridge CFArrayRef)@[@{vendorKey: vendor, productKey: product}]);
        } else {
            IOHIDManagerSetDeviceMatchingMultiple(_hidManagerRef, NULL);
        }
        IOHIDManagerRegisterDeviceMatchingCallback(_hidManagerRef, FDUSBHIDMonitorDeviceMatchingCallback, (__bridge void *)self);
    }
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    while (![_hidRunLoopThread isCancelled]) {
        @autoreleasepool {
            [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        }
    }
    
    IOHIDManagerUnscheduleFromRunLoop(_hidManagerRef, _runLoopRef, kCFRunLoopDefaultMode);
    _runLoopRef = nil;
    IOHIDManagerClose(_hidManagerRef, 0);
    _hidManagerRef = nil;
}

@end
