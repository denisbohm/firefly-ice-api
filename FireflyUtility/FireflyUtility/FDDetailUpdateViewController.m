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
@property IBOutlet UILabel *currentHashLabel;

@property IBOutlet UILabel *deviceVersionLabel;
@property IBOutlet UILabel *deviceHashLabel;

@property IBOutlet UIProgressView *progressView;
@property IBOutlet FDUpdateView *updateView;

@property IBOutlet UIButton *updateButton;

@end

@implementation FDDetailUpdateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.buttons addObject:_updateButton];
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

- (NSString *)loadFirmware:(NSString *)name type:(NSString *)type
{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"hex"];
    return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
}

/*
- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel externalHash:(NSData *)externalHash
{
    NSLog(@"external hash %@", externalHash);
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel pageData:(NSData *)pageData
{
    NSLog(@"page data %@", pageData);
}
*/

- (IBAction)startFirmwareUpdate:(id)sender
{
    _progressView.progress = 0;
    _progressView.hidden = NO;

    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    
    FDFirmwareUpdateTask *task = [[FDFirmwareUpdateTask alloc] init];
    task.fireflyIce = fireflyIce;
    task.channel = channel;
    task.delegate = self;
    [task parseFirmware:[self loadFirmware:@"FireflyIce" type:@"THUMB Flash Release"]];
    _updateView.firmwareUpdateTask = task;
    [_updateView setNeedsDisplay];
    [fireflyIce.executor execute:task];
    /*
    uint32_t length = task.firmware.length;
    NSLog(@"%u expect hash %@", length, [FDCrypto sha1:[task.firmware subdataWithRange:NSMakeRange(0, length)]]);
    [fireflyIce.coder sendUpdateGetExternalHash:channel address:0 length:length]; // task.firmware.length];
     */
}

@end
