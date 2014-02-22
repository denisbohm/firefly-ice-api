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
    return
    @"Touch the 'Connect' button above to connect to the device and interact with it.\n\n"
    @"The overview will show information about the basic configuration of the device.\n\n"
    @"Touch the device name at the top to modify it."
    ;
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

- (void)unconfigureView
{
    _nameTextField.text = @"-";
    
    _hardwareRevisionLabel.text = @"-";
    _vendorAndProductLabel.text = @"-";
    _hardwareIdLabel.text = @"-";
    
    _bootRevisionLabel.text = @"-";
    
    _firmwareRevisionLabel.text = @"-";
    
    _debugLockLabel.text = @"-";
}

- (void)configureView
{
    FDFireflyIceCollector *collector = self.device[@"collector"];
    if (collector.dictionary.count == 0) {
        [self unconfigureView];
        return;
    }
    
    _nameTextField.text = [collector objectForKey:@"name"];
    
    FDFireflyIceHardwareId *hardwareId = [collector objectForKey:@"hardwareId"];
    _hardwareRevisionLabel.text = [NSString stringWithFormat:@"v%d.%d", hardwareId.major, hardwareId.minor];
    _vendorAndProductLabel.text = [NSString stringWithFormat:@"%04x / %04x", hardwareId.vendor, hardwareId.product];
    _hardwareIdLabel.text = [NSString stringWithFormat:@"%@", [self toHex:hardwareId.unique]];
    
    FDFireflyIceVersion *bootVersion = [collector objectForKey:@"bootVersion"];
    _bootRevisionLabel.text = [NSString stringWithFormat:@"v%d.%d.%d", bootVersion.major, bootVersion.minor, bootVersion.patch];
    
    FDFireflyIceVersion *version = [collector objectForKey:@"version"];
    _firmwareRevisionLabel.text = [NSString stringWithFormat:@"v%d.%d.%d", version.major, version.minor, version.patch];
    
    NSNumber *debugLock = [collector objectForKey:@"debugLock"];
    _debugLockLabel.text = debugLock.boolValue ? @"Locked" : @"Unlocked";
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
    id<FDFireflyIceChannel> channel = self.device[@"channel"];
    [fireflyIce.coder sendSetPropertyName:channel name:name];
}

- (IBAction)updateOverview:(id)sender
{
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    FDFireflyIceCollector *collector = self.device[@"collector"];
    [fireflyIce.executor execute:collector];
}

@end
