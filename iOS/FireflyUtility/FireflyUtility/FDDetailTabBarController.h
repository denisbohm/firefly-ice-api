//
//  FDDetailTabBarController.h
//  FireflyUtility
//
//  Created by Denis Bohm on 9/24/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FDHelpController.h"

#import <FireflyDevice/FDFireflyIceManager.h>

@interface FDDetailTabBarController : UITabBarController

@property FDFireflyIceManager *fireflyIceManager;
@property(nonatomic) NSMutableDictionary *device;

@end
