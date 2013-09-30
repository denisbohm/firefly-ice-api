//
//  FDFireflyIceCoder.h
//  Sync
//
//  Created by Denis Bohm on 7/19/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIceChannel.h"

#define FD_CONTROL_PING 1

#define FD_CONTROL_GET_PROPERTIES 2
#define FD_CONTROL_SET_PROPERTIES 3

#define FD_CONTROL_PROVISION 4
#define FD_CONTROL_RESET 5

#define FD_CONTROL_UPDATE_GET_SECTOR_HASHES 6
#define FD_CONTROL_UPDATE_ERASE_SECTORS 7
#define FD_CONTROL_UPDATE_WRITE_PAGE 8
#define FD_CONTROL_UPDATE_COMMIT 9

#define FD_CONTROL_RADIO_DIRECT_TEST_MODE_ENTER 10
#define FD_CONTROL_RADIO_DIRECT_TEST_MODE_EXIT 11
#define FD_CONTROL_RADIO_DIRECT_TEST_MODE_REPORT 12

#define FD_CONTROL_DISCONNECT 13

#define FD_CONTROL_INDICATOR_OVERRIDE 14

#define FD_CONTROL_SYNC_START 15
#define FD_CONTROL_SYNC_DATA 16
#define FD_CONTROL_SYNC_ACK 17

// property bits for get/set property commands
#define FD_CONTROL_PROPERTY_VERSION     0x00000001
#define FD_CONTROL_PROPERTY_HARDWARE_ID 0x00000002
#define FD_CONTROL_PROPERTY_DEBUG_LOCK  0x00000004
#define FD_CONTROL_PROPERTY_RTC         0x00000008
#define FD_CONTROL_PROPERTY_POWER       0x00000010
#define FD_CONTROL_PROPERTY_SITE        0x00000020
#define FD_CONTROL_PROPERTY_RESET       0x00000040
#define FD_CONTROL_PROPERTY_STORAGE     0x00000080
#define FD_CONTROL_PROPERTY_MODE        0x00000100

#define FD_CONTROL_RESET_SYSTEM_REQUEST 1
#define FD_CONTROL_RESET_WATCHDOG 2
#define FD_CONTROL_RESET_HARD_FAULT 3

#define FD_CONTROL_MODE_STORAGE 1

#define FD_UPDATE_METADATA_FLAG_ENCRYPTED 0x00000001

typedef enum {
    FDDirectTestModeCommandReset=0b00,
    FDDirectTestModeCommandReceiverTest=0b01,
    FDDirectTestModeCommandTransmitterTest=0b10,
    FDDirectTestModeCommandTestEnd=0b11
} FDDirectTestModeCommand;

typedef enum {
    FDDirectTestModePacketTypePRBS9=0b00,
    FDDirectTestModePacketTypeF0=0b01,
    FDDirectTestModePacketTypeAA=0b10,
    FDDirectTestModePacketTypeVendorSpecific=0b11
} FDDirectTestModePacketType;

@class FDFireflyIce;
@class FDFireflyIceObservable;
@protocol FDFireflyIceObserver;

@interface FDFireflyIceCoder : NSObject

@property FDFireflyIceObservable *observable;

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel packet:(NSData *)data;

- (void)sendPing:(id<FDFireflyIceChannel>)channel data:(NSData *)data;

- (void)sendGetProperties:(id<FDFireflyIceChannel>)channel properties:(uint32_t)properties;
- (void)sendSetPropertyTime:(id<FDFireflyIceChannel>)channel time:(NSDate *)time;
- (void)sendSetPropertyMode:(id<FDFireflyIceChannel>)channel mode:(uint8_t)mode;

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

+ (uint16_t)makeDirectTestModePacket:(FDDirectTestModeCommand)command
                           frequency:(uint8_t)frequency
                              length:(uint8_t)length
                                type:(FDDirectTestModePacketType)type;
- (void)sendDirectTestModeEnter:(id<FDFireflyIceChannel>)channel
                         packet:(uint16_t)packet
                       duration:(NSTimeInterval)duration;
- (void)sendDirectTestModeExit:(id<FDFireflyIceChannel>)channel;
- (void)sendDirectTestModeReport:(id<FDFireflyIceChannel>)channel;

- (void)sendDirectTestModeReset:(id<FDFireflyIceChannel>)channel;
- (void)sendDirectTestModeReceiverTest:(id<FDFireflyIceChannel>)channel
                             frequency:(uint8_t)frequency
                                length:(uint8_t)length
                                  type:(FDDirectTestModePacketType)type
                              duration:(NSTimeInterval)duration;
- (void)sendDirectTestModeTransmitterTest:(id<FDFireflyIceChannel>)channel
                                frequency:(uint8_t)frequency
                                   length:(uint8_t)length
                                     type:(FDDirectTestModePacketType)type
                                 duration:(NSTimeInterval)duration;
- (void)sendDirectTestModeEnd:(id<FDFireflyIceChannel>)channel;

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

