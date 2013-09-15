//
//  FDFireflyIceCoder.h
//  Sync
//
//  Created by Denis Bohm on 7/19/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIceChannel.h"

// property bits for get/set propery commands
#define FD_CONTROL_PROPERTY_VERSION     0x00000001
#define FD_CONTROL_PROPERTY_HARDWARE_ID 0x00000002
#define FD_CONTROL_PROPERTY_DEBUG_LOCK  0x00000004
#define FD_CONTROL_PROPERTY_RTC         0x00000008
#define FD_CONTROL_PROPERTY_POWER       0x00000010
#define FD_CONTROL_PROPERTY_SITE        0x00000020

#define FD_UPDATE_METADATA_FLAG_ENCRYPTED 0x00000001

@class FDFireflyIceObservable;
@protocol FDFireflyIceObserver;

@interface FDFireflyIceCoder : NSObject

@property FDFireflyIceObservable *observable;

- (void)fireflyIceChannelPacket:(id<FDFireflyIceChannel>)channel data:(NSData *)data;

- (void)sendPing:(id<FDFireflyIceChannel>)channel data:(NSData *)data;

- (void)sendGetProperties:(id<FDFireflyIceChannel>)channel properties:(uint32_t)properties;
- (void)sendSetPropertyTime:(id<FDFireflyIceChannel>)channel time:(NSDate *)time;

- (void)sendProvision:(id<FDFireflyIceChannel>)channel dictionary:(NSDictionary *)dictionary options:(uint32_t)options;
- (void)sendReset:(id<FDFireflyIceChannel>)channel type:(uint8_t)type;

- (void)sendUpdateGetSectorHashes:(id<FDFireflyIceChannel>)channel sectors:(NSArray *)sectors;
- (void)sendUpdateEraseSectors:(id<FDFireflyIceChannel>)channel sectors:(NSArray *)sectors;
- (void)sendUpdateWritePage:(id<FDFireflyIceChannel>)channel page:(uint16_t)page data:(NSData *)data;
- (void)sendUpdateCommit:(id<FDFireflyIceChannel>)channel
                   flags:(uint32_t)flags
                  length:(uint32_t)length
                    hash:(NSData *)hash
               cryptHash:(NSData *)cryptHash
                 cryptIv:(NSData *)cryptIv;

- (void)sendIndicatorOverride:(id<FDFireflyIceChannel>)channel
                    usbOrange:(uint8_t)usbOrange
                     usbGreen:(uint8_t)usbGreen
                           d0:(uint8_t)d0
                           d1:(uint32_t)d1
                           d2:(uint32_t)d2
                           d3:(uint32_t)d3
                           d4:(uint8_t)d4
                     duration:(NSTimeInterval)duration;

- (void)sendSyncStart:(id<FDFireflyIceChannel>)channel;

@end

