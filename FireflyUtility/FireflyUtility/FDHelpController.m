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
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [button addTarget:self action:@selector(help:) forControlEvents:UIControlEventTouchUpInside];
    return [[UIBarButtonItem alloc] initWithCustomView:button];
    /*
    return [[UIBarButtonItem alloc]
            initWithImage:[UIImage imageNamed:@"help"]
            style:UIBarButtonItemStylePlain
            target:self
            action:@selector(help:)];
     */
}

- (void)showHelpOverlay:(NSTimeInterval)delay completion:(void (^)(BOOL finished))completion
{
    if (_timer != nil) {
        return;
    }
    
    CGRect frame = self.viewController.view.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    if (
        [self.viewController respondsToSelector:@selector(edgesForExtendedLayout)] &&
        (self.viewController.edgesForExtendedLayout & UIRectEdgeTop)
    ) {
        CGFloat barHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
        id rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        if ([rootViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController *)rootViewController;
            if (!navigationController.navigationBarHidden) {
                barHeight += navigationController.navigationBar.frame.size.height;
            }
        }
        frame.size.height -= barHeight;
    }
    
    UIView *helpView = [[UIView alloc] initWithFrame:frame];
    
    UIView *translucentView = [[UIView alloc] initWithFrame:frame];
    [translucentView setBackgroundColor:[UIColor blackColor]];
    [translucentView setAlpha:0.8];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = frame;
    [button addTarget:self action:@selector(hideHelpOverlay) forControlEvents:UIControlEventTouchUpInside];
    
    UIView *contentView = [_delegate helpControllerHelpView:self];
    contentView.frame = CGRectMake(frame.origin.x + 20, frame.origin.y + 20, frame.size.width - 40, frame.size.height - 40);
    
    [translucentView addSubview:button];
    [helpView addSubview:translucentView];
    [helpView addSubview:contentView];
    
    self.helpView = helpView;
    helpView.alpha = 0.0;
    [self.viewController.view addSubview:helpView];
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
