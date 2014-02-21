//
//  FDHelpController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 2/19/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDHelpController.h"

@interface FDHelpController ()

@property NSTimeInterval duration;
@property UIView *helpView;
@property NSTimer *timer;

@end

@implementation FDHelpController

- (id)init
{
    if (self = [super init]) {
        _duration = 30.0;
    }
    return self;
}

- (UIBarButtonItem *)makeBarButtonItem
{
    return [[UIBarButtonItem alloc]
            initWithImage:[UIImage imageNamed:@"help"]
            style:UIBarButtonItemStylePlain
            target:self
            action:@selector(help:)];
}

- (void)showHelpOverlay:(NSTimeInterval)delay completion:(void (^)(BOOL finished))completion
{
    if (_timer != nil) {
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
        if (!navigationController.navigationBarHidden) {
            barFrame.size.height += navigationController.navigationBar.frame.size.height;
        }
    }
    UIView *contentView = [_delegate helpControllerHelpView:self];
    [contentView setFrame:CGRectMake(0, barFrame.size.height, 320, 480 - barFrame.size.height)];
    
    [translucentView addSubview:button];
    [helpView addSubview:translucentView];
    [helpView addSubview:contentView];
    
    self.helpView = helpView;
    helpView.alpha = 0.0;
    [self.parentView addSubview:helpView];
    [UIView animateWithDuration:0.5
                          delay:delay
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                     animations:^{
                         helpView.alpha = 1.0;
                     }
                     completion:completion];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:_duration target:self selector:@selector(hideHelpOverlay) userInfo:nil repeats:NO];
}

- (void)showHelpOverlay
{
    [self showHelpOverlay:0.0 completion:nil];
}

- (void)hideHelpOverlay
{
    if (_timer == nil) {
        return;
    }
    __weak FDHelpController *weakSelf = self;
    [UIView animateWithDuration:0.5
                     animations:^{weakSelf.helpView.alpha = 0.0;}
                     completion:^(BOOL finished){[weakSelf.helpView removeFromSuperview]; weakSelf.helpView = nil;}];
    
    [_timer invalidate];
    _timer = nil;
}

- (void)toggleHelpOverlay
{
    if (self.helpView == nil) {
        [self showHelpOverlay];
    } else {
        [self hideHelpOverlay];
    }
}

- (void)autoShowHelp:(NSString *)name
{
    NSString *key = [NSString stringWithFormat:@"hasShownHelpFor%@", name];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults boolForKey:key]) {
        [self showHelpOverlay:0.5 completion:^(BOOL finished){[userDefaults setBool:YES forKey:key];}];
    }
}


- (void)help:(id)sender
{
    [self toggleHelpOverlay];
}

@end
