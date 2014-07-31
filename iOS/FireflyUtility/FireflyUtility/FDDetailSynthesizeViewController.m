//
//  FDDetailSynthesizeViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 7/7/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDDetailSynthesizeViewController.h"

#import <FireflyDevice/FDFireflyIceCoder.h>
#import <FireflyDevice/FDFireflyIceSimpleTask.h>
#import <FireflyDevice/FDSyncTask.h>

@interface FDDetailSynthesizeViewController ()

@property IBOutlet UILabel *synthesizeLabel;
@property IBOutlet UISlider *synthesizeSlider;

@property IBOutlet UIButton *synthesizeButton;

@end

@implementation FDDetailSynthesizeViewController

- (NSString *)helpText
{
    return
    @"The Firefly Ice can synthesize raw accelerometer samples, useful for testing syncing."
    ;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.controls addObject:_synthesizeButton];
}

- (void)unconfigureView
{
}

- (void)configureView
{
    _synthesizeLabel.text = [NSString stringWithFormat:@"%0.1f days", _synthesizeSlider.value * 2];
}

- (IBAction)valueChanged:(id)sender
{
    [self configureView];
}

- (IBAction)synthesize:(id)sender
{
    uint32_t samples = _synthesizeSlider.value * 2 * 24 * 60 * 6;
    
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = self.device[@"channel"];
    
    FDFireflyIceSimpleTask *task = [FDFireflyIceSimpleTask simpleTask:fireflyIce channel:channel block:^() {
        [fireflyIce.coder sendSensingSynthesize:channel samples:samples vma:3.0f];
    }];
    [fireflyIce.executor execute:task];
}

@end
