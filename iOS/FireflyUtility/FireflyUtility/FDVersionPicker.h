//
//  FDVersionPicker.h
//  FireflyUtility
//
//  Created by Denis Bohm on 9/15/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FDVersionPicker : UIViewController

@property NSArray *items;
@property NSString *selectedItem;

@property (readonly) NSString *chosenItem;
@property (readonly) NSInteger chosenIndex;

@end
