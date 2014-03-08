//
//  FDColorPickerViewController.h
//  FireflyUtility
//
//  Created by Denis Bohm on 2/7/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDColorUtilities.h"

/*
 Example Usage:
 
 FDColorPickerViewController *picker = [FDColorPickerViewController colorPickerViewController];
 
 __weak id *weakSelf = self;
 picker.doneBlock = ^(UIColor *color) {
     [self dismissViewControllerAnimated:YES completion:nil];
     [weakSelf doSomethingWithColorPicked:color];
 };
 
 picker.color = someInitialColor;
 
 [self presentViewController:[[UINavigationController alloc] initWithRootViewController:picker] animated:YES completion:nil];
*/

@interface FDColorPickerViewController : UIViewController

+ (FDColorPickerViewController *)colorPickerViewController;

@property(copy) void (^doneBlock)(UIColor *color);

@property(nonatomic) FDRange hueRange;
@property(nonatomic) FDRange saturationRange;
@property(nonatomic) FDRange brightnessRange;

@property(nonatomic) UIColor *color;

@end
