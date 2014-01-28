//
//  FDDetailOverviewViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/23/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetailOverviewViewController.h"

#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceCoder.h>

@interface FDDetailOverviewViewController ()

@property IBOutlet UILabel *hardwareIdLabel;
@property IBOutlet UILabel *hardwareRevisionLabel;
@property IBOutlet UILabel *bootRevisionLabel;
@property IBOutlet UILabel *firmwareRevisionLabel;
@property IBOutlet UILabel *vendorAndProductLabel;
@property IBOutlet UILabel *debugLockLabel;

@property IBOutlet UILabel *timeLabel;

@property IBOutlet UIButton *setTimeButton;
@property IBOutlet UIButton *updateButton;

@end

@implementation FDDetailOverviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.buttons addObject:_setTimeButton];
    [self.buttons addObject:_updateButton];
}

- (NSString *)toHex:(NSData *)data
{
    NSMutableString *string = [NSMutableString string];
    uint8_t *bytes = (uint8_t *)data.bytes;
    for (NSInteger i = 0; i < data.length; ++i) {
        uint8_t byte = bytes[i];
        [string appendFormat:@"%02x", byte];
    }
    return string;
}

#define JAN_1_2014 1388534400

- (void)configureView
{
    FDFireflyIceCollector *collector = self.device[@"collector"];
    
    FDFireflyIceVersion *version = [collector objectForKey:@"version"];
    FDFireflyIceVersion *bootVersion = [collector objectForKey:@"bootVersion"];
    FDFireflyIceHardwareId *hardwareId = [collector objectForKey:@"hardwareId"];
    
    _hardwareRevisionLabel.text = [NSString stringWithFormat:@"Hardware v%d.%d", hardwareId.major, hardwareId.minor];
    _vendorAndProductLabel.text = [NSString stringWithFormat:@"USB VID %04x / PID %04x", hardwareId.vendor, hardwareId.product];
    _hardwareIdLabel.text = [NSString stringWithFormat:@"UUID %@", [self toHex:hardwareId.unique]];
    
    _bootRevisionLabel.text = [NSString stringWithFormat:@"Boot Loader v%d.%d.%d", bootVersion.major, bootVersion.minor, bootVersion.patch];
    
    _firmwareRevisionLabel.text = [NSString stringWithFormat:@"Firmware v%d.%d.%d", version.major, version.minor, version.patch];
    
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
    
    NSNumber *debugLock = [collector objectForKey:@"debugLock"];
    _debugLockLabel.text = debugLock.boolValue ? @"Debug Lock Set" : @"Debug is Unlocked";
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

- (IBAction)updateOverview:(id)sender
{
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    FDFireflyIceCollector *collector = self.device[@"collector"];
    [fireflyIce.executor execute:collector];
}

@end
