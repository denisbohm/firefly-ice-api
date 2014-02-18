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

@property IBOutlet UITextField *nameTextField;
@property IBOutlet UILabel *hardwareIdLabel;
@property IBOutlet UILabel *hardwareRevisionLabel;
@property IBOutlet UILabel *bootRevisionLabel;
@property IBOutlet UILabel *firmwareRevisionLabel;
@property IBOutlet UILabel *vendorAndProductLabel;
@property IBOutlet UILabel *debugLockLabel;

@property IBOutlet UIButton *updateButton;

@end

@implementation FDDetailOverviewViewController

- (NSString *)helpText
{
    return @"Overview:\nShows basic information about the firefly ice.";
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.controls addObject:_nameTextField];
    [self.controls addObject:_updateButton];
    
    self.nameTextField.returnKeyType = UIReturnKeyDone;
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
    FDFireflyIceCollector *collector = self.device[@"collector"];
    
    _nameTextField.text = [collector objectForKey:@"name"];
    
    FDFireflyIceVersion *version = [collector objectForKey:@"version"];
    FDFireflyIceVersion *bootVersion = [collector objectForKey:@"bootVersion"];
    FDFireflyIceHardwareId *hardwareId = [collector objectForKey:@"hardwareId"];
    
    _hardwareRevisionLabel.text = [NSString stringWithFormat:@"Hardware v%d.%d", hardwareId.major, hardwareId.minor];
    _vendorAndProductLabel.text = [NSString stringWithFormat:@"USB VID %04x / PID %04x", hardwareId.vendor, hardwareId.product];
    _hardwareIdLabel.text = [NSString stringWithFormat:@"UUID %@", [self toHex:hardwareId.unique]];
    
    _bootRevisionLabel.text = [NSString stringWithFormat:@"Boot Loader v%d.%d.%d", bootVersion.major, bootVersion.minor, bootVersion.patch];
    
    _firmwareRevisionLabel.text = [NSString stringWithFormat:@"Firmware v%d.%d.%d", version.major, version.minor, version.patch];
    
    NSNumber *debugLock = [collector objectForKey:@"debugLock"];
    _debugLockLabel.text = debugLock.boolValue ? @"Debug Lock Set" : @"Debug is Unlocked";
}

- (void)fireflyIceCollectorEntry:(FDFireflyIceCollectorEntry *)entry
{
    [self configureView];
}

- (IBAction)beginEditingName:(id)sender
{
    [_nameTextField setBorderStyle:UITextBorderStyleRoundedRect];
}

- (IBAction)endEditingName:(id)sender
{
    [_nameTextField setBorderStyle:UITextBorderStyleNone];
    
    [self updateName:_nameTextField.text];
}

- (IBAction)doneName:(id)sender
{
    [_nameTextField resignFirstResponder];    
}

- (void)updateName:(NSString *)name
{
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    [fireflyIce.coder sendSetPropertyName:channel name:name];
}

- (IBAction)updateOverview:(id)sender
{
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    FDFireflyIceCollector *collector = self.device[@"collector"];
    [fireflyIce.executor execute:collector];
}

@end
