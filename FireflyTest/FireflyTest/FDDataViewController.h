//
//  FDDataViewController.h
//  FireflyTest
//
//  Created by Denis Bohm on 9/18/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FDDataViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *dataLabel;
@property (strong, nonatomic) id dataObject;

@property IBOutlet UITableView

@end
