//
//  FDColorSpectrumControl.h
//  FireflyUtility
//
//  Created by Denis Bohm on 2/7/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDColorUtilities.h"

@interface FDColorSpectrumControl : UIControl

@property(nonatomic) FDRange hueRange;

@property(nonatomic) CGFloat hue;

@property(nonatomic) CGFloat value;

@end
