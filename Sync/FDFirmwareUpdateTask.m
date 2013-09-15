//
//  FDFirmwareUpdateTask.m
//  Sync
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIce.h"
#import "FDFireflyIceCoder.h"
#import "FDFireflyIceChannel.h"
#import "FDFirmwareUpdateTask.h"

#import <FireflyProduction/FDBinary.h>
#import <FireflyProduction/FDExecutable.h>

#import <CommonCrypto/CommonDigest.h>

@interface FDFirmwareUpdateTask () <FDFireflyIceObserver>

@property uint32_t sectorSize;
@property uint32_t pageSize;
@property uint32_t pagesPerSector;
@property FDExecutableSection *section;
@property NSArray *sectorHashes;
@property NSMutableArray *updateSectors;
@property NSMutableArray *updatePages;

@end

@implementation FDFirmwareUpdateTask

- (id)init
{
    if (self = [super init]) {
        _pageSize = 256;
        _sectorSize = 2048;
        _pagesPerSector = _sectorSize / _pageSize;
    }
    return self;
}

- (void)taskStarted
{
    [super taskStarted];
    
    NSArray *sections = [_executable combineAllSectionsType:FDExecutableSectionTypeProgram address:0x00000000 length:0x40000 pageSize:_sectorSize];
    _section = sections[0];
    
    [self begin];
}

- (void)taskResumed
{
    [super taskResumed];
    
    [self begin];
}

- (void)begin
{
    _sectorHashes = nil;
    _updateSectors = nil;
    _updatePages = nil;
    
    [self getSectorHashes];
    [self next:@selector(firstSectorHashesCheck)];
}

- (void)firstSectorHashesCheck
{
    [self checkSectorHashes];
    if (_updateSectors.count == 0) {
        [self commit];
    } else {
        [self.firefly.coder sendUpdateEraseSectors:self.channel sectors:_updateSectors];
        [self next:@selector(writeNextPage)];
    }
}

- (void)getSectorHashes
{
    uint16_t sector = (uint16_t)(_section.address / _sectorSize);
    uint16_t sectorCount = (uint16_t)(_section.data.length / _sectorSize);
    NSMutableArray *sectors = [NSMutableArray array];
    for (uint16_t i = 0; i < sectorCount; ++i) {
        [sectors addObject:[NSNumber numberWithUnsignedShort:sector + i]];
    }

    [self.firefly.coder sendUpdateGetSectorHashes:self.channel sectors:sectors];
}

- (void)fireflyIceSectorHashes:(id<FDFireflyIceChannel>)channel sectorHashes:(NSArray *)sectorHashes
{
    _sectorHashes = sectorHashes;
}

- (NSData *)sha1:(NSData *)data
{
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    return [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
}

- (void)checkSectorHashes
{
    _updateSectors = nil;
    _updatePages = nil;
    
    NSMutableArray *updateSectors = [NSMutableArray array];
    NSMutableArray *updatePages = [NSMutableArray array];
    uint16_t firstSector = (uint16_t)(_section.address / _sectorSize);
    uint16_t sectorCount = (uint16_t)(_section.data.length / _sectorSize);
    for (uint16_t i = 0; i < sectorCount; ++i) {
        uint16_t sector = firstSector + i;
        FDFireflyIceSectorHash *sectorHash = _sectorHashes[i];
        if (sectorHash.sector != sector) {
            @throw [NSException exceptionWithName:@"unexpected" reason:@"unexpected" userInfo:nil];
        }
        NSData * hash = [self sha1:[_section.data subdataWithRange:NSMakeRange(i * _sectorSize, _sectorSize)]];
        if (![hash isEqualToData:sectorHash.hash]) {
            [updateSectors addObject:[NSNumber numberWithUnsignedShort:sectorHash.sector]];
            uint16_t page = sector * _pagesPerSector;
            for (uint16_t i = 0; i < _pagesPerSector; ++i) {
                [updatePages addObject:[NSNumber numberWithUnsignedShort:page + i]];
            }
        }
    }
    
    if (updateSectors.count == 0) {
        // nothing to update
        return;
    }
    
    _updateSectors = updateSectors;
    _updatePages = updatePages;
}

- (void)writeNextPage
{
    if (_updatePages.count == 0) {
        // noting left to write, check the hashes to confirm
        _sectorHashes = nil;
        [self getSectorHashes];
        [self next:@selector(verify)];
    } else {
        uint16_t page = [_updatePages[0] unsignedShortValue];
        [_updatePages removeObjectAtIndex:0];
        NSInteger location = page * _pageSize - _section.address;
        NSData *data = [_section.data subdataWithRange:NSMakeRange(location, _pageSize)];
        [self.firefly.coder sendUpdateWritePage:self.channel page:page data:data];
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
    uint32_t length = (uint32_t)_section.data.length;
    NSData *hash = [self sha1:_section.data];
    NSMutableData *cryptHash = [NSMutableData data];
    cryptHash.length = 20;
    NSMutableData *cryptIv = [NSMutableData data];
    cryptIv.length = 16;
    [self.firefly.coder sendUpdateCommit:self.channel flags:flags length:length hash:hash cryptHash:cryptHash cryptIv:cryptIv];
    [self next:@selector(complete)];
}

- (void)complete
{
    BOOL isFirmwareUpToDate = (_updatePages.count == 0);
    [_delegate firmwareUpdateTaskComplete:isFirmwareUpToDate];
    [self done];
}

@end
