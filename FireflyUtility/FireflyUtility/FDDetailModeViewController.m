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
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    
    [fireflyIce.coder sendSetPropertyMode:channel mode:FD_CONTROL_MODE_STORAGE];
}

@end
