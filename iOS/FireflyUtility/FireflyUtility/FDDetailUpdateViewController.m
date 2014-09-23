//
//  FDDetailUpdateViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/23/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetailUpdateViewController.h"
#import "FDUpdateView.h"
#import "FDVersionPicker.h"

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

@property NSArray *versions;
@property NSInteger versionIndex;

@end

@implementation FDDetailUpdateViewController

- (NSString *)helpText
{
    return
    @"The Firefly Ice firmware can be updated over the air.\n\n"
    @"A firmware update has two phases:\n"
    @"1) Transferring the firmware.\n"
    @"2) Commiting the firmware and restarting."
    ;
}

- (NSString *)formatVersion:(FDIntelHex *)intelHex
{
    return [NSString stringWithFormat:@"%@.%@.%@ %@", intelHex.properties[@"major"] , intelHex.properties[@"minor"], intelHex.properties[@"patch"], intelHex.properties[@"note"]];
}

- (void)showCurrentVersion
{
    FDIntelHex *intelHex = _versions[_versionIndex];
    _currentVersionLabel.text = [self formatVersion:intelHex];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.controls addObject:_updateButton];
    
    _versions = [FDFirmwareUpdateTask loadAllFirmwareVersions:@"FireflyIce"];
    _versionIndex = 0;
    [self showCurrentVersion];
}

- (void)unconfigureView
{
    _deviceVersionLabel.text = @"-";
}

- (void)configureView
{
    FDFireflyIceCollector *collector = self.device[@"collector"];
    if (collector.dictionary.count == 0) {
        [self unconfigureView];
        return;
    }

    FDFireflyIceVersion *version = [collector objectForKey:@"version"];
    _deviceVersionLabel.text = [NSString stringWithFormat:@"%d.%d.%d", version.major, version.minor, version.patch];
}

- (void)fireflyIceCollectorEntry:(FDFireflyIceCollectorEntry *)entry
{
    [self configureView];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"pickVersion"]) {
        NSMutableArray *versions = [NSMutableArray array];
        for (FDIntelHex *intelHex in _versions) {
            [versions addObject:[self formatVersion:intelHex]];
        }
             
        FDVersionPicker *picker = (FDVersionPicker *)segue.destinationViewController;
        picker.items = versions;
        picker.selectedItem = versions[0];
    }
}

- (IBAction)unwindToUpdate:(UIStoryboardSegue *)unwindSegue
{
    FDVersionPicker *picker = (FDVersionPicker *)unwindSegue.sourceViewController;
    _versionIndex = picker.chosenIndex;
    [self showCurrentVersion];
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
    id<FDFireflyIceChannel> channel = self.device[@"channel"];
    
    FDIntelHex *intelHex = _versions[_versionIndex];
    FDFirmwareUpdateTask *task = [FDFirmwareUpdateTask firmwareUpdateTask:fireflyIce channel:channel intelHex:intelHex];
    task.downgrade = true;
    task.delegate = self;
    _updateView.firmwareUpdateTask = task;
    [_updateView setNeedsDisplay];
    [fireflyIce.executor execute:task];
}

@end
