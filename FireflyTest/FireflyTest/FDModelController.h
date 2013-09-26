//
//  FDModelController.h
//  FireflyTest
//
//  Created by Denis Bohm on 9/18/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FDDataViewController;

@interface FDModelController : NSObject <UIPageViewControllerDataSource>

- (FDDataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard;
- (NSUInteger)indexOfViewController:(FDDataViewController *)viewController;

@end
