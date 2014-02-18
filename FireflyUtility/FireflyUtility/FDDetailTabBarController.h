//
//  FDDetailTabBarController.h
//  FireflyUtility
//
//  Created by Denis Bohm on 9/24/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FDDetailTabBarController;

@protocol FDDetailTabBarControllerDelegate <NSObject>

- (void)detailTabBarControllerDidAppear:(FDDetailTabBarController *)detailTabBarController;
- (UIView *)detailTabBarControllerHelpView:(FDDetailTabBarController *)detailTabBarController;

@end

@interface FDDetailTabBarController : UITabBarController

@property id<FDDetailTabBarControllerDelegate> detailTabBarControllerDelegate;

@end
