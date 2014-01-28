//
//  FDDetailPowerViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 1/27/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDBatteryView.h"
#import "FDDetailPowerViewController.h"

@interface FDDetailPowerViewController ()

@property IBOutlet FDBatteryView *batteryView;
@property IBOutlet UILabel *voltageLabel;
@property IBOutlet UILabel *temperatureLabel;
@property IBOutlet UILabel *usbLabel;

@end

@implementation FDDetailPowerViewController

- (void)configureView
{
    FDFireflyIceCollector *collector = self.device[@"collector"];
    
    FDFireflyIcePower *power = [collector objectForKey:@"power"];
    
    _batteryView.currentValue = (NSUInteger)(power.batteryLevel * 100);
    
    _voltageLabel.text = [NSMutableString stringWithFormat:@"%0.1fV", power.batteryVoltage];
    
    NSMutableString *text = [NSMutableString string];
    if (power.isUSBPowered) {
        [text appendString:@"USB Powered"];
        if (power.isCharging) {
            [text appendFormat:@" & Charging @ %0.1fmA", power.chargeCurrent * 1000];
        }
    }
    _usbLabel.text = text;
    
    _temperatureLabel.text = [NSString stringWithFormat:@"%0.1f°C / %0.1f°F", power.temperature, power.temperature * 9.0/5.0 + 32.0];
}

- (void)fireflyIceCollectorEntry:(FDFireflyIceCollectorEntry *)entry
{
    [self configureView];
}

- (IBAction)updatePower:(id)sender
{
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    FDFireflyIceCollector *collector = self.device[@"collector"];
    [fireflyIce.executor execute:collector];
}

@end
