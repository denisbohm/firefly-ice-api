//
//  FDPickerModel.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/15/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDPickerModel.h"

@interface FDPickerModel () <UIPickerViewDataSource, UIPickerViewDelegate>
@end

@implementation FDPickerModel

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return _items.count;
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return _items[row];
}

@end
