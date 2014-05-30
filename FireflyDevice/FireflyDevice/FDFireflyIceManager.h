//
//  FDFireflyIceManager.h
//  FireflyDevice
//
//  Created by Denis Bohm on 9/30/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceChannelBLE.h>

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

@class FDFireflyIceManager;

@protocol FDFireflyIceManagerDelegate <NSObject>

- (void)fireflyIceManager:(FDFireflyIceManager *)manager discovered:(FDFireflyIce *)fireflyIce;

@optional

- (void)fireflyIceManager:(FDFireflyIceManager *)manager advertisementDataHasChanged:(FDFireflyIce *)fireflyIce;

- (void)fireflyIceManager:(FDFireflyIceManager *)manager openedBLE:(FDFireflyIce *)fireflyIce;
- (void)fireflyIceManager:(FDFireflyIceManager *)manager closedBLE:(FDFireflyIce *)fireflyIce;

- (void)fireflyIceManager:(FDFireflyIceManager *)manager identified:(FDFireflyIce *)fireflyIce;

@end

@interface FDFireflyIceManager : NSObject <CBCentralManagerDelegate>

+ (FDFireflyIceManager *)manager;
+ (FDFireflyIceManager *)managerWithDelegate:(id<FDFireflyIceManagerDelegate>)delegate;

@property id<FDFireflyIceManagerDelegate> delegate;
@property NSString *identifier;
@property dispatch_queue_t centralManagerDispatchQueue;
@property CBCentralManager *centralManager;

@property(nonatomic) BOOL active;
@property(nonatomic) BOOL discovery;

- (void)scan:(BOOL)allowDuplicates;

- (void)connectBLE:(FDFireflyIce *)fireflyIce;
- (void)disconnectBLE:(FDFireflyIce *)fireflyIce;

- (NSMutableDictionary *)dictionaryFor:(id)object key:(NSString *)key;

- (NSString *)nameForPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData;

@end
