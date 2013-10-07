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

#import <CommonCrypto/CommonDigest.h>

@interface FDFirmwareUpdateTask () <FDFireflyIceObserver>

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

+ (FDFirmwareUpdateTask *)firmwareUpdateTask:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel
{
    FDFirmwareUpdateTask *firmwareUpdateTask = [[FDFirmwareUpdateTask alloc] init];
    firmwareUpdateTask.fireflyIce = fireflyIce;
    firmwareUpdateTask.channel = channel;
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:@"FireflyIce" ofType:@"hex"];
    NSString *firmware = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [firmwareUpdateTask parseFirmware:firmware];
    return firmwareUpdateTask;
}

- (id)init
{
    if (self = [super init]) {
        self.priority = -100;
        _pageSize = 256;
        _sectorSize = 4096;
        _pagesPerSector = _sectorSize / _pageSize;
    }
    return self;
}

- (void)parseFirmware:(NSString *)intelHex
{
    NSMutableData *data = [NSMutableData dataWithData:[FDIntelHex parse:intelHex address:0x08000 length:0x40000 - 0x08000]];
    // pad to sector multiple of sector size
    NSUInteger length = data.length;
    length = ((length + _sectorSize - 1) / _sectorSize) * _sectorSize;
    data.length = length;
    _firmware = data;
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

- (void)begin
{
    _updateSectors = nil;
    _updatePages = nil;
    
    [self getSectorHashes];
}

- (void)firstSectorHashesCheck
{
    [self checkSectorHashes];
    _invalidSectors = [NSArray arrayWithArray:_updateSectors];
    _invalidPages = [NSArray arrayWithArray:_updatePages];
    
    if (_updateSectors.count == 0) {
        [self commit];
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
    NSLog(@"fireflyIceSectorHashes %@", sectorHashes);
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
        NSLog(@"nothing to update");
        return;
    }
    
    NSLog(@"updating pages %@", _updatePages);
}

- (void)writeNextPage
{
    float progress = (_invalidPages.count - _updatePages.count) / (float)_invalidPages.count;
    [_delegate firmwareUpdateTask:self progress:progress];
    NSUInteger progressPercent = (NSUInteger)(progress * 100);
    if (_lastProgressPercent != progressPercent) {
        _lastProgressPercent = progressPercent;
        NSLog(@"firmware update progress %lu%%", (unsigned long) (unsigned long)progressPercent);
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
        [self commit];
    } else {
        [self complete];
    }
}

- (void)commit
{
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
    BOOL isFirmwareUpToDate = (_updatePages.count == 0);
    NSLog(@"isFirmwareUpToDate = %@, commit result = %u", isFirmwareUpToDate ? @"YES" : @"NO", _updateCommit.result);
    [_delegate firmwareUpdateTask:self complete:isFirmwareUpToDate];
    [self done];
}

@end
