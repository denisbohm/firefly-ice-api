//
//  FDDetailIndicatorsViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/23/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetailIndicatorsViewController.h"

#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceCoder.h>

@interface FDDetailIndicatorsViewController ()

@property IBOutlet UISegmentedControl *usbColorSegmentedControl;
@property IBOutlet UISwitch *usbSwitch;

@property IBOutlet UISwitch *d0Switch;

@property IBOutlet UISwitch *d1Switch;
@property IBOutlet UIView *d1ColorView;

@property IBOutlet UISwitch *d2Switch;
@property IBOutlet UIView *d2ColorView;

@property IBOutlet UISwitch *d3Switch;
@property IBOutlet UIView *d3ColorView;

@property IBOutlet UISwitch *d4Switch;

@property IBOutlet UISlider *durationSlider;
@property IBOutlet UILabel *durationLabel;

@property IBOutlet UIButton *overrideButton;

@end

@implementation FDDetailIndicatorsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.buttons addObject:_overrideButton];
}

- (IBAction)pickColor:(id)sender
{
}

- (unsigned)testDuration
{
    return (unsigned)round(_durationSlider.value * 60);
}

- (void)configureView
{
    _durationLabel.text = [NSString stringWithFormat:@"%d minutes", [self testDuration]];
}

- (IBAction)valueChanged:(id)sender
{
    [self configureView];
}

- (uint32_t)toRGB:(UIColor *)color
{
    CGFloat r;
    CGFloat g;
    CGFloat b;
    CGFloat a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    uint8_t rb = (uint8_t)round(r * 255);
    uint8_t gb = (uint8_t)round(g * 255);
    uint8_t bb = (uint8_t)round(b * 255);
    return (rb << 16) | (gb << 8) | bb;
}

- (IBAction)startIndicatorsOverride:(id)sender
{
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    
    uint8_t usbOrange = 0;
    uint8_t usbGreen = 0;
    if (_usbSwitch.isOn) {
        if (_usbColorSegmentedControl.selectedSegmentIndex == 0) {
            usbGreen = 0xff;
        } else {
            usbOrange = 0xff;
        }
    }
    uint8_t d0 = _d0Switch.isOn ? 0xff : 0;
    uint32_t d1 = _d1Switch.isOn ? [self toRGB:_d1ColorView.backgroundColor] : 0;
    uint32_t d2 = _d2Switch.isOn ? [self toRGB:_d2ColorView.backgroundColor] : 0;
    uint32_t d3 = _d3Switch.isOn ? [self toRGB:_d3ColorView.backgroundColor] : 0;
    uint8_t d4 = _d4Switch.isOn ? 0xff : 0;
    
    NSTimeInterval duration = [self testDuration];

    [fireflyIce.coder sendIndicatorOverride:channel usbOrange:usbOrange usbGreen:usbGreen d0:d0 d1:d1 d2:d2 d3:d3 d4:d4 duration:duration];
}

@end
