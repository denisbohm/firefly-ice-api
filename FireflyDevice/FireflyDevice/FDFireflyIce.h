//
//  FDFireflyIce.h
//  FireflyDevice
//
//  Created by Denis Bohm on 7/18/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDFireflyIceChannel.h>
#import <FireflyDevice/FDObservable.h>

@interface FDFireflyIceVersion : NSObject
@property uint16_t major;
@property uint16_t minor;
@property uint16_t patch;
@property uint32_t capabilities;
@property NSData *gitCommit;
@end

@interface FDFireflyIceHardwareVersion : NSObject
@property uint16_t major;
@property uint16_t minor;
@end

@interface FDFireflyIceUpdateBinary : NSObject
@property uint32_t flags;
@property uint32_t length;
@property NSData *clearHash;
@property NSData *cryptHash;
@property NSData *cryptIV;
@end

@interface FDFireflyIceUpdateMetadata : NSObject
@property FDFireflyIceUpdateBinary *binary;
@property FDFireflyIceVersion *revision;
@end

@interface FDFireflyIceUpdateVersion : NSObject
@property FDFireflyIceVersion *revision;
@property FDFireflyIceUpdateMetadata *metadata;
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
@property NSData *hashValue;
@end

@interface FDFireflyIceReset : NSObject
@property uint32_t cause;
@property NSDate *date;

+ (NSString *)causeDescription:(uint32_t)cause;
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
    FDLockOwnerNone = 0,
    FDLockOwnerBle = FD_LOCK_OWNER_ENCODE('B', 'L', 'E', ' '),
    FDLockOwnerUsb = FD_LOCK_OWNER_ENCODE('U', 'S', 'B', ' '),
    FDLockOwnerInet = FD_LOCK_OWNER_ENCODE('I', 'N', 'E', 'T'),
};
typedef uint32_t FDLockOwner;

enum {
    FDLockOperationNone,
    FDLockOperationAcquire,
    FDLockOperationRelease,
};
typedef uint8_t FDLockOperation;

enum {
    FDLockIdentifierSync,
    FDLockIdentifierUpdate,
};
typedef uint8_t FDLockIdentifier;

@interface FDFireflyIceLock : NSObject

@property FDLockIdentifier identifier;
@property FDLockOperation operation;
@property FDLockOwner owner;

@property(readonly) NSString *identifierName;
@property(readonly) NSString *operationName;
@property(readonly) NSString *ownerName;

@end

@interface FDFireflyIceLogging : NSObject

@property uint32_t flags;
@property uint32_t count;
@property uint32_t state;

@end

@interface FDFireflyIceDiagnosticsBLE : NSObject

@property uint32_t version;
@property uint32_t systemSteps;
@property uint32_t dataSteps;
@property uint32_t systemCredits;
@property uint32_t dataCredits;
@property uint8_t txPower;
@property uint8_t operatingMode;
@property uint8_t idle;
@property uint8_t dtm;
@property uint8_t did;
@property uint8_t disconnectAction;
@property uint64_t pipesOpen;
@property uint16_t dtmRequest;
@property uint16_t dtmData;
@property uint32_t bufferCount;

@end

@interface FDFireflyIceDiagnostics : NSObject

@property uint32_t flags;
@property NSArray *values;

@end

@interface FDFireflyIceRetained : NSObject

@property BOOL retained;
@property NSData *data;

@end

@class FDDetour;
@class FDFireflyIce;
@protocol FDFireflyDeviceLog;

/// @brief Protocol used to observe messages sent from the Firefly Ice device to your iOS or Mac OS X device.  Typically sent in response to commands sent from your iOS or Mac OS X device to the Firefly Ice device.
@protocol FDFireflyIceObserver <NSObject>

@optional

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel status:(FDFireflyIceChannelStatus)status;

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel detour:(FDDetour *)detour error:(NSError *)error;

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel ping:(NSData *)data;

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel version:(FDFireflyIceVersion *)version;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel hardwareVersion:(FDFireflyIceHardwareVersion *)version;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel hardwareId:(FDFireflyIceHardwareId *)hardwareId;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel bootVersion:(FDFireflyIceVersion *)version;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel debugLock:(NSNumber *)debugLock;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel time:(NSDate *)time;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel rtc:(NSDictionary *)dictionary;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel hardware:(NSDictionary *)hardware;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel power:(FDFireflyIcePower *)power;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel site:(NSString *)site;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel reset:(FDFireflyIceReset *)reset;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel storage:(FDFireflyIceStorage *)storage;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel mode:(NSNumber *)mode;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel txPower:(NSNumber *)level;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel regulator:(NSNumber *)regulator;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel sensingCount:(NSNumber *)sensingCount;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel indicate:(NSNumber *)indicate;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel recognition:(NSNumber *)recognition;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel lock:(FDFireflyIceLock *)lock;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel logging:(FDFireflyIceLogging *)logging;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel name:(NSString *)name;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel diagnostics:(FDFireflyIceDiagnostics *)diagnostics;
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel retained:(FDFireflyIceRetained *)retained;

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel directTestModeReport:(FDFireflyIceDirectTestModeReport *)directTestModeReport;

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel updateVersion:(FDFireflyIceUpdateVersion*)version;
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

@property id<FDFireflyDeviceLog> log;

@property FDFireflyIceCoder *coder;

@property(nonatomic, readonly) FDFireflyIceObservable *observable;

@property NSMutableDictionary *channels;

@property NSString *name;

@property FDFireflyIceVersion *version;
@property FDFireflyIceHardwareId *hardwareId;
@property FDFireflyIceVersion *bootVersion;

@property FDExecutor *executor;

- (void)addChannel:(id<FDFireflyIceChannel>)channel type:(NSString *)type;
- (void)removeChannel:(NSString *)type;

@end
