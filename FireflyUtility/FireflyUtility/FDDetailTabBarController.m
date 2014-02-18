//
//  FDDetailTabBarController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/24/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetailTabBarController.h"

@interface FDDetailTabBarController ()

@property UIView *helpView;

@end

@implementation FDDetailTabBarController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UIBarButtonItem *helpButtonItem = [[UIBarButtonItem alloc]
                                       initWithTitle:@"?"
                                       style:UIBarButtonItemStylePlain
                                       target:self
                                       action:@selector(help:)];
    self.navigationItem.rightBarButtonItems = @[helpButtonItem, self.navigationItem.rightBarButtonItem];
    
    [self.moreNavigationController.navigationBar setHidden:YES];
}

- (void)showHelpOverlay
{
    if (self.helpView != nil) {
        return;
    }
    
    UIView *helpView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    
    UIView *translucentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    [translucentView setBackgroundColor:[UIColor blackColor]];
    [translucentView setAlpha:0.8];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = helpView.frame;
    [button addTarget:self action:@selector(hideHelpOverlay) forControlEvents:UIControlEventTouchUpInside];
    
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    
    UIView *contentView = [_detailTabBarControllerDelegate detailTabBarControllerHelpView:self];
    [contentView setFrame:CGRectMake(0, (-1) * statusBarFrame.size.height, 320, 480)];
    
    [translucentView addSubview:button];
    [helpView addSubview:translucentView];
    [helpView addSubview:contentView];
    
    self.helpView = helpView;
    [self.view addSubview:helpView];
}

- (void)hideHelpOverlay
{
    [self.helpView removeFromSuperview];
    self.helpView = nil;
}

- (void)help:(id)sender
{
    [self showHelpOverlay];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.detailTabBarControllerDelegate detailTabBarControllerDidAppear:self];
}

@end
