//
//  FDFireflyIceDeviceMock.m
//  FireflyDevice
//
//  Created by Denis Bohm on 2/22/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import "FDFireflyIceDeviceMock.h"
#import "FDFireflyIceCoder.h"

@implementation FDFireflyIceDeviceMock

- (id)init
{
    if (self = [super init]) {
        _name = @"Mock";
        
        _versionMajor = 1;
        _versionMinor = 0;
        _versionPatch = 29;
        _versionCapabilities =
            FD_CONTROL_CAPABILITY_LOCK |
            FD_CONTROL_CAPABILITY_BOOT_VERSION |
            FD_CONTROL_CAPABILITY_SYNC_AHEAD |
            FD_CONTROL_CAPABILITY_IDENTIFY |
            FD_CONTROL_CAPABILITY_LOGGING |
            FD_CONTROL_CAPABILITY_DIAGNOSTICS |
            FD_CONTROL_CAPABILITY_NAME |
            FD_CONTROL_CAPABILITY_RETAINED;
        uint8_t versionGitCommitBytes[] = {0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19};
        _versionGitCommit = [NSData dataWithBytes:versionGitCommitBytes length:sizeof(versionGitCommitBytes)];
        
        _bootMajor = 0;
        _bootMinor = 1;
        _bootPatch = 0;
        _bootCapabilities = 0;
        uint8_t bootGitCommitBytes[] = {0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19};
        _bootGitCommit = [NSData dataWithBytes:bootGitCommitBytes length:sizeof(bootGitCommitBytes)];
        
        _hardwareVendor = 0x2222;
        _hardwareProduct = 0x0002;
        _hardwareMajor = 1;
        _hardwareMinor = 5;
        uint8_t hardwareUUIDBytes[] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08};
        _hardwareUUID = [NSData dataWithBytes:hardwareUUIDBytes length:sizeof(hardwareUUIDBytes)];
        
        _resetLastCause = 1; // power on reset
        _resetLastTime = [NSDate dateWithTimeIntervalSince1970:0];
        
        _power = [[FDFireflyIcePower alloc] init];
        _power.batteryLevel = 0.87;
        _power.batteryVoltage = 4.05;
        _power.isUSBPowered = YES;
        _power.isCharging = YES;
        _power.chargeCurrent = 0.017;
        _power.temperature = 19.8;

        _externalData = [NSMutableData data];
        _externalData.length = 1 << 22;
    }
    return self;
}

@end
