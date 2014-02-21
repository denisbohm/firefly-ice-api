//
//  FDDetailViewController.h
//  FireflyUtility
//
//  Created by Denis Bohm on 9/21/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <FireflyDevice/FDFireflyIce.h>

#import "FDFireflyIceCollector.h"

#import <UIKit/UIKit.h>

@class FDDetailViewController;

@protocol FDDetailViewControllerDelegate <NSObject>

- (void)detailViewControllerDidAppear:(FDDetailViewController *)detailViewController;
- (void)detailViewControllerDidDisappear:(FDDetailViewController *)detailViewController;

@end

@interface FDDetailViewController : UIViewController <FDFireflyIceObserver, FDFireflyIceCollectorDelegate>

@property NSMutableArray *controls;

@property id<FDDetailViewControllerDelegate> delegate;

@property(nonatomic) NSMutableDictionary *device;

- (void)configureView;

@property(readonly) NSString *helpText;

@end
