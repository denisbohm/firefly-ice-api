//
//  FDFireflyIceCoder.h
//  FireflyDevice
//
//  Created by Denis Bohm on 7/19/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceChannel.h>

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

#define FD_CONTROL_LED_OVERRIDE 14

#define FD_CONTROL_SYNC_START 15
#define FD_CONTROL_SYNC_DATA 16
#define FD_CONTROL_SYNC_ACK 17

#define FD_CONTROL_UPDATE_GET_EXTERNAL_HASH 18
#define FD_CONTROL_UPDATE_READ_PAGE 19

#define FD_CONTROL_LOCK 20

#define FD_CONTROL_IDENTIFY 21

#define FD_CONTROL_DIAGNOSTICS 22

#define FD_CONTROL_SENSING_SYNTHESIZE 23

#define FD_CONTROL_UPDATE_AREA_GET_VERSION 24
#define FD_CONTROL_UPDATE_AREA_GET_EXTERNAL_HASH 25
#define FD_CONTROL_UPDATE_AREA_GET_SECTOR_HASHES 26
#define FD_CONTROL_UPDATE_AREA_ERASE_SECTORS 27
#define FD_CONTROL_UPDATE_AREA_WRITE_PAGE 28
#define FD_CONTROL_UPDATE_AREA_READ_PAGE 29
#define FD_CONTROL_UPDATE_AREA_COMMIT 30

#define FD_CONTROL_DIAGNOSTICS_BLE        0x00000001
#define FD_CONTROL_DIAGNOSTICS_BLE_TIMING 0x00000002

#define FD_CONTROL_SYNC_AHEAD 0x00000001

#define FD_CONTROL_LOGGING_STATE 0x00000001
#define FD_CONTROL_LOGGING_COUNT 0x00000002

#define FD_CONTROL_LOGGING_STORAGE 0x00000001

#define FD_CONTROL_UPDATE_AREA_GET_VERSION_FLAG_REVISION 0x00000001
#define FD_CONTROL_UPDATE_AREA_GET_VERSION_FLAG_METADATA 0x00000002

#define FD_CONTROL_CAPABILITY_LOCK             0x00000001
#define FD_CONTROL_CAPABILITY_BOOT_VERSION     0x00000002
#define FD_CONTROL_CAPABILITY_SYNC_FLAGS       0x00000004
#define FD_CONTROL_CAPABILITY_SYNC_AHEAD       0x00000004
#define FD_CONTROL_CAPABILITY_IDENTIFY         0x00000008
#define FD_CONTROL_CAPABILITY_LOGGING          0x00000010
#define FD_CONTROL_CAPABILITY_DIAGNOSTICS      0x00000010
#define FD_CONTROL_CAPABILITY_NAME             0x00000020
#define FD_CONTROL_CAPABILITY_RETAINED         0x00000040
#define FD_CONTROL_CAPABILITY_ADC_VDD          0x00000080
#define FD_CONTROL_CAPABILITY_REGULATOR        0x00000100
#define FD_CONTROL_CAPABILITY_SENSING_COUNT    0x00000200
#define FD_CONTROL_CAPABILITY_INDICATE         0x00000400
#define FD_CONTROL_CAPABILITY_RECOGNITION      0x00000800
#define FD_CONTROL_CAPABILITY_HARDWARE_VERSION 0x00001000
#define FD_CONTROL_CAPABILITY_UPDATE_AREA      0x00002000

// property bits for get/set property commands
#define FD_CONTROL_PROPERTY_VERSION          0x00000001
#define FD_CONTROL_PROPERTY_HARDWARE_ID      0x00000002
#define FD_CONTROL_PROPERTY_DEBUG_LOCK       0x00000004
#define FD_CONTROL_PROPERTY_RTC              0x00000008
#define FD_CONTROL_PROPERTY_POWER            0x00000010
#define FD_CONTROL_PROPERTY_SITE             0x00000020
#define FD_CONTROL_PROPERTY_RESET            0x00000040
#define FD_CONTROL_PROPERTY_STORAGE          0x00000080
#define FD_CONTROL_PROPERTY_MODE             0x00000100
#define FD_CONTROL_PROPERTY_TX_POWER         0x00000200
#define FD_CONTROL_PROPERTY_BOOT_VERSION     0x00000400
#define FD_CONTROL_PROPERTY_LOGGING          0x00000800
#define FD_CONTROL_PROPERTY_NAME             0x00001000
#define FD_CONTROL_PROPERTY_RETAINED         0x00002000
#define FD_CONTROL_PROPERTY_ADC_VDD          0x00004000
#define FD_CONTROL_PROPERTY_REGULATOR        0x00008000
#define FD_CONTROL_PROPERTY_SENSING_COUNT    0x00010000
#define FD_CONTROL_PROPERTY_INDICATE         0x00020000
#define FD_CONTROL_PROPERTY_RECOGNITION      0x00040000
#define FD_CONTROL_PROPERTY_HARDWARE_VERSION 0x00080000

#define FD_CONTROL_PROVISION_OPTION_DEBUG_LOCK    0x00000001
#define FD_CONTROL_PROVISION_OPTION_RESET         0x00000002
#define FD_CONTROL_PROVISION_OPTION_SENSING_ERASE 0x00000004

#define FD_CONTROL_RESET_SYSTEM_REQUEST 1
#define FD_CONTROL_RESET_WATCHDOG 2
#define FD_CONTROL_RESET_HARD_FAULT 3

#define FD_CONTROL_MODE_STORAGE 1

#define FD_HAL_SYSTEM_AREA_BOOTLOADER 0
#define FD_HAL_SYSTEM_AREA_APPLICATION 1
#define FD_HAL_SYSTEM_AREA_OPERATING_SYSTEM 2

#define FD_UPDATE_METADATA_FLAG_ENCRYPTED 0x00000001

#define FD_UPDATE_COMMIT_SUCCESS 0
#define FD_UPDATE_COMMIT_FAIL_HASH_MISMATCH 1
#define FD_UPDATE_COMMIT_FAIL_CRYPT_HASH_MISMATCH 2
#define FD_UPDATE_COMMIT_FAIL_UNSUPPORTED 3

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

typedef void (^FDFireflyIceCoderCommandBlock)(FDFireflyIce *fireflyIce, id<FDFireflyIceChannel> channel, NSData *data);

@interface FDFireflyIceCoder : NSObject

@property FDFireflyIceObservable *observable;

- (void)setCommand:(uint8_t)code block:(FDFireflyIceCoderCommandBlock)block;
- (FDFireflyIceCoderCommandBlock)getCommandBlock:(uint8_t)code;

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel packet:(NSData *)data;

- (void)sendPing:(id<FDFireflyIceChannel>)channel data:(NSData *)data;

- (void)sendGetProperties:(id<FDFireflyIceChannel>)channel properties:(uint32_t)properties;
- (void)sendSetPropertyTime:(id<FDFireflyIceChannel>)channel time:(NSDate *)time;
- (void)sendSetPropertyMode:(id<FDFireflyIceChannel>)channel mode:(uint8_t)mode;
- (void)sendSetPropertyTxPower:(id<FDFireflyIceChannel>)channel level:(uint8_t)level;
- (void)sendSetPropertyLogging:(id<FDFireflyIceChannel>)channel storage:(BOOL)storage;
- (void)sendSetPropertyName:(id<FDFireflyIceChannel>)channel name:(NSString *)name;
- (void)sendSetPropertyRegulator:(id<FDFireflyIceChannel>)channel regulator:(uint8_t)regulator;
- (void)sendSetPropertySensingCount:(id<FDFireflyIceChannel>)channel count:(uint32_t)count;
- (void)sendSetPropertyIndicate:(id<FDFireflyIceChannel>)channel indicate:(BOOL)indicate;
- (void)sendSetPropertyRecognition:(id<FDFireflyIceChannel>)channel recognition:(BOOL)recognition;

- (void)sendProvision:(id<FDFireflyIceChannel>)channel dictionary:(NSDictionary *)dictionary options:(uint32_t)options;
- (void)sendReset:(id<FDFireflyIceChannel>)channel type:(uint8_t)type;

- (void)sendUpdateGetExternalHash:(id<FDFireflyIceChannel>)channel address:(uint32_t)address length:(uint32_t)length;
- (void)sendUpdateReadPage:(id<FDFireflyIceChannel>)channel page:(uint32_t)page;
- (void)sendUpdateGetSectorHashes:(id<FDFireflyIceChannel>)channel sectors:(NSArray *)sectors;
- (void)sendUpdateEraseSectors:(id<FDFireflyIceChannel>)channel sectors:(NSArray *)sectors;
- (void)sendUpdateWritePage:(id<FDFireflyIceChannel>)channel page:(uint16_t)page data:(NSData *)data;
- (void)sendUpdateCommit:(id<FDFireflyIceChannel>)channel
                   flags:(uint32_t)flags
                  length:(uint32_t)length
                    hash:(NSData *)hash
               cryptHash:(NSData *)cryptHash
                 cryptIv:(NSData *)cryptIv;


- (void)sendUpdateGetVersion:(id<FDFireflyIceChannel>)channel area:(uint8_t)area;
- (void)sendUpdateGetExternalHash:(id<FDFireflyIceChannel>)channel area:(uint8_t)area address:(uint32_t)address length:(uint32_t)length;
- (void)sendUpdateGetSectorHashes:(id<FDFireflyIceChannel>)channel area:(uint8_t)area sectors:(NSArray *)sectors;
- (void)sendUpdateEraseSectors:(id<FDFireflyIceChannel>)channel area:(uint8_t)area sectors:(NSArray *)sectors;
- (void)sendUpdateWritePage:(id<FDFireflyIceChannel>)channel area:(uint8_t)area page:(uint16_t)page data:(NSData *)data;
- (void)sendUpdateReadPage:(id<FDFireflyIceChannel>)channel area:(uint8_t)area page:(uint32_t)page;
- (void)sendUpdateCommit:(id<FDFireflyIceChannel>)channel
                    area:(uint8_t)area
                   flags:(uint32_t)flags
                  length:(uint32_t)length
                    hash:(NSData *)hash
               cryptHash:(NSData *)cryptHash
                 cryptIv:(NSData *)cryptIv
                   major:(uint16_t)major
                   minor:(uint16_t)minor
                   patch:(uint16_t)patch
            capabilities:(uint32_t)capabilities
                  commit:(NSData *)commit;

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

- (void)sendLEDOverride:(id<FDFireflyIceChannel>)channel
              usbOrange:(uint8_t)usbOrange
               usbGreen:(uint8_t)usbGreen
                     d0:(uint8_t)d0
                     d1:(uint32_t)d1
                     d2:(uint32_t)d2
                     d3:(uint32_t)d3
                     d4:(uint8_t)d4
               duration:(NSTimeInterval)duration;

- (void)sendIdentify:(id<FDFireflyIceChannel>)channel duration:(NSTimeInterval)duration;

- (void)sendLock:(id<FDFireflyIceChannel>)channel identifier:(fd_lock_identifier_t)identifier operation:(fd_lock_operation_t)operation;

- (void)sendSyncStart:(id<FDFireflyIceChannel>)channel;
- (void)sendSyncStart:(id<FDFireflyIceChannel>)channel offset:(uint32_t)offset;

- (void)sendDiagnostics:(id<FDFireflyIceChannel>)channel flags:(uint32_t)flags;

- (void)sendSensingSynthesize:(id<FDFireflyIceChannel>)channel samples:(uint32_t)samples vma:(float)vma;

@end

