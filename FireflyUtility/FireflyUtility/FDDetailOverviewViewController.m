//
//  FDDetailOverviewViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/23/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetailOverviewViewController.h"

#import <FireflyDevice/FDFireflyIce.h>

@interface FDDetailOverviewViewController ()

@property IBOutlet UILabel *revisionLabel;
@property IBOutlet UILabel *productLabel;
@property IBOutlet UILabel *debugLockLabel;
@property IBOutlet UILabel *siteLabel;
@property IBOutlet UILabel *batteryLabel;
@property IBOutlet UILabel *timeLabel;
@property IBOutlet UILabel *accelerometerLabel;
@property IBOutlet UILabel *magnetometerLabel;
@property IBOutlet UILabel *temperatureLabel;
@property IBOutlet UILabel *dataLabel;

@property IBOutlet UIButton *updateButton;

@end

@implementation FDDetailOverviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
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

- (void)configureView
{
    FDFireflyIceCollector *collector = self.device.collector;
    
    FDFireflyIceVersion *version = [collector objectForKey:@"version"];
    FDFireflyIceHardwareId *hardwareId = [collector objectForKey:@"hardwareId"];
    _revisionLabel.text = [NSString stringWithFormat:@"sw %d.%d.%d hw %d.%d %04x/%04x",
                           version.major, version.minor, version.patch,
                           hardwareId.major, hardwareId.minor,
                           hardwareId.vendor, hardwareId.product];
    
    _productLabel.text = [self toHex:hardwareId.unique];
    
    FDFireflyIceStorage *storage = [collector objectForKey:@"storage"];
    _dataLabel.text = [NSString stringWithFormat:@"%u pages of data", storage.pageCount];

    FDFireflyIceSensing *sensing = [collector objectForKey:@"sensing"];
    _accelerometerLabel.text = [NSString stringWithFormat:@"%0.2f, %0.2f, %0.2f g", sensing.ax, sensing.ay, sensing.az];
    _magnetometerLabel.text = [NSString stringWithFormat:@"%0.2f, %0.2f, %0.2f uT", sensing.mx, sensing.my, sensing.mz];

    FDFireflyIceCollectorEntry *entry = collector.dictionary[@"time"];
    NSDate *time = entry.object;
    NSTimeInterval offset = [time timeIntervalSinceDate:entry.date];
    if (offset < 0) {
        _timeLabel.text = [NSString stringWithFormat:@"time is behind by %0.2f seconds", offset];
    } else {
        _timeLabel.text = [NSString stringWithFormat:@"time is ahead by %0.2f seconds", -offset];
    }

    FDFireflyIcePower *power = [collector objectForKey:@"power"];
    NSMutableString *text = [NSMutableString stringWithFormat:@"battery %0.1f%% %0.1fV", power.batteryLevel, power.batteryVoltage];
    if (power.isUSBPowered) {
        [text appendString:@" USB"];
        if (power.isCharging) {
            [text appendFormat:@" %0.1fmA", power.chargeCurrent * 1000];
        }
    }
    _batteryLabel.text = text;
    
    _temperatureLabel.text = [NSString stringWithFormat:@"%0.1f°C / %0.1f°F", power.temperature, power.temperature * 9.0/5.0 + 32.0];

    NSString *site = [collector objectForKey:@"site"];
    _siteLabel.text = site;

    NSNumber *debugLock = [collector objectForKey:@"debugLock"];
    _debugLockLabel.text = debugLock.boolValue ? @"locked" : @"unlocked";
}

- (void)fireflyIceCollectorEntry:(FDFireflyIceCollectorEntry *)entry
{
    [self configureView];
}

- (IBAction)updateOverview:(id)sender
{
    [self.device.fireflyIce.executor execute:self.device.collector];
}

@end
