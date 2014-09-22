//
//  FDVersionPicker.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/15/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDVersionPicker.h"
#import "FDPickerModel.h"

@interface FDVersionPicker ()

@property IBOutlet UIPickerView *versionPicker;
@property FDPickerModel *versionModel;

@end

@implementation FDVersionPicker

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _versionModel = [[FDPickerModel alloc] init];
    _versionModel.items = self.items;
    _versionPicker.dataSource = _versionModel;
    _versionPicker.delegate = _versionModel;
    
    NSInteger row = [_versionModel.items indexOfObject:_selectedItem];
    if (row >= 0) {
        [_versionPicker selectRow:row inComponent:0 animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

/*
- (void)setItems:(NSArray *)items
{
    _versionModel.items = items;
    [_versionPicker reloadAllComponents];
}

- (NSArray *)items
{
    return _versionModel.items;
}

- (void)setSelectedItem:(NSString *)selectedItem
{
    NSInteger row = [_versionModel.items indexOfObject:selectedItem];
    if (row < 0) {
        return;
    }
    [_versionPicker selectRow:row inComponent:0 animated:YES];
}
*/

- (NSString *)chosenItem
{
    NSInteger row = [_versionPicker selectedRowInComponent:0];
    if (row < 0) {
        return nil;
    }
    return _versionModel.items[row];
}

- (NSInteger)chosenIndex
{
    return [_versionPicker selectedRowInComponent:0];
}

@end
