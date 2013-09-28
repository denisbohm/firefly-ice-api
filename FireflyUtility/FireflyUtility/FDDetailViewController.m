//
//  FDDetailViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/21/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetailViewController.h"

@interface FDDetailViewController ()

@end

@implementation FDDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _buttons = [NSMutableArray array];
}

- (void)configureButtons
{
    id<FDFireflyIceChannel> channel = _device.fireflyIce.channels[@"BLE"];
    BOOL enabled = channel.status == FDFireflyIceChannelStatusOpen;
    for (UIButton *button in _buttons) {
        [button setEnabled:enabled];
    }
}

- (void)configureView
{
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel status:(FDFireflyIceChannelStatus)status
{
    [self configureButtons];
}

- (void)setDevice:(FDDevice *)device
{
    if (_device != device) {
        [_device.fireflyIce.observable removeObserver:self];
        _device.collector.delegate = nil;
        
        _device = device;
        
        [_device.fireflyIce.observable addObserver:self];
        _device.collector.delegate = self;

        [self configureButtons];
        [self configureView];
    }
}

- (void)fireflyIceCollectorEntry:(FDFireflyIceCollectorEntry *)entry
{
}

@end
