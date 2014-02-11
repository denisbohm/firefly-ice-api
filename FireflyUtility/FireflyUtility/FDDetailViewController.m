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
    _controls = [NSMutableArray array];
}

- (void)configureButtons
{
    FDFireflyIce *fireflyIce = _device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    BOOL enabled = channel.status == FDFireflyIceChannelStatusOpen;
    for (UIButton *control in _controls) {
        [control setEnabled:enabled];
    }
}

- (void)configureView
{
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel status:(FDFireflyIceChannelStatus)status
{
    [self configureButtons];
}

- (void)setDevice:(NSMutableDictionary *)device
{
    if (_device != device) {
        FDFireflyIce *fireflyIce = _device[@"fireflyIce"];
        [fireflyIce.observable removeObserver:self];
        FDFireflyIceCollector *collector = _device[@"collector"];
        collector.delegate = nil;
        
        _device = device;
        
        fireflyIce = _device[@"fireflyIce"];
        [fireflyIce.observable addObserver:self];
        collector = _device[@"collector"];
        collector.delegate = self;

        [self configureButtons];
        [self configureView];
    }
}

- (void)fireflyIceCollectorEntry:(FDFireflyIceCollectorEntry *)entry
{
}

@end
