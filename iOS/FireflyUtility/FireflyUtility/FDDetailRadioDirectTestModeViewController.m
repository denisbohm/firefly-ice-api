//
//  FDDetailRadioViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/23/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetailRadioDirectTestModeViewController.h"

#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceCoder.h>

@interface FDDetailRadioDirectTestModeViewController ()

@property IBOutlet UISlider *frequency;
@property IBOutlet UILabel *frequencyLabel;

@property IBOutlet UISlider *duration;
@property IBOutlet UILabel *durationLabel;

@property IBOutlet UISegmentedControl *mode;

@property IBOutlet UILabel *typeTitle;
@property IBOutlet UISegmentedControl *type;

@property IBOutlet UILabel *lengthTitle;
@property IBOutlet UISlider *length;
@property IBOutlet UILabel *lengthLabel;

@property IBOutlet UILabel *reportLabel;

@property IBOutlet UIButton *testButton;

@end

@implementation FDDetailRadioDirectTestModeViewController

- (NSString *)helpText
{
    return
    @"The Bluetooth Low Energy radio can be put into direct test mode for FCC testing, etc.\n\n"
    @"Choose the frequency and duration then click 'Start Radio Direct Test Mode'.\n\n"
    @"To check two Firefly Ice devices, place one in transmit mode and the other in receive mode. Start direct test mode on both simultaneously.  The number of received packets is shown after the test completes."
    ;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.controls addObject:_testButton];
}

- (void)configureView
{
    _lengthLabel.text = [NSString stringWithFormat:@"%d bytes", [self packetLength]];
    _frequencyLabel.text = [NSString stringWithFormat:@"%d MHz", [self packetFrequency]];
    _durationLabel.text = [NSString stringWithFormat:@"%d minutes", [self testDuration]];

    FDFireflyIceCollector *collector = self.device[@"collector"];
    FDFireflyIceDirectTestModeReport *report = [collector objectForKey:@"directTestModeReport"];
    if (report.packetCount & 0x8000) {
        _reportLabel.text = [NSString stringWithFormat:@"%u packets received", report.packetCount & 0x7fff];
    } else {
        _reportLabel.text = @"";
    }
    
    FDDirectTestModeCommand command = (_mode.selectedSegmentIndex == 0) ? FDDirectTestModeCommandTransmitterTest : FDDirectTestModeCommandReceiverTest;
    BOOL isTransmitMode = command == FDDirectTestModeCommandTransmitterTest;
    [_typeTitle setHidden:!isTransmitMode];
    [_type setHidden:!isTransmitMode];
    [_lengthTitle setHidden:!isTransmitMode];
    [_length setHidden:!isTransmitMode];
    [_lengthLabel setHidden:!isTransmitMode];
    [_reportLabel setHidden:isTransmitMode];
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

- (IBAction)startDirectTestMode:(id)sender
{
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = self.device[@"channel"];
    
    FDDirectTestModeCommand command = (_mode.selectedSegmentIndex == 0) ? FDDirectTestModeCommandTransmitterTest : FDDirectTestModeCommandReceiverTest;
    uint8_t frequency = [self packetFrequencyCode];
    uint8_t length = [self packetLength];
    FDDirectTestModePacketType type = (FDDirectTestModePacketType)_type.selectedSegmentIndex;
    uint16_t packet = [FDFireflyIceCoder makeDirectTestModePacket:command frequency:frequency length:length type:type];
    
    NSTimeInterval duration = [self testDuration] * 60;

    [fireflyIce.coder sendDirectTestModeEnter:channel packet:packet duration:duration];
}

- (IBAction)valueChanged:(id)sender
{
    [self configureView];
}

- (void)fireflyIceCollectorEntry:(FDFireflyIceCollectorEntry *)entry
{
    [self configureView];
}

@end
