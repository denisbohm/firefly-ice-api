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

@property IBOutlet UILabel *lastResetLabel;

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
    return [NSString stringWithFormat:@"0x%08x", cause];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel reset:(FDFireflyIceReset *)reset
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSString *date = [dateFormatter stringFromDate:reset.date];
    _lastResetLabel.text = [NSString stringWithFormat:@"%@ %@", date, [self causeDescription:reset.cause]];
}

- (IBAction)resetDevice:(id)sender
{
    uint8_t type = _typeSegmentedControl.selectedSegmentIndex + 1;
    
    FDFireflyIce *fireflyIce = self.device.fireflyIce;
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    
    [fireflyIce.coder sendReset:channel type:type];
}

@end
