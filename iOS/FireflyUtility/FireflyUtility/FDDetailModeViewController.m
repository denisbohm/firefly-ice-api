//
//  FDDetailModeViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 2/9/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDDetailModeViewController.h"

#import <FireflyDevice/FDFireflyIceCoder.h>

@interface FDDetailModeViewController ()

@property IBOutlet UIButton *modeButton;

@end

@implementation FDDetailModeViewController

- (NSString *)helpText
{
    return
    @"The Firefly Ice can be put into a very low power storage mode when not in use.\n\n"
    @"Plug the device into USB power to wake it up."
    ;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.controls addObject:_modeButton];
}

- (IBAction)enterStorageMode:(id)sender
{
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = self.device[@"channel"];
    
    [fireflyIce.coder sendSetPropertyMode:channel mode:FD_CONTROL_MODE_STORAGE];
}

@end
