//
//  FDColorGamutControl.h
//  FireflyUtility
//
//  Created by Denis Bohm on 2/8/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDColorUtilities.h"

@interface FDColorGamutControl : UIControl

@property(nonatomic) FDRange saturationRange;
@property(nonatomic) FDRange brightnessRange;

@property(nonatomic) CGFloat hue;
@property(nonatomic) CGFloat saturation;
@property(nonatomic) CGFloat brightness;

@property(nonatomic) UIColor *value;

@end
