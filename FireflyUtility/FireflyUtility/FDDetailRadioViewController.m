//
//  FDDetailRadioViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/23/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetailRadioViewController.h"

#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceCoder.h>

@interface FDDetailRadioViewController ()

@property IBOutlet UISegmentedControl *mode;
@property IBOutlet UILabel *modeLabel;

@property IBOutlet UISegmentedControl *type;
@property IBOutlet UILabel *typeLabel;

@property IBOutlet UISlider *length;
@property IBOutlet UILabel *lengthLabel;

@property IBOutlet UISlider *frequency;
@property IBOutlet UILabel *frequencyLabel;

@property IBOutlet UISlider *duration;
@property IBOutlet UILabel *durationLabel;

@property IBOutlet UILabel *reportLabel;

@end

@implementation FDDetailRadioViewController

- (void)configureView
{
    _modeLabel.text = [_mode titleForSegmentAtIndex:_mode.selectedSegmentIndex];
    _typeLabel.text = [_type titleForSegmentAtIndex:_type.selectedSegmentIndex];
    _lengthLabel.text = [NSString stringWithFormat:@"%d bytes", [self packetLength]];
    _frequencyLabel.text = [NSString stringWithFormat:@"%d MHz", [self packetFrequency]];
    _durationLabel.text = [NSString stringWithFormat:@"%d minutes", [self testDuration]];
}

- (unsigned)packetLength
{
    return (unsigned)round(_length.value * 0x25);
}

// N = 0x00 – 0x27: N = (F-2402)/2 Frequency Range 2402 MHz to 2480 MHz
- (unsigned)packetFrequencyCode
{
    return (unsigned)round(_frequency.value * 0x27);
}

- (unsigned)packetFrequency
{
    unsigned N = [self packetFrequencyCode];
    return 2 * N + 2402;
}

- (unsigned)testDuration
{
    return (unsigned)round(_duration.value * 60);
}

- (void)fireflyIceDirectTestModeReport:(id<FDFireflyIceChannel>)channel result:(uint16_t)result
{
    _reportLabel.text = [NSString stringWithFormat:@"%d packets received", result & 0x7fff];
}

- (IBAction)startDirectTestMode:(id)sender
{
    FDFireflyIce *fireflyIce = self.device.fireflyIce;
    
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    
    FDDirectTestModeCommand command = (_mode.selectedSegmentIndex == 0) ? FDDirectTestModeCommandTransmitterTest : FDDirectTestModeCommandReceiverTest;
    uint8_t frequency = [self packetFrequencyCode];
    uint8_t length = [self packetLength];
    FDDirectTestModePacketType type = _type.selectedSegmentIndex;
    uint16_t packet = [FDFireflyIceCoder makeDirectTestModePacket:command frequency:frequency length:length type:type];
    
    NSTimeInterval duration = [self testDuration] * 60;

    [fireflyIce.coder sendDirectTestModeEnter:channel packet:packet duration:duration];
}

- (IBAction)report:(id)sender
{
    FDFireflyIce *fireflyIce = self.device.fireflyIce;
    
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];

    [fireflyIce.coder sendDirectTestModeReport:channel];
}

- (IBAction)valueChanged:(id)sender
{
    [self configureView];
}

@end
