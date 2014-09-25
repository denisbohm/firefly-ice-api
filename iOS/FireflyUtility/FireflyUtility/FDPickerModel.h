//
//  FDPickerModel.h
//  FireflyUtility
//
//  Created by Denis Bohm on 9/15/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FDPickerModel : NSObject <UIPickerViewDataSource, UIPickerViewDelegate>

@property NSArray *items;

@end
