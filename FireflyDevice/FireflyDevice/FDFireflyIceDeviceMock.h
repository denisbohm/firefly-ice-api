//
//  FDFireflyIceDeviceMock.h
//  FireflyDevice
//
//  Created by Denis Bohm on 2/22/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDFireflyIce.h>

@interface FDFireflyIceDeviceMock : NSObject

@property uint16_t versionMajor;
@property uint16_t versionMinor;
@property uint16_t versionPatch;
@property uint32_t versionCapabilities;
@property NSData *versionGitCommit;

@property uint16_t bootMajor;
@property uint16_t bootMinor;
@property uint16_t bootPatch;
@property uint32_t bootCapabilities;
@property NSData *bootGitCommit;

@property uint16_t hardwareVendor;
@property uint16_t hardwareProduct;
@property uint16_t hardwareMajor;
@property uint16_t hardwareMinor;
@property NSData *hardwareUUID;

@property BOOL debugLock;

@property NSData *provisionData;
@property NSString *site;

@property uint32_t resetLastCause;
@property NSDate *resetLastTime;

@property FDFireflyIcePower *power;

@property uint8_t txPower;

@property BOOL logStorage;
@property uint32_t logCount;

@property NSString *name;

@property NSMutableData *externalData;

@property uint16_t directTestModeReport;

@end
