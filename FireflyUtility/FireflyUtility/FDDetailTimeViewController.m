//
//  FDDetailTimeViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 2/9/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDDetailTimeViewController.h"

#import <FireflyDevice/FDFireflyIceCoder.h>

@interface FDDetailTimeViewController ()

@property IBOutlet UILabel *timeLabel;

@property IBOutlet UIButton *setTimeButton;

@end

@implementation FDDetailTimeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.controls addObject:_setTimeButton];
}

#define JAN_1_2014 1388534400

- (void)configureView
{
    FDFireflyIceCollector *collector = self.device[@"collector"];
    
    FDFireflyIceCollectorEntry *entry = collector.dictionary[@"time"];
    NSDate *time = entry.object;
    if ([time timeIntervalSince1970] < JAN_1_2014) {
        _timeLabel.text = @"Time is not set.";
    } else {
        NSTimeInterval offset = [time timeIntervalSinceDate:entry.date];
        if (offset < 0) {
            _timeLabel.text = [NSString stringWithFormat:@"Time is behind by %0.2f seconds.", offset];
        } else {
            _timeLabel.text = [NSString stringWithFormat:@"Time is ahead by %0.2f seconds.", -offset];
        }
    }
}

- (void)fireflyIceCollectorEntry:(FDFireflyIceCollectorEntry *)entry
{
    [self configureView];
}

- (IBAction)setTime:(id)sender
{
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    [fireflyIce.coder sendSetPropertyTime:channel time:[NSDate date]];
}

@end
