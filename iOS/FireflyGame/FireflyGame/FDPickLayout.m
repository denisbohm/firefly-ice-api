//
//  FDPickLayout.m
//  FireflyGame
//
//  Created by Denis Bohm on 3/10/14.
//  Copyright (c) 2014 Firefly Design LLC. All rights reserved.
//

#import "FDPickLayout.h"

@implementation FDPickLayout

- (id)init:(CGSize)size cellSize:(CGSize)cellSize cellSpace:(CGSize)cellSpace
{
    if (self = [super init]) {
        _dx = cellSpace.width + cellSize.width;
        _dy = cellSpace.height + cellSize.height;
        NSInteger nx = (NSInteger)((size.width - cellSpace.width) / (cellSize.width + cellSpace.width));
        NSInteger ny = (NSInteger)((size.height - cellSpace.height) / (cellSize.height + cellSpace.height));
        _x = _ix = (size.width - (nx * (cellSize.width + cellSpace.width) + cellSpace.width)) / 2.0 + cellSpace.width + cellSize.width / 2.0;
        _y = _iy = (size.height - (ny * (cellSize.height + cellSpace.height) + cellSpace.height)) / 2.0 + cellSpace.height + cellSize.height / 2.0;
        _mx = _ix + (nx - 1) * (cellSize.width + cellSpace.width);
        _my = _iy + (ny - 1) * (cellSize.height + cellSpace.height);
    }
    return self;
}

- (CGPoint)nextPoint
{
    CGPoint point = CGPointMake(_x, _y);
    _x += _dx;
    if (_x > _mx) {
        _x = _ix;
        _y += _dy;
    }
    return point;
}

@end
