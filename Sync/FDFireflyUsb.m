//
//  FDFireflyUsb.m
//  Sync
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetour.h"
#import "FDDetourSource.h"
#import "FDFireflyUsb.h"
#import "FDUSBHIDMonitor.h"

@interface FDFireflyUsb () <FDUSBHIDDeviceDelegate>

@property FDDetour *detour;

@end

@implementation FDFireflyUsb

- (id)initWithDevice:(FDUSBHIDDevice *)device
{
    if (self = [super init]) {
        _device = device;
        _detour = [[FDDetour alloc] init];
    }
    return self;
}

- (void)open
{
    _device.delegate = self;
    [_device open];
}

- (void)close
{
    _device.delegate = nil;
    [_device close];
}

- (void)usbHidDevice:(FDUSBHIDDevice *)device inputReport:(NSData *)data
{
    NSLog(@"usbHidDevice:inputReport: %@", data);
    [_detour detourEvent:data];
    if (_detour.state == FDDetourStateSuccess) {
        [_delegate fireflyPacket:self data:_detour.data];
        [_detour clear];
    } else
        if (_detour.state == FDDetourStateError) {
            NSLog(@"detour error");
            [_detour clear];
        }
}

- (void)send:(NSData *)data
{
    FDDetourSource *source = [[FDDetourSource alloc] initWithSize:64 data:data];
    NSData *subdata;
    while ((subdata = [source next]) != nil) {
        [_device setReport:subdata];
    }
}

@end
