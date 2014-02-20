//
//  FDDetailUpdateViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/23/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetailUpdateViewController.h"
#import "FDUpdateView.h"

#import <FireflyDevice/FDCrypto.h>
#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceCoder.h>
#import <FireflyDevice/FDFirmwareUpdateTask.h>
#import <FireflyDevice/FDIntelHex.h>

@interface FDDetailUpdateViewController () <FDFirmwareUpdateTaskDelegate>

@property IBOutlet UILabel *currentVersionLabel;

@property IBOutlet UILabel *deviceVersionLabel;

@property IBOutlet UIProgressView *progressView;
@property IBOutlet FDUpdateView *updateView;

@property IBOutlet UIButton *updateButton;

@property FDIntelHex *intelHex;

@end

@implementation FDDetailUpdateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.controls addObject:_updateButton];
    
    _intelHex = [FDFirmwareUpdateTask loadFirmware:@"FireflyIce"];
    _currentVersionLabel.text = [NSString stringWithFormat:@"v%@.%@.%@", _intelHex.properties[@"major"] , _intelHex.properties[@"minor"], _intelHex.properties[@"patch"]];
}

- (void)configureView
{
    FDFireflyIceCollector *collector = self.device[@"collector"];
    FDFireflyIceVersion *version = [collector objectForKey:@"version"];
    _deviceVersionLabel.text = [NSString stringWithFormat:@"v%d.%d.%d", version.major, version.minor, version.patch];
}

- (void)firmwareUpdateTask:(FDFirmwareUpdateTask *)task progress:(float)progress
{
    _progressView.progress = progress;
    
    [_updateView setNeedsDisplay];
}

- (void)firmwareUpdateTask:(FDFirmwareUpdateTask *)task complete:(BOOL)isFirmwareUpToDate
{
    _progressView.hidden = YES;
}

- (IBAction)startFirmwareUpdate:(id)sender
{
    _progressView.progress = 0;
    _progressView.hidden = NO;

    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    
    FDFirmwareUpdateTask *task = [FDFirmwareUpdateTask firmwareUpdateTask:fireflyIce channel:channel intelHex:_intelHex];
    task.delegate = self;
    _updateView.firmwareUpdateTask = task;
    [_updateView setNeedsDisplay];
    [fireflyIce.executor execute:task];
}

@end
