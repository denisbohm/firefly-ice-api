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
@property NSTimer *timer;

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

- (void)showHelpOverlay:(NSTimeInterval)duration
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
    
    CGRect barFrame = [[UIApplication sharedApplication] statusBarFrame];
    id rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController;
        if(!navigationController.navigationBarHidden) {
            barFrame.size.height += navigationController.navigationBar.frame.size.height;
        }
    }
    UIView *contentView = [_detailTabBarControllerDelegate detailTabBarControllerHelpView:self];
    [contentView setFrame:CGRectMake(0, barFrame.size.height, 320, 480 - barFrame.size.height)];
    
    [translucentView addSubview:button];
    [helpView addSubview:translucentView];
    [helpView addSubview:contentView];
    
    self.helpView = helpView;
    [self.view addSubview:helpView];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(hideHelpOverlay) userInfo:nil repeats:NO];
}

- (void)hideHelpOverlay
{
    [self.helpView removeFromSuperview];
    self.helpView = nil;
    
    [_timer invalidate];
    _timer = nil;
}

- (void)help:(id)sender
{
    if (self.helpView == nil) {
        [self showHelpOverlay:60];
    } else {
        [self hideHelpOverlay];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.detailTabBarControllerDelegate detailTabBarControllerDidAppear:self];
}

@end
