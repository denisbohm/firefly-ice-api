//
//  FDFireflyIce.h
//  Sync
//
//  Created by Denis Bohm on 7/18/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIceChannelBLE.h"
#import "FDFireflyIceChannelUSB.h"
#import "FDObservable.h"

@interface FDFireflyIceVersion : NSObject
@property uint16_t major;
@property uint16_t minor;
@property uint16_t patch;
@property uint32_t capabilities;
@property NSData *gitCommit;
@end

@interface FDFireflyIceHardwareId : NSObject
@property uint16_t vendor;
@property uint16_t product;
@property uint16_t major;
@property uint16_t minor;
@property NSData *unique;
@end

@interface FDFireflyIcePower : NSObject
@property float batteryLevel;
@property float batteryVoltage;
@property BOOL isUSBPowered;
@property BOOL isCharging;
@property float chargeCurrent;
@property float temperature;
@end

@interface FDFireflyIceSectorHash : NSObject
@property uint16_t sector;
@property NSData *hash;
@end

@protocol FDFireflyIceObserver <NSObject>

@optional

- (void)fireflyIceProperty:(id<FDFireflyIceChannel>)channel version:(FDFireflyIceVersion *)version;
- (void)fireflyIceProperty:(id<FDFireflyIceChannel>)channel hardwareId:(FDFireflyIceHardwareId *)hardwareId;
- (void)fireflyIceProperty:(id<FDFireflyIceChannel>)channel debugLock:(BOOL)debugLock;
- (void)fireflyIceProperty:(id<FDFireflyIceChannel>)channel time:(NSDate *)date;
- (void)fireflyIceProperty:(id<FDFireflyIceChannel>)channel power:(FDFireflyIcePower *)power;
- (void)fireflyIceProperty:(id<FDFireflyIceChannel>)channel site:(NSString *)site;

- (void)fireflyIceUpdateCommit:(id<FDFireflyIceChannel>)channel result:(uint8_t)result;

- (void)fireflyIceDirectTestModeReport:(id<FDFireflyIceChannel>)channel result:(uint16_t)result;

- (void)fireflyIceSectorHashes:(id<FDFireflyIceChannel>)channel sectorHashes:(NSArray *)sectorHashes;

- (void)fireflyIceSyncData:(id<FDFireflyIceChannel>)channel data:(NSData *)data;

- (void)fireflyIceSensing:(id<FDFireflyIceChannel>)channel ax:(float)ax ay:(float)ay az:(float)az mx:(float)mx my:(float)my mz:(float)mz;

- (void)fireflyIcePing:(id<FDFireflyIceChannel>)channel data:(NSData *)data;

@end

@class FDExecutor;

@interface FDFireflyIceObservable : FDObservable <FDFireflyIceObserver>
@end

@class FDFireflyIceCoder;

@interface FDFireflyIce : NSObject

@property FDFireflyIceCoder *coder;

@property(readonly) FDFireflyIceObservable *observable;

@property FDFireflyIceChannelBLE *channelBLE;
@property FDFireflyIceChannelUSB *channelUSB;

@property FDFireflyIceVersion *version;
@property FDFireflyIceHardwareId *hardwareId;
@property NSString *site;

@property FDExecutor *executor;

@end
