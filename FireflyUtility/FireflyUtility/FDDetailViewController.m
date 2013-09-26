//
//  FDDetailViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/21/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetailViewController.h"

@interface FDDetailViewController ()

- (void)configureView;

@end

@implementation FDDetailViewController

- (void)configureView
{
}

- (void)setDevice:(FDDevice *)device
{
    if (_device != device) {
        [_device.fireflyIce.observable removeObserver:self];
        _device.collector.delegate = nil;
        
        _device = device;
        
        [_device.fireflyIce.observable addObserver:self];
        _device.collector.delegate = self;

        [self configureView];
    }
}

- (void)fireflyIceCollectorEntry:(FDFireflyIceCollectorEntry *)entry
{
}

@end
