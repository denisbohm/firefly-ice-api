//
//  FDFireflyIceManager.h
//  FireflyDevice
//
//  Created by Denis Bohm on 9/30/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIce.h"
#import "FDFireflyIceChannelBLE.h"

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

- (void)fireflyIceManager:(FDFireflyIceManager *)manager openedBLE:(FDFireflyIce *)fireflyIce;
- (void)fireflyIceManager:(FDFireflyIceManager *)manager closedBLE:(FDFireflyIce *)fireflyIce;

- (void)fireflyIceManager:(FDFireflyIceManager *)manager identified:(FDFireflyIce *)fireflyIce;

@end

@interface FDFireflyIceManager : NSObject <CBCentralManagerDelegate>

+ (FDFireflyIceManager *)managerWithDelegate:(id<FDFireflyIceManagerDelegate>)delegate;

@property id<FDFireflyIceManagerDelegate> delegate;

@property CBCentralManager *centralManager;

- (void)connectBLE:(FDFireflyIce *)fireflyIce;
- (void)disconnectBLE:(FDFireflyIce *)fireflyIce;

@end
