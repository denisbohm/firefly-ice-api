//
//  FDDetailTabBarController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/24/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetailTabBarController.h"
#import "FDDetailViewController.h"
#import "FDFireflyIceCollector.h"
#import "FDHelpController.h"

#import <FireflyDevice/FDFireflyIce.h>

@interface FDDetailTabBarController () <FDHelpControllerDelegate, FDDetailViewControllerDelegate, FDFireflyIceObserver>

@property IBOutlet UIButton *connectButton;

@property FDHelpController *helpController;

@property FDDetailViewController *currentDetailViewController;

@end

@implementation FDDetailTabBarController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UIBarButtonItem *connect = self.navigationItem.rightBarButtonItem;
    UIButton *connectButton = (UIButton *)connect.customView;
    [connectButton addTarget:self action:@selector(connect:) forControlEvents:UIControlEventTouchUpInside];
    [self configureConnectButton];
    
    _helpController = [[FDHelpController alloc] init];
    _helpController.delegate = self;
    _helpController.viewController = self;
    UIBarButtonItem *helpButtonItem = [_helpController makeBarButtonItem];
    self.navigationItem.rightBarButtonItems = @[helpButtonItem, self.navigationItem.rightBarButtonItem];
    
    [self.moreNavigationController.navigationBar setHidden:YES];

    for (UIViewController *viewController in self.viewControllers) {
        if ([viewController isKindOfClass:[FDDetailViewController class]]) {
            FDDetailViewController *detailViewController = (FDDetailViewController *)viewController;
            detailViewController.delegate = self;
        }
    }
}

- (IBAction)connect:(id)sender
{
    id<FDFireflyIceChannel> channel = self.device[@"channel"];
    if (channel.status == FDFireflyIceChannelStatusClosed) {
        [channel open];
    } else {
        [channel close];
    }
}

- (void)configureConnectButton
{
    NSString *title = @"Connect";
    id<FDFireflyIceChannel> channel = self.device[@"channel"];
    switch (channel.status) {
        case FDFireflyIceChannelStatusClosed:
            title = @"Connect";
            break;
        case FDFireflyIceChannelStatusOpening:
            title = @"Cancel";
            break;
        case FDFireflyIceChannelStatusOpen:
            title = @"Disconnect";
            break;
    }
    [_connectButton setTitle:title forState:UIControlStateNormal];
    [_connectButton setEnabled:channel != nil];
}

- (void)configure
{
    [self configureConnectButton];
    
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = self.device[@"channel"];
    if (channel.status == FDFireflyIceChannelStatusOpen) {
        FDFireflyIceCollector *collector = _device[@"collector"];
        [fireflyIce.executor execute:collector];
    }
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel status:(FDFireflyIceChannelStatus)status
{
    [self configure];
}

- (void)setDevice:(NSMutableDictionary *)device
{
    if (_device != device) {
        FDFireflyIce *fireflyIce = _device[@"fireflyIce"];
        [fireflyIce.observable removeObserver:self];
        
        _device = device;
        fireflyIce = _device[@"fireflyIce"];
        [fireflyIce.observable addObserver:self];
        
        [self configure];
    }
}

- (UIView *)helpControllerHelpView:(FDHelpController *)helpController
{
    UILabel *textView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    textView.backgroundColor = UIColor.clearColor;
    [textView setLineBreakMode:NSLineBreakByWordWrapping];
    textView.textColor = [UIColor whiteColor];
    
    NSMutableString *text = [NSMutableString string];
    if (_currentDetailViewController != nil) {
        [text appendString:[_currentDetailViewController helpText]];
    }
    [text appendString:@"\n\nTouch the information button at the top right to hide or show this message."];
    textView.text = text;
    
    textView.numberOfLines = 0;
    [textView sizeToFit];
    return textView;
}

- (void)detailViewControllerDidAppear:(FDDetailViewController *)detailViewController
{
    _currentDetailViewController = detailViewController;
    
    detailViewController.device = _device;
    [detailViewController configureView];
    NSString *className = NSStringFromClass([detailViewController class]);
    [_helpController autoShowHelp:className];
    
    [self configure];
}

- (void)detailViewControllerDidDisappear:(FDDetailViewController *)detailViewController
{
    _currentDetailViewController.device = nil;
    
    _currentDetailViewController = nil;
}

@end
