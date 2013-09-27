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

@end

@implementation FDDetailResetViewController

- (NSString *)causeDescription:(uint32_t)cause
{
    if (cause & 1) {
        return @"Power On Reset";
    }
    if (cause & 2) {
        return @"Brown Out Detector Unregulated Domain Reset";
    }
    if (cause & 4) {
        return @"Brown Out Detector Regulated Domain Reset";
    }
    if (cause & 8) {
        return @"External Pin Reset";
    }
    if (cause & 16) {
        return @"Watchdog Reset";
    }
    if (cause & 32) {
        return @"LOCKUP Reset";
    }
    if (cause & 64) {
        return @"System Request Reset";
    }
    if (cause == 0) {
        return @"";
    }
    return [NSString stringWithFormat:@"0x%08x Reset", cause];
}

- (void)configureView
{
    FDFireflyIceReset *reset = [self.device.collector objectForKey:@"reset"];

    _causeLabel.text = [self causeDescription:reset.cause];

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
    
    FDFireflyIce *fireflyIce = self.device.fireflyIce;
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    
    [fireflyIce.coder sendReset:channel type:type];
}

@end
