//
//  FDDetailRadioViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 2/7/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDDetailRadioViewController.h"

#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceCoder.h>

@interface FDDetailRadioViewController ()

@property IBOutlet UISegmentedControl *txPowerLevel;

@property IBOutlet UIButton *setTxPowerButton;

@end

@implementation FDDetailRadioViewController

- (NSString *)helpText
{
    return
    @"The radio transmit strentgh can be reduced by up to -18 dBm."
    ;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.controls addObject:_setTxPowerButton];
}

- (void)configureView
{
    FDFireflyIceCollector *collector = self.device[@"collector"];
    
    NSNumber *txPower = [collector objectForKey:@"txPower"];
    if (txPower != nil) {
        uint8_t level = [txPower unsignedCharValue];
        [_txPowerLevel setSelectedSegmentIndex:level];
    }
}

- (IBAction)setTxPower:(id)sender
{
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    
    uint8_t level = _txPowerLevel.selectedSegmentIndex;
    [fireflyIce.coder sendSetPropertyTxPower:channel level:level];
}

@end
