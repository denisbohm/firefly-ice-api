//
//  FDFirmwareUpdateTask.m
//  FireflyDevice
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDBinary.h>
#import <FireflyDevice/FDCrypto.h>
#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceCoder.h>
#import <FireflyDevice/FDFireflyIceChannel.h>
#import <FireflyDevice/FDFirmwareUpdateTask.h>
#import <FireflyDevice/FDIntelHex.h>
#import <FireflyDevice/FDFireflyDeviceLogger.h>

#import <CommonCrypto/CommonDigest.h>

#define _log self.fireflyIce.log

@interface FDFirmwareUpdateTask () <FDFireflyIceObserver>

@property FDFireflyIceVersion *version;
@property FDFireflyIceVersion *updateVersion;
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

+ (NSArray *)loadAllFirmwareVersions:(NSString *)resource bundle:(NSBundle *)bundle
{
    NSMutableArray *versions = [NSMutableArray array];
    NSArray *paths = [bundle pathsForResourcesOfType:@"hex" inDirectory:nil];
    for (NSString *path in paths) {
        [versions addObject:[FDFirmwareUpdateTask loadFirmwareFromPath:path]];
    }
    return versions;
}

+ (NSArray *)loadAllFirmwareVersions:(NSString *)resource
{
    NSMutableArray *versions = [NSMutableArray array];
    
    NSBundle *frameworkBundle = [NSBundle bundleForClass:[FDFirmwareUpdateTask class]];
    [versions addObjectsFromArray:[FDFirmwareUpdateTask loadAllFirmwareVersions:resource bundle:frameworkBundle]];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    if (mainBundle != frameworkBundle) {
        [versions addObjectsFromArray:[FDFirmwareUpdateTask loadAllFirmwareVersions:resource bundle:mainBundle]];
    }
    
    return [versions sortedArrayUsingComparator: ^(id oa, id ob) {
        FDIntelHex *a = (FDIntelHex *)oa;
        FDIntelHex *b = (FDIntelHex *)ob;
        return [a.properties[@"patch"] compare:b.properties[@"patch"]];
    }];
}

+ (FDIntelHex *)loadFirmware:(NSString *)resource
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
    return [self loadFirmwareFromPath:path];
}

+ (FDIntelHex *)loadFirmwareFromPath:(NSString *)path
{
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    return [FDIntelHex intelHex:content address:0x08000 length:0x40000 - 0x08000];
}

+ (NSData *)dataWithHexString:(NSString *)hex
{
    if (([hex length] % 2) != 0) {
        @throw [NSException exceptionWithName:@"FirmwareInvalidHex" reason:@"firmware invalid hex" userInfo:nil];
    }
    NSMutableData *data = [NSMutableData data];
    for (int i = 0; i < hex.length; i += 2) {
        char buffer[] = {[hex characterAtIndex:i], [hex characterAtIndex:i + 1], '\0'};
        char byte = strtol(buffer, NULL, 16);
        [data appendBytes:&byte length:1];
    }
    return data;
}

+ (uint32_t)getHexUInt32:(NSString *)hex
{
    if (hex) {
        NSScanner *scanner = [NSScanner scannerWithString:hex];
        unsigned int value = 0;
        if ([scanner scanHexInt:&value]) {
            return value;
        }
    }
    return 0;
}

+ (FDFirmwareUpdateTask *)firmwareUpdateTask:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel intelHex:(FDIntelHex *)intelHex
{
    FDFirmwareUpdateTask *firmwareUpdateTask = [[FDFirmwareUpdateTask alloc] init];
    firmwareUpdateTask.fireflyIce = fireflyIce;
    firmwareUpdateTask.channel = channel;

    firmwareUpdateTask.major = [intelHex.properties[@"major"] unsignedShortValue];
    firmwareUpdateTask.minor = [intelHex.properties[@"minor"] unsignedShortValue];
    firmwareUpdateTask.patch = [intelHex.properties[@"patch"] unsignedShortValue];
    firmwareUpdateTask.capabilities = [FDFirmwareUpdateTask getHexUInt32:intelHex.properties[@"capabilities"]];
    firmwareUpdateTask.gitCommit = [FDFirmwareUpdateTask dataWithHexString:intelHex.properties[@"commit"]];
    
    firmwareUpdateTask.firmware = intelHex.data;
    if ([intelHex.properties[@"encrypted"] boolValue]) {
        firmwareUpdateTask.commitFlags = FD_UPDATE_METADATA_FLAG_ENCRYPTED;
        firmwareUpdateTask.commitLength = [FDFirmwareUpdateTask getHexUInt32:intelHex.properties[@"length"]];
        firmwareUpdateTask.commitHash = [FDFirmwareUpdateTask dataWithHexString:intelHex.properties[@"hash"]];
        firmwareUpdateTask.commitCryptIv = [FDFirmwareUpdateTask dataWithHexString:intelHex.properties[@"cryptIV"]];
        firmwareUpdateTask.commitCryptHash = [FDFirmwareUpdateTask dataWithHexString:intelHex.properties[@"cryptHash"]];
    }
    
    return firmwareUpdateTask;
}

+ (FDFirmwareUpdateTask *)firmwareUpdateTask:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel resource:(NSString *)resource
{
    NSArray *versions = [FDFirmwareUpdateTask loadAllFirmwareVersions:resource];
    FDIntelHex *intelHex = versions[0];
    return [FDFirmwareUpdateTask firmwareUpdateTask:fireflyIce channel:channel intelHex:intelHex];
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
        _reset = YES;
        
        _area = FD_HAL_SYSTEM_AREA_APPLICATION;

        _commitFlags = 0;
        _commitCryptIv = [NSMutableData dataWithLength:16];
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
    
    _commitLength = (uint32_t)_firmware.length;
    _commitHash = [FDCrypto sha1:_firmware];
    _commitCryptHash = _commitHash;
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
    _updateVersion = version;
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel updateVersion:(FDFireflyIceUpdateVersion*)version
{
    _updateVersion = version.revision;
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
        return (_updateVersion.major != _major) || (_updateVersion.minor != _minor) || (_updateVersion.patch != _patch);
    }
    
    if (_updateVersion.major < _major) {
        return YES;
    }
    if (_updateVersion.major > _major) {
        return NO;
    }
    if (_updateVersion.minor < _minor) {
        return YES;
    }
    if (_updateVersion.minor > _minor) {
        return NO;
    }
    if (_updateVersion.patch < _patch) {
        return YES;
    }
    if (_updateVersion.patch > _patch) {
        return NO;
    }
    return NO;
}

- (void)checkOutOfDate
{
    BOOL isFirmwareUpToDate = ![self isOutOfDate];
    if ([_delegate respondsToSelector:@selector(firmwareUpdateTask:check:)]) {
        [_delegate firmwareUpdateTask:self check:isFirmwareUpToDate];
    }
    if (!isFirmwareUpToDate) {
        FDFireflyDeviceLogInfo(@"FD010401", @"firmware %@ is out of date with latest %u.%u.%u", _updateVersion, _major, _minor, _patch);
        [self next:@selector(getSectorHashes)];
    } else {
        FDFireflyDeviceLogInfo(@"FD010402", @"firmware %@ is up to date with latest %u.%u.%u", _updateVersion, _major, _minor, _patch);
        [self complete];
    }
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel lock:(FDFireflyIceLock *)lock
{
    _lock = lock;
}

- (void)checkLock
{
    if ((_lock.identifier == FDLockIdentifierUpdate) && [self.channel.name isEqualToString:_lock.ownerName]) {
        FDFireflyDeviceLogDebug(@"FD010403", @"acquired update lock");
        [self checkOutOfDate];
    } else {
        FDFireflyDeviceLogDebug(@"FD010404", @"update could not acquire lock");
        [self complete];
    }
}

- (void)checkVersion
{
    if (_useArea && (_version.capabilities & FD_CONTROL_CAPABILITY_UPDATE_AREA)) {
        [self.fireflyIce.coder sendUpdateGetVersion:self.channel area:_area];
        [self next:@selector(checkVersions)];
    } else {
        [self checkVersions];
    }
}

- (void)checkVersions
{
    if (_version.capabilities & FD_CONTROL_CAPABILITY_LOCK) {
        [self.fireflyIce.coder sendLock:self.channel identifier:FDLockIdentifierUpdate operation:FDLockOperationAcquire];
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
        if (_useArea) {
            [self.fireflyIce.coder sendUpdateEraseSectors:self.channel area:_area sectors:_updateSectors];
        } else {
            [self.fireflyIce.coder sendUpdateEraseSectors:self.channel sectors:_updateSectors];
        }
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
        if (_useArea) {
            [self.fireflyIce.coder sendUpdateGetSectorHashes:self.channel area:_area sectors:sectors];
        } else {
            [self.fireflyIce.coder sendUpdateGetSectorHashes:self.channel sectors:sectors];
        }
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
        NSData *hash = [FDCrypto sha1:[_firmware subdataWithRange:NSMakeRange(i * _sectorSize, _sectorSize)]];
        if (![hash isEqualToData:sectorHash.hashValue]) {
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
    
    FDFireflyDeviceLogInfo(@"FD010405", @"updating pages %@", _updatePages);
}

- (void)writeNextPage
{
    float progress = (_invalidPages.count - _updatePages.count) / (float)_invalidPages.count;
    if ([_delegate respondsToSelector:@selector(firmwareUpdateTask:progress:)]) {
        [_delegate firmwareUpdateTask:self progress:progress];
    }
    NSUInteger progressPercent = (NSUInteger)(progress * 100);
    if (_lastProgressPercent != progressPercent) {
        _lastProgressPercent = progressPercent;
        FDFireflyDeviceLogInfo(@"FD010406", @"firmware update progress %lu%%", (unsigned long) (unsigned long)progressPercent);
    }
    
    if (_updatePages.count == 0) {
        // noting left to write, check the hashes to confirm
        [self getSectorHashes];
    } else {
        uint16_t page = [_updatePages[0] unsignedShortValue];
        [_updatePages removeObjectAtIndex:0];
        NSInteger location = page * _pageSize;
        NSData *data = [_firmware subdataWithRange:NSMakeRange(location, _pageSize)];
        if (_useArea) {
            [self.fireflyIce.coder sendUpdateWritePage:self.channel area:_area page:page data:data];
        } else {
            [self.fireflyIce.coder sendUpdateWritePage:self.channel page:page data:data];
        }
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
    
    FDFireflyDeviceLogInfo(@"FD010407", @"sending update commit");
    if (_useArea) {
        [self.fireflyIce.coder sendUpdateCommit:self.channel area:_area flags:_commitFlags length:_commitLength hash:_commitHash cryptHash:_commitCryptHash cryptIv:_commitCryptIv major:_major minor:_minor patch:_patch capabilities:_capabilities commit:_gitCommit];
    } else {
        [self.fireflyIce.coder sendUpdateCommit:self.channel flags:_commitFlags length:_commitLength hash:_commitHash cryptHash:_commitCryptHash cryptIv:_commitCryptIv];
    }
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel updateCommit:(FDFireflyIceUpdateCommit *)updateCommit
{
    _updateCommit = updateCommit;
    [self complete];
}

- (void)complete
{
    if (_version.capabilities & FD_CONTROL_CAPABILITY_LOCK) {
        FDFireflyDeviceLogDebug(@"FD010408", @"released update lock");
        [self.fireflyIce.coder sendLock:self.channel identifier:FDLockIdentifierUpdate operation:FDLockOperationRelease];
    }
    
    BOOL isFirmwareUpToDate = (_updatePages.count == 0);
    BOOL success = isFirmwareUpToDate && (!_commit || ((_updateCommit != nil) && (_updateCommit.result == FD_UPDATE_COMMIT_SUCCESS)));
    FDFireflyDeviceLogInfo(@"FD010409", @"success = %@, isFirmwareUpToDate = %@, commit %@ result = %u", success ? @"YES" : @"NO", isFirmwareUpToDate ? @"YES" : @"NO", _updateCommit != nil ? @"YES" : @"NO", _updateCommit.result);
    if ([_delegate respondsToSelector:@selector(firmwareUpdateTask:complete:)]) {
        [_delegate firmwareUpdateTask:self complete:success];
    }
    if (_reset && [self isOutOfDate] && isFirmwareUpToDate && (_updateCommit != nil) && (_updateCommit.result == FD_UPDATE_COMMIT_SUCCESS)) {
        FDFireflyDeviceLogInfo(@"FD010410", @"new firmware has been transferred and comitted - restarting device");
        [self.fireflyIce.coder sendReset:self.channel type:FD_CONTROL_RESET_SYSTEM_REQUEST];
    }
    [self done];
}

@end
