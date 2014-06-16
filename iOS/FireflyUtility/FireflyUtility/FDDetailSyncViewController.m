//
//  FDDetailSyncViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 6/12/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDDetailSyncViewController.h"

#import <FireflyDevice/FDFireflyIceCoder.h>
#import <FireflyDevice/FDFireflyIceSimpleTask.h>
#import <FireflyDevice/FDSyncTask.h>

@interface FDDetailSyncSampleSet : NSObject

@property NSTimeInterval time;
@property NSTimeInterval interval;
@property NSArray *accs;

@end

@implementation FDDetailSyncSampleSet
@end

@interface FDDetailSyncViewController () <FDSyncTaskDelegate>

@property IBOutlet UILabel *samplesLabel;
@property IBOutlet UISlider *samplesSlider;
@property IBOutlet UIProgressView *progressView;

@property IBOutlet UIButton *sampleButton;
@property IBOutlet UIButton *syncButton;
@property IBOutlet UIButton *saveButton;

@property NSMutableArray *sampleSets;

@end

@implementation FDDetailSyncViewController

- (NSString *)helpText
{
    return
    @"The Firefly Ice can collect raw accelerometer samples, sync the data to iOS, and save it to iCloud."
    ;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.controls addObject:_sampleButton];
    [self.controls addObject:_syncButton];
//    [self.controls addObject:_saveButton];
    
    _sampleSets = [NSMutableArray array];
}

- (void)configureView
{
    double seconds = _samplesSlider.value * 10.0;
    _samplesLabel.text = [NSString stringWithFormat:@"%0.1f seconds", seconds];
}

- (IBAction)valueChanged:(id)sender
{
    [self configureView];
}

- (void)syncTask:(FDSyncTask *)syncTask progress:(float)progress;
{
    _progressView.progress = progress;
}

- (void)syncTaskComplete:(FDSyncTask *)syncTask;
{
    _progressView.hidden = YES;
}

- (void)syncTask:(FDSyncTask *)syncTask error:(NSError *)error
{
    _progressView.hidden = YES;
}

- (void)syncTask:(FDSyncTask *)syncTask site:(NSString *)site hardwareId:(NSString *)hardwareId time:(NSTimeInterval)time interval:(NSTimeInterval)interval accs:(NSArray *)accs backlog:(NSUInteger)backlog
{
    FDDetailSyncSampleSet *sampleSet = [[FDDetailSyncSampleSet alloc] init];
    sampleSet.time = time;
    sampleSet.interval = interval;
    sampleSet.accs = accs;
    [_sampleSets addObject:sampleSet];
}

- (IBAction)startSampling:(id)sender
{
    uint32_t count = _samplesSlider.value * 250;
    
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = self.device[@"channel"];
    
    FDFireflyIceSimpleTask *task = [FDFireflyIceSimpleTask simpleTask:fireflyIce channel:channel block:^() {
        [fireflyIce.coder sendSetPropertySensingCount:channel count:count];
    }];
    [fireflyIce.executor execute:task];
}

- (NSString *)sampleSetsAsText
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd hh:mm:ss.SSS"];
    NSMutableString *text = [NSMutableString string];
    for (FDDetailSyncSampleSet *sampleSet in _sampleSets) {
        NSTimeInterval offset = 0;
        for (FDSyncTaskAcc *acc in sampleSet.accs) {
            NSString *timestamp = [dateFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:sampleSet.time + offset]];
            [text appendFormat:@"%@\t%0.3f\t%0.3f\t%0.3f\n", timestamp, acc.x, acc.y, acc.z];
            offset += sampleSet.interval / 1000.0;
        }
    }
    return text;
}

- (IBAction)saveSamples:(id)sender
{
    NSString *hardwareId = @"hwid";
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH_mm_ss"];
    NSString *timestamp = [dateFormat stringFromDate:date];
    NSString *name = [NSString stringWithFormat:@"%@ %@.txt", hardwareId, timestamp];
    
    NSURL *temporaryDirectoryURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSURL *sourceURL = [temporaryDirectoryURL URLByAppendingPathComponent:name];
    NSString *text = [self sampleSetsAsText];
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    if (![data writeToURL:sourceURL options:NSDataWritingAtomic error:&error]) {
        NSLog(@"can't save samples to local file: %@", error);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
        NSURL *ubiquitousURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        if (ubiquitousURL == nil) {
            NSLog(@"iCloud is not enabled");
            return;
        }
        NSURL *destinationURL = [[ubiquitousURL URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:name];
        
        NSError *error = nil;
        if ([[NSFileManager defaultManager] setUbiquitous:YES itemAtURL:sourceURL destinationURL:destinationURL error:&error] != YES) {
            NSLog(@"can't save samples to iCloud: %@", error);
            return;
        }
        NSLog(@"samples saved to iCloud");
        _sampleSets = [NSMutableArray array];
    });
}

- (IBAction)startSync:(id)sender
{
    _progressView.progress = 0;
    _progressView.hidden = NO;
    
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = self.device[@"channel"];
    
    FDSyncTask *task = [FDSyncTask syncTask:@"hwid" fireflyIce:fireflyIce channel:channel delegate:self identifier:@"FireflyUtility"];
    [fireflyIce.executor execute:task];
}

@end
