//
//  FDDetailViewController.h
//  FireflyUtility
//
//  Created by Denis Bohm on 9/21/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDevice.h"

#import <UIKit/UIKit.h>

@interface FDDetailViewController : UIViewController <FDFireflyIceObserver, FDFireflyIceCollectorDelegate>

@property(nonatomic) FDDevice *device;

@end
