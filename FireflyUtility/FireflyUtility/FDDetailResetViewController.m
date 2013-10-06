//
//  FDDetailResetViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/23/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetailResetViewController.h"

#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceCoder.h>

@interface FDDetailResetViewController ()

@property IBOutlet UILabel *causeLabel;
@property IBOutlet UILabel *dateLabel;

@property IBOutlet UISegmentedControl *typeSegmentedControl;

@property IBOutlet UIButton *resetButton;
@property IBOutlet UIButton *modeButton;

@end

@implementation FDDetailResetViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.buttons addObject:_resetButton];
    [self.buttons addObject:_modeButton];
}

- (void)configureView
{
    FDFireflyIceCollector *collector = self.device[@"collector"];
    FDFireflyIceReset *reset = [collector objectForKey:@"reset"];

    NSLog(@"reset cause %08x", reset.cause);
    _causeLabel.text = [reset description];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    _dateLabel.text = [dateFormatter stringFromDate:reset.date];
}

- (void)fireflyIceCollectorEntry:(FDFireflyIceCollectorEntry *)entry
{
    [self configureView];
}

- (IBAction)resetDevice:(id)sender
{
    uint8_t type = _typeSegmentedControl.selectedSegmentIndex + 1;
    
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    
    [fireflyIce.coder sendReset:channel type:type];
}

- (IBAction)enterStorageMode:(id)sender
{
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    
    [fireflyIce.coder sendSetPropertyMode:channel mode:FD_CONTROL_MODE_STORAGE];
}

@end
