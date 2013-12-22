//
//  FDFirmwareUpdateTask.m
//  Sync
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDBinary.h"
#import "FDCrypto.h"
#import "FDFireflyIce.h"
#import "FDFireflyIceCoder.h"
#import "FDFireflyIceChannel.h"
#import "FDFirmwareUpdateTask.h"
#import "FDIntelHex.h"
#import "FDFireflyDeviceLogger.h"

#import <CommonCrypto/CommonDigest.h>

#define _log self.fireflyIce.log

@interface FDFirmwareUpdateTask () <FDFireflyIceObserver>

@property FDFireflyIceVersion *version;
@property FDFireflyIceVersion *bootVersion;
@property FDFireflyIceLock *lock;

// sector and page size for external flash memory
@property uint32_t sectorSize;
@property uint32_t pageSize;
@property uint32_t pagesPerSector;

@property NSArray *usedSectors;
@property NSArray *invalidSectors;
@property NSArray *invalidPages;

@property NSMutableArray *updateSectors;
@property NSMutableArray *updatePages;

@property NSMutableArray *getSectors;
@property NSMutableArray *sectorHashes;

@property FDFireflyIceUpdateCommit *updateCommit;

@property NSUInteger lastProgressPercent;

@end

@implementation FDFirmwareUpdateTask

@synthesize firmware = _firmware;

+ (FDFirmwareUpdateTask *)firmwareUpdateTask:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel firmware:(NSData *)firmware
{
    FDFirmwareUpdateTask *firmwareUpdateTask = [[FDFirmwareUpdateTask alloc] init];
    firmwareUpdateTask.fireflyIce = fireflyIce;
    firmwareUpdateTask.channel = channel;
    firmwareUpdateTask.firmware = firmware;
    return firmwareUpdateTask;
}

+ (FDFirmwareUpdateTask *)firmwareUpdateTask:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel resource:(NSString *)resource
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *path = [mainBundle pathForResource:resource ofType:@"hex"];
    if (path == nil) {
        NSBundle *classBundle = [NSBundle bundleForClass:[self class]];
        path = [classBundle pathForResource:resource ofType:@"hex"];
    }
    if (path == nil) {
        @throw [NSException exceptionWithName:@"FirmwareUpdateFileNotFound" reason:@"firmware update file not found" userInfo:nil];
    }
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    FDIntelHex *intelHex = [FDIntelHex intelHex:content address:0x08000 length:0x40000 - 0x08000];
    
    FDFirmwareUpdateTask *firmwareUpdateTask = [[FDFirmwareUpdateTask alloc] init];
    firmwareUpdateTask.fireflyIce = fireflyIce;
    firmwareUpdateTask.channel = channel;
    firmwareUpdateTask.firmware = intelHex.data;
    firmwareUpdateTask.major = [intelHex.properties[@"major"] unsignedShortValue];
    firmwareUpdateTask.minor = [intelHex.properties[@"minor"] unsignedShortValue];
    firmwareUpdateTask.patch = [intelHex.properties[@"patch"] unsignedShortValue];
    
    return firmwareUpdateTask;
}

+ (FDFirmwareUpdateTask *)firmwareUpdateTask:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel
{
    return [FDFirmwareUpdateTask firmwareUpdateTask:fireflyIce channel:channel resource:@"FireflyIce"];
}

- (id)init
{
    if (self = [super init]) {
        self.priority = -100;
        _pageSize = 256;
        _sectorSize = 4096;
        _pagesPerSector = _sectorSize / _pageSize;
        _commit = YES;
    }
    return self;
}

- (NSData *)firmware {
    return _firmware;
}

- (void)setFirmware:(NSData *)unpaddedFirmware
{
    // pad to sector multiple of sector size
    NSMutableData *firmware = [NSMutableData dataWithData:unpaddedFirmware];
    NSUInteger length = firmware.length;
    length = ((length + _sectorSize - 1) / _sectorSize) * _sectorSize;
    firmware.length = length;
    _firmware = firmware;
}

- (void)executorTaskStarted:(FDExecutor *)executor
{
    [super executorTaskStarted:executor];
    
    [self begin];
}

- (void)executorTaskResumed:(FDExecutor *)executor
{
    [super executorTaskResumed:executor];
    
    [self begin];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel version:(FDFireflyIceVersion *)version
{
    _version = version;
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel bootVersion:(FDFireflyIceVersion *)bootVersion
{
    _bootVersion = bootVersion;
}

- (void)begin
{
    _updateSectors = nil;
    _updatePages = nil;
    
    [self.fireflyIce.coder sendGetProperties:self.channel properties:FD_CONTROL_PROPERTY_VERSION];
    [self next:@selector(checkVersion)];
}

- (BOOL)isOutOfDate
{
    if (_downgrade) {
        return (_version.major != _major) || (_version.minor != _minor) || (_version.patch != _patch);
    }
    
    if (_version.major < _major) {
        return YES;
    }
    if (_version.major > _major) {
        return NO;
    }
    if (_version.minor < _minor) {
        return YES;
    }
    if (_version.minor > _minor) {
        return NO;
    }
    if (_version.patch < _patch) {
        return YES;
    }
    if (_version.patch > _patch) {
        return NO;
    }
    return NO;
}

- (void)checkOutOfDate
{
    if ([self isOutOfDate]) {
        FDFireflyDeviceLogInfo(@"firmware %@ is out of date with latest %u.%u.%u (boot loader is version %@)", _version, _major, _minor, _patch, _bootVersion);
        [self next:@selector(getSectorHashes)];
    } else {
        FDFireflyDeviceLogInfo(@"firmware %@ is up to date with latest %u.%u.%u (boot loader is version %@)", _version, _major, _minor, _patch, _bootVersion);
        [self complete];
    }
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel lock:(FDFireflyIceLock *)lock
{
    _lock = lock;
}

- (void)checkLock
{
    if ((_lock.identifier == fd_lock_identifier_update) && [self.channel.name isEqualToString:_lock.ownerName]) {
        FDFireflyDeviceLogDebug(@"acquired update lock");
        [self checkOutOfDate];
    } else {
        FDFireflyDeviceLogDebug(@"update could not acquire lock");
        [self complete];
    }
}

- (void)checkVersion
{
    if (_version.capabilities & FD_CONTROL_CAPABILITY_BOOT_VERSION) {
        [self.fireflyIce.coder sendGetProperties:self.channel properties:FD_CONTROL_PROPERTY_BOOT_VERSION];
        [self next:@selector(checkVersions)];
    } else {
        [self checkVersions];
    }
}

- (void)checkVersions
{
    if (_version.capabilities & FD_CONTROL_CAPABILITY_LOCK) {
        [self.fireflyIce.coder sendLock:self.channel identifier:fd_lock_identifier_update operation:fd_lock_operation_acquire];
        [self next:@selector(checkLock)];
    } else {
        [self checkOutOfDate];
    }
}

- (void)firstSectorHashesCheck
{
    [self checkSectorHashes];
    _invalidSectors = [NSArray arrayWithArray:_updateSectors];
    _invalidPages = [NSArray arrayWithArray:_updatePages];
    
    if (_updateSectors.count == 0) {
        [self commitUpdate];
    } else {
        [self.fireflyIce.coder sendUpdateEraseSectors:self.channel sectors:_updateSectors];
        [self next:@selector(writeNextPage)];
    }
}

- (void)getSomeSectors
{
    if (_getSectors.count > 0) {
        NSUInteger n = MIN(_getSectors.count, 10);
        NSRange range = NSMakeRange(0, n);
        NSArray *sectors = [_getSectors subarrayWithRange:range];
        [_getSectors removeObjectsInRange:range];
        [self.fireflyIce.coder sendUpdateGetSectorHashes:self.channel sectors:sectors];
    } else {
        if (_updatePages == nil) {
            [self next:@selector(firstSectorHashesCheck)];
        } else {
            [self next:@selector(verify)];
        }
    }
}

- (void)getSectorHashes
{
    _sectorHashes = [NSMutableArray array];

    uint16_t sectorCount = (uint16_t)(_firmware.length / _sectorSize);
    _getSectors = [NSMutableArray array];
    for (uint16_t i = 0; i < sectorCount; ++i) {
        [_getSectors addObject:[NSNumber numberWithUnsignedShort:i]];
    }
    _usedSectors = [NSArray arrayWithArray:_getSectors];
    
    [self getSomeSectors];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel sectorHashes:(NSArray *)sectorHashes
{
    [_sectorHashes addObjectsFromArray:sectorHashes];
    
    [self getSomeSectors];
}

- (void)checkSectorHashes
{
    _updateSectors = nil;
    _updatePages = nil;
    
    NSMutableArray *updateSectors = [NSMutableArray array];
    NSMutableArray *updatePages = [NSMutableArray array];
    uint16_t sectorCount = (uint16_t)(_firmware.length / _sectorSize);
    for (uint16_t i = 0; i < sectorCount; ++i) {
        uint16_t sector = i;
        FDFireflyIceSectorHash *sectorHash = _sectorHashes[i];
        if (sectorHash.sector != sector) {
            @throw [NSException exceptionWithName:@"unexpected" reason:@"unexpected" userInfo:nil];
        }
        NSData * hash = [FDCrypto sha1:[_firmware subdataWithRange:NSMakeRange(i * _sectorSize, _sectorSize)]];
        if (![hash isEqualToData:sectorHash.hash]) {
            [updateSectors addObject:[NSNumber numberWithUnsignedShort:sectorHash.sector]];
            uint16_t page = sector * _pagesPerSector;
            for (uint16_t i = 0; i < _pagesPerSector; ++i) {
                [updatePages addObject:[NSNumber numberWithUnsignedShort:page + i]];
            }
        }
    }

    _updateSectors = updateSectors;
    _updatePages = updatePages;

    if (updateSectors.count == 0) {
        return;
    }
    
    FDFireflyDeviceLogInfo(@"updating pages %@", _updatePages);
}

- (void)writeNextPage
{
    float progress = (_invalidPages.count - _updatePages.count) / (float)_invalidPages.count;
    [_delegate firmwareUpdateTask:self progress:progress];
    NSUInteger progressPercent = (NSUInteger)(progress * 100);
    if (_lastProgressPercent != progressPercent) {
        _lastProgressPercent = progressPercent;
        FDFireflyDeviceLogInfo(@"firmware update progress %lu%%", (unsigned long) (unsigned long)progressPercent);
    }
    
    if (_updatePages.count == 0) {
        // noting left to write, check the hashes to confirm
        [self getSectorHashes];
    } else {
        uint16_t page = [_updatePages[0] unsignedShortValue];
        [_updatePages removeObjectAtIndex:0];
        NSInteger location = page * _pageSize;
        NSData *data = [_firmware subdataWithRange:NSMakeRange(location, _pageSize)];
        [self.fireflyIce.coder sendUpdateWritePage:self.channel page:page data:data];
        [self next:@selector(writeNextPage)];
    }
}

- (void)verify
{
    [self checkSectorHashes];
    if (_updateSectors.count == 0) {
        [self commitUpdate];
    } else {
        [self complete];
    }
}

- (void)commitUpdate
{
    if (!_commit) {
        [self complete];
        return;
    }
    
    FDFireflyDeviceLogInfo(@"sending update commit");
    uint32_t flags = 0;
    uint32_t length = (uint32_t)_firmware.length;
    NSData *hash = [FDCrypto sha1:_firmware];
    NSData *cryptHash = hash;
    NSMutableData *cryptIv = [NSMutableData data];
    cryptIv.length = 16;
    [self.fireflyIce.coder sendUpdateCommit:self.channel flags:flags length:length hash:hash cryptHash:cryptHash cryptIv:cryptIv];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel updateCommit:(FDFireflyIceUpdateCommit *)updateCommit
{
    _updateCommit = updateCommit;
    [self complete];
}

- (void)complete
{
    if (_version.capabilities & FD_CONTROL_CAPABILITY_LOCK) {
        FDFireflyDeviceLogDebug(@"released update lock");
        [self.fireflyIce.coder sendLock:self.channel identifier:fd_lock_identifier_update operation:fd_lock_operation_release];
    }
    
    BOOL isFirmwareUpToDate = (_updatePages.count == 0);
    FDFireflyDeviceLogInfo(@"isFirmwareUpToDate = %@, commit %@ result = %u", isFirmwareUpToDate ? @"YES" : @"NO", _updateCommit != nil ? @"YES" : @"NO", _updateCommit.result);
    [_delegate firmwareUpdateTask:self complete:isFirmwareUpToDate];
    if (_reset && [self isOutOfDate] && isFirmwareUpToDate && (_updateCommit != nil) && (_updateCommit.result == FD_UPDATE_COMMIT_SUCCESS)) {
        FDFireflyDeviceLogInfo(@"new firmware has been transferred and comitted - restarting device");
        [self.fireflyIce.coder sendReset:self.channel type:FD_CONTROL_RESET_SYSTEM_REQUEST];
    }
    [self done];
}

@end
