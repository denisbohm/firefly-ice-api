//
//  FDFireflyIce.h
//  Sync
//
//  Created by Denis Bohm on 7/18/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIceChannel.h"
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

@interface FDFireflyIceReset : NSObject
@property uint32_t cause;
@property NSDate *date;
@end

@interface FDFireflyIceStorage : NSObject
@property uint32_t pageCount;
@end

@interface FDFireflyIceDirectTestModeReport : NSObject
@property uint16_t packetCount;
@end

@interface FDFireflyIceUpdateCommit : NSObject
@property uint8_t result;
@end

@interface FDFireflyIceSensing : NSObject
@property float ax;
@property float ay;
@property float az;
@property float mx;
@property float my;
@property float mz;
@end

#define FD_LOCK_OWNER_ENCODE(a, b, c, d) ((a << 24) | (b << 16) | (c << 8) | d)

void fd_lock_initialize(void);

enum {
    fd_lock_owner_none = 0,
    fd_lock_owner_ble = FD_LOCK_OWNER_ENCODE('B', 'L', 'E', ' '),
    fd_lock_owner_usb = FD_LOCK_OWNER_ENCODE('U', 'S', 'B', ' '),
};
typedef uint32_t fd_lock_owner_t;

enum {
    fd_lock_operation_none,
    fd_lock_operation_acquire,
    fd_lock_operation_release,
};
typedef uint8_t fd_lock_operation_t;

enum {
    fd_lock_identifier_sync,
    fd_lock_identifier_update,
};
typedef uint8_t fd_lock_identifier_t;

@interface FDFireflyIceLock : NSObject

@property fd_lock_identifier_t identifier;
@property fd_lock_operation_t operation;
@property fd_lock_owner_t owner;

@property(readonly) NSString *identifierName;
@property(readonly) NSString *operationName;
@property(readonly) NSString *ownerName;

@end

@class FDDetour;
@class FDFireflyIce;

@protocol FDFireflyIceObserver <NSObject>

@optional

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel status:(FDFireflyIceChannelStatus)status;

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel detour:(FDDetour *)detour error:(NSError *)error;

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel ping:(NSData *)data;

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel version:(FDFireflyIceVersion *)version;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel hardwareId:(FDFireflyIceHardwareId *)hardwareId;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel debugLock:(NSNumber *)debugLock;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel time:(NSDate *)time;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel power:(FDFireflyIcePower *)power;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel site:(NSString *)site;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel reset:(FDFireflyIceReset *)reset;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel storage:(FDFireflyIceStorage *)storage;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel mode:(NSNumber *)mode;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel txPower:(NSNumber *)level;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel lock:(FDFireflyIceLock *)lock;

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel directTestModeReport:(FDFireflyIceDirectTestModeReport *)directTestModeReport;

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel externalHash:(NSData *)externalHash;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel pageData:(NSData *)pageData;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel sectorHashes:(NSArray *)sectorHashes;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel updateCommit:(FDFireflyIceUpdateCommit *)updateCommit;

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel sensing:(FDFireflyIceSensing *)sensing;

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel syncData:(NSData *)data;

@end

@class FDExecutor;

@interface FDFireflyIceObservable : FDObservable <FDFireflyIceObserver>
@end

@class FDFireflyIceCoder;

@interface FDFireflyIce : NSObject

@property FDFireflyIceCoder *coder;

@property(nonatomic, readonly) FDFireflyIceObservable *observable;

@property NSMutableDictionary *channels;

@property NSString *name;
@property FDFireflyIceVersion *version;
@property FDFireflyIceHardwareId *hardwareId;

@property FDExecutor *executor;

- (void)addChannel:(id<FDFireflyIceChannel>)channel type:(NSString *)type;
- (void)removeChannel:(NSString *)type;

@end
