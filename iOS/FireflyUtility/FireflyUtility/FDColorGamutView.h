//
//  FDColorGamutView.h
//  FireflyUtility
//
//  Created by Denis Bohm on 2/7/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDColorUtilities.h"

@interface FDColorGamutView : UIImageView

@property(nonatomic) FDRange saturationRange;
@property(nonatomic) FDRange brightnessRange;

@property(nonatomic) CGFloat hue;

@end
