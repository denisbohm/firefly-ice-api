//
//  FDDetailTabBarController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/24/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetailTabBarController.h"

@implementation FDDetailTabBarController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _helpController = [[FDHelpController alloc] init];
    _helpController.viewController = self;
    UIBarButtonItem *helpButtonItem = [_helpController makeBarButtonItem];
    self.navigationItem.rightBarButtonItems = @[helpButtonItem, self.navigationItem.rightBarButtonItem];
    
    [self.moreNavigationController.navigationBar setHidden:YES];
}

@end
