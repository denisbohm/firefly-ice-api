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
@class FDFirmwareUpdateTask;

@protocol FDFireflyIceManagerDelegate <NSObject>

- (void)fireflyIceManager:(FDFireflyIceManager * _Nonnull)manager discovered:(FDFireflyIce * _Nonnull )fireflyIce;

@optional

- (void)fireflyIceManager:(FDFireflyIceManager * _Nonnull)manager advertisementDataHasChanged:(FDFireflyIce * _Nonnull)fireflyIce;
- (void)fireflyIceManager:(FDFireflyIceManager * _Nonnull)manager advertisement:(FDFireflyIce * _Nonnull)fireflyIce;

- (void)fireflyIceManager:(FDFireflyIceManager * _Nonnull)manager openedBLE:(FDFireflyIce * _Nonnull)fireflyIce;
- (void)fireflyIceManager:(FDFireflyIceManager * _Nonnull)manager closingBLE:(FDFireflyIce * _Nonnull)fireflyIce;
- (void)fireflyIceManager:(FDFireflyIceManager * _Nonnull)manager closedBLE:(FDFireflyIce * _Nonnull)fireflyIce;

- (void)fireflyIceManager:(FDFireflyIceManager * _Nonnull)manager identified:(FDFireflyIce * _Nonnull)fireflyIce;

- (FDFirmwareUpdateTask * _Nullable)fireflyIceManager:(FDFireflyIceManager * _Nonnull)manager firmwareUpdateTask:(FDFireflyIce * _Nonnull)fireflyIce;

@end

@interface FDFireflyIceManager : NSObject <CBCentralManagerDelegate>

+ (FDFireflyIceManager * _Nullable)manager;
+ (FDFireflyIceManager * _Nullable)managerWithDelegate:(id<FDFireflyIceManagerDelegate>_Nullable)delegate;
+ (FDFireflyIceManager * _Nullable)managerWithServiceUUID:(CBUUID *_Nonnull)serviceUUID withDelegate:(id<FDFireflyIceManagerDelegate>_Nullable)delegate;

@property id<FDFireflyIceManagerDelegate> _Nullable delegate;
@property CBUUID * _Nullable serviceUUID;
@property NSString * _Nullable identifier;
@property dispatch_queue_t _Nullable centralManagerDispatchQueue;
@property CBCentralManager * _Nullable centralManager;

@property(nonatomic) BOOL active;
@property(nonatomic) BOOL discovery;

- (void)scan:(BOOL)allowDuplicates;

- (void)connectBLE:(FDFireflyIce *_Nonnull)fireflyIce;
- (void)disconnectBLE:(FDFireflyIce *_Nonnull)fireflyIce;

- (NSMutableDictionary *_Nullable)dictionaryFor:(id _Nonnull )object key:(NSString *_Nonnull)key;

- (NSString *_Nullable)nameForPeripheral:(CBPeripheral *_Nonnull)peripheral advertisementData:(NSDictionary *_Nonnull)advertisementData;

- (FDFireflyIce * _Nullable)newFireflyIce:(NSUUID *_Nullable)identifier;

@end
