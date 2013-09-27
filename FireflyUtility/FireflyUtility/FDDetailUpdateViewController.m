//
//  FDDetailUpdateViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/23/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetailUpdateViewController.h"
#import "FDUpdateView.h"

#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceCoder.h>
#import <FireflyDevice/FDFirmwareUpdateTask.h>
#import <FireflyDevice/FDIntelHex.h>

@interface FDDetailUpdateViewController () <FDFirmwareUpdateTaskDelegate>

@property IBOutlet UILabel *currentVersionLabel;
@property IBOutlet UILabel *currentHashLabel;

@property IBOutlet UILabel *deviceVersionLabel;
@property IBOutlet UILabel *deviceHashLabel;

@property IBOutlet UIProgressView *progressView;
@property IBOutlet FDUpdateView *updateView;

@end

@implementation FDDetailUpdateViewController

- (void)firmwareUpdateTask:(FDFirmwareUpdateTask *)task progress:(float)progress
{
    _progressView.progress = progress;
    
    [_updateView setNeedsDisplay];
}

- (void)firmwareUpdateTask:(FDFirmwareUpdateTask *)task complete:(BOOL)isFirmwareUpToDate
{
    _progressView.hidden = YES;
}

- (NSData *)loadFirmware:(NSString *)name type:(NSString *)type
{
    NSString *path = [NSString stringWithFormat:@"/Users/denis/sandbox/denisbohm/firefly-ice-firmware/%@/%@/%@.hex", type, name, name];
    return [FDIntelHex read:path address:0x08000 length:0x40000 - 0x08000];
}

- (IBAction)startFirmwareUpdate:(id)sender
{
    _progressView.progress = 0;
    _progressView.hidden = NO;

    FDFireflyIce *fireflyIce = self.device.fireflyIce;
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    
    FDFirmwareUpdateTask *task = [[FDFirmwareUpdateTask alloc] init];
    task.fireflyIce = fireflyIce;
    task.channel = channel;
    task.delegate = self;
    task.firmware = [self loadFirmware:@"FireflyIce" type:@"THUMB Flash Release"];
    _updateView.firmwareUpdateTask = task;
    [_updateView setNeedsDisplay];
    [fireflyIce.executor execute:task];
}

@end
