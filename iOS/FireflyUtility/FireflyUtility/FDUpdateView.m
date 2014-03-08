//
//  FDUpdateView.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/23/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDUpdateView.h"

typedef enum {Unused, UpToDate, OutOfDate} FDUpdateState;

@implementation FDUpdateView

- (void)updateViewInit
{
    
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self updateViewInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
        [self updateViewInit];
    }
    return self;
}

- (void)draw:(CGContextRef)context sectors:(NSSet *)sectors
{
    for (NSNumber *sectorNumber in sectors) {
        NSUInteger sector = sectorNumber.unsignedShortValue;
        CGContextFillRect(context, CGRectMake(0, sector * 4, 16, 4));
    }
}

- (void)draw:(CGContextRef)context pages:(NSSet *)pages
{
    for (NSNumber *pageNumber in pages) {
        NSUInteger page = pageNumber.unsignedShortValue;
        NSUInteger sector = page / _firmwareUpdateTask.pagesPerSector;
        NSUInteger pageInSector = page - sector * _firmwareUpdateTask.pagesPerSector;
        CGContextFillRect(context, CGRectMake(24 + pageInSector * 16, sector * 4, 16, 4));
    }
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (_firmwareUpdateTask == nil) {
        return;
    }
    
    NSSet *usedSectors = [NSSet setWithArray:_firmwareUpdateTask.usedSectors];
    NSSet *updateSectors = [NSSet setWithArray:_firmwareUpdateTask.updateSectors];
    NSMutableSet *upToDateSectors = [NSMutableSet setWithSet:usedSectors];
    [upToDateSectors minusSet:updateSectors];

    NSMutableSet *usedPages = [NSMutableSet set];
    for (NSNumber *sectorNumber in usedSectors) {
        NSUInteger sectorPage = sectorNumber.unsignedShortValue * _firmwareUpdateTask.pagesPerSector;
        for (NSUInteger i = 0; i < _firmwareUpdateTask.pagesPerSector; ++i) {
            NSUInteger page = sectorPage + i;
            [usedPages addObject:[NSNumber numberWithUnsignedShort:page]];
        }
    }
    NSSet *updatePages = [NSSet setWithArray:_firmwareUpdateTask.updatePages];
    NSMutableSet *upToDatePages = [NSMutableSet setWithSet:usedPages];
    [upToDatePages minusSet:updatePages];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, 0.0, 1.0, 0.0, 1.0);
    [self draw:context sectors:upToDateSectors];
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
    [self draw:context sectors:updateSectors];
    CGContextSetRGBFillColor(context, 0.0, 1.0, 0.0, 1.0);
    [self draw:context pages:upToDatePages];
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
    [self draw:context pages:updatePages];
}

@end
