//
//  FDPickLayout.h
//  FireflyGame
//
//  Created by Denis Bohm on 3/10/14.
//  Copyright (c) 2014 Firefly Design LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDPickLayout : NSObject

- (id)init:(CGSize)size cellSize:(CGSize)cellSize cellSpace:(CGSize)cellSpace;

@property CGFloat ix;
@property CGFloat iy;
@property CGFloat dx;
@property CGFloat dy;
@property CGFloat mx;
@property CGFloat my;
@property CGFloat x;
@property CGFloat y;

- (CGPoint)nextPoint;

@end
