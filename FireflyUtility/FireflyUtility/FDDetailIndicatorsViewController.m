//
//  FDDetailIndicatorsViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/23/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDColorButton.h"
#import "FDColorPickerViewController.h"
#import "FDDetailIndicatorsViewController.h"

#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceCoder.h>
#import <FireflyDevice/FDFireflyIceSimpleTask.h>

@interface FDDetailIndicatorsViewController ()

@property IBOutlet FDColorButton *usbButton;
@property IBOutlet FDColorButton *d0Button;
@property IBOutlet FDColorButton *d1Button;
@property IBOutlet FDColorButton *d2Button;
@property IBOutlet FDColorButton *d3Button;
@property IBOutlet FDColorButton *d4Button;

@property IBOutlet UISlider *durationSlider;
@property IBOutlet UILabel *durationLabel;

@property IBOutlet UIButton *overrideButton;

@end

@implementation FDDetailIndicatorsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.buttons addObject:_overrideButton];
    _usbButton.color = [UIColor orangeColor];
    _d0Button.color = [UIColor redColor];
    _d1Button.color = [UIColor whiteColor];
    _d2Button.color = [UIColor whiteColor];
    _d3Button.color = [UIColor whiteColor];
    _d4Button.color = [UIColor redColor];
}

- (void)pickColor:(FDColorButton *)button hueRange:(FDRange)hueRange saturationRange:(FDRange)saturationRange
{
    FDColorPickerViewController *picker = [FDColorPickerViewController colorPickerViewController];
    
    picker.doneBlock = ^(UIColor *color) {
        [self dismissViewControllerAnimated:YES completion:nil];
        button.color = color;
    };
    
    picker.hueRange = hueRange;
    picker.saturationRange = saturationRange;
    picker.brightnessRange = FDRangeMake(0.0f, 1.0f);
    
    picker.color = button.color;
    
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:picker] animated:YES completion:nil];
}

- (void)pickRedGreenBlue:(FDColorButton *)button
{
    [self pickColor:button hueRange:FDRangeMake(0.0f, 360.0f / 360.0f) saturationRange:FDRangeMake(0.0f, 1.0f)];
}

- (void)pickRedGreen:(FDColorButton *)button
{
    [self pickColor:button hueRange:FDRangeMake(0.0f, 120.0f / 360.0f) saturationRange:FDRangeMake(1.0f, 1.0f)];
}

- (void)pickRed:(FDColorButton *)button
{
    [self pickColor:button hueRange:FDRangeMake(0.0f, 0.0f / 360.0f) saturationRange:FDRangeMake(1.0f, 1.0f)];
}

- (IBAction)pickColorForUSB:(id)sender
{
    [self pickRedGreen:_usbButton];
}

- (IBAction)pickColorForD0:(id)sender
{
    [self pickRed:_d0Button];
}

- (IBAction)pickColorForD1:(id)sender
{
    [self pickRedGreenBlue:_d1Button];
}

- (IBAction)pickColorForD2:(id)sender
{
    [self pickRedGreenBlue:_d2Button];
}

- (IBAction)pickColorForD3:(id)sender
{
    [self pickRedGreenBlue:_d3Button];
}

- (IBAction)pickColorForD4:(id)sender
{
    [self pickRed:_d4Button];
}

- (unsigned)testDuration
{
    return (unsigned)round(_durationSlider.value * 60);
}

- (void)configureView
{
    _durationLabel.text = [NSString stringWithFormat:@"%d seconds", [self testDuration]];
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
    
    uint32_t rgb = [self toRGB:_usbButton.color];
    uint8_t usbRed = (rgb >> 16) & 0xff;
    uint8_t usbGreen = (rgb >> 8) & 0xff;
    uint8_t d0 = ([self toRGB:_d0Button.color] >> 16) & 0xff;
    uint32_t d1 = [self toRGB:_d1Button.color];
    uint32_t d2 = [self toRGB:_d2Button.color];
    uint32_t d3 = [self toRGB:_d3Button.color];
    uint8_t d4 = ([self toRGB:_d4Button.color] >> 16) & 0xff;
    
    NSTimeInterval duration = [self testDuration];

    [fireflyIce.executor execute:[FDFireflyIceSimpleTask simpleTask:fireflyIce channel:channel block:^(void) {
        [fireflyIce.coder sendLEDOverride:channel usbOrange:usbRed usbGreen:usbGreen d0:d0 d1:d1 d2:d2 d3:d3 d4:d4 duration:duration];
    }]];
}

@end
