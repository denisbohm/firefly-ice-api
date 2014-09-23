//
//  FDDetailTimingViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 7/8/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDAppDelegate.h"
#import "FDDetailTimingViewController.h"
#import "FDMasterViewController.h"
#import "FDTimingView.h"

#import <FireflyDevice/FDFireflyIceCoder.h>
#import <FireflyDevice/FDFireflyIceSimpleTask.h>
#import <FireflyDevice/FDSyncTask.h>

@interface FDSensor : NSObject

@property FDFireflyIce *fireflyIce;
@property id<FDFireflyIceChannel> channel;
@property NSString *hardwareId;
@property NSMutableArray *samples;
@property float progress;
@property BOOL complete;

@end

@implementation FDSensor

- (id)init
{
    if (self = [super init]) {
        _samples = [NSMutableArray array];
    }
    return self;
}

@end

@interface FDRecognition : NSObject

@property NSInteger alphaIndex;
@property NSInteger deltaIndex;

@end

@implementation FDRecognition

@end

@interface FDDetailTimingViewController () <FDSyncTaskDelegate>

@property IBOutlet FDTimingView *timingView;
@property IBOutlet UIButton *syncButton;
@property IBOutlet UIProgressView *progressView;
@property IBOutlet UISwitch *recognitionSwitch;

@property FDSensor *alphaSensor;
@property FDSensor *deltaSensor;

@property NSTimeInterval interval;

@end

@implementation FDDetailTimingViewController

- (NSString *)helpText
{
    return
    @"The Firefly Ice can recognize events.  This panel shows the timing between events from two devices."
    ;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.controls addObject:_syncButton];
    [self.controls addObject:_recognitionSwitch];
    
    _interval = 0.040;
}

- (void)unconfigureView
{
}

- (void)configureView
{
    FDFireflyIceCollector *collector = self.device[@"collector"];
    if (collector.dictionary.count == 0) {
        [self unconfigureView];
        return;
    }
    
    NSNumber *number = [collector objectForKey:@"recognition"];
    BOOL recognition = [number boolValue];
    _recognitionSwitch.on = recognition;
}

- (void)fireflyIceCollectorEntry:(FDFireflyIceCollectorEntry *)entry
{
    [self configureView];
}

- (NSInteger)findLastIndex:(NSArray *)samples beforeTime:(NSTimeInterval)time
{
    for (NSInteger i = samples.count - 1; i >= 0; --i) {
        FDSensorSample *sample = samples[i];
        if (sample.time < time) {
            return i;
        }
    }
    return -1;
}

- (NSInteger)findLastEvent:(NSArray *)samples
{
    for (NSInteger i = samples.count - 1; i >= 0; --i) {
        FDSensorSample *sample = samples[i];
        if (sample.a >= 2.0f) {
            return i;
        }
    }
    return -1;
}

- (NSArray *)samples:(NSArray *)samples fromTime:(NSTimeInterval)t0 toTime:(NSTimeInterval)tn
{
    NSInteger count = ceil((tn - t0) / _interval);
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger i = 0; i < count; ++i) {
        FDSensorSample *sample = [[FDSensorSample alloc] init];
        sample.ax = sample.ay = sample.az = 0.0f;
        sample.time = t0 + i * _interval;
        [result addObject:sample];
    }

    for (FDSensorSample *sample in samples) {
        NSInteger index = round((sample.time - t0) / _interval);
        if ((0 <= index) && (index < count)) {
            [result replaceObjectAtIndex:index withObject:sample];
        }
    }
    return result;
}

// Find last event for delta sensor.
// Find last event for alpha sensor before event from delta sensor (within some time limit - 10 seconds / 250 samples).
- (FDRecognition *)recognize
{
    NSInteger deltaIndex = [self findLastEvent:_deltaSensor.samples];
    if (deltaIndex < 0) {
        return nil;
    }
    FDSensorSample *deltaSample = _deltaSensor.samples[deltaIndex];
    NSInteger beforeIndex = [self findLastIndex:_alphaSensor.samples beforeTime:deltaSample.time];
    if (beforeIndex < 0) {
        return nil;
    }
    NSInteger alphaIndex = [self findLastEvent:[_alphaSensor.samples subarrayWithRange:NSMakeRange(0, beforeIndex)]];
    if (alphaIndex < 0) {
        return nil;
    }
    FDRecognition *recognition = [[FDRecognition alloc] init];
    recognition.alphaIndex = alphaIndex;
    recognition.deltaIndex = deltaIndex;
    return recognition;
}

// Show waveforms in timing view from ta - 20% to td + 20%.
- (void)showRecognition:(FDRecognition *)recognition
{
    NSInteger alphaIndex = recognition.alphaIndex;
    NSInteger deltaIndex = recognition.deltaIndex;
    FDSensorSample *alphaSample = _alphaSensor.samples[alphaIndex];
    FDSensorSample *deltaSample = _deltaSensor.samples[deltaIndex];

    NSInteger deltaIntervals = (NSInteger)round((deltaSample.time - alphaSample.time) / _interval);
    NSInteger marginIntervals = deltaIntervals / 5; // 20%
    NSTimeInterval t0 = alphaSample.time - marginIntervals * _interval;
    NSTimeInterval tn = deltaSample.time + marginIntervals * _interval;
    
    [_timingView.alphaSamples removeAllObjects];
    [_timingView.alphaSamples addObjectsFromArray:[self samples:_alphaSensor.samples fromTime:t0 toTime:tn]];
    
    [_timingView.deltaSamples removeAllObjects];
    [_timingView.deltaSamples addObjectsFromArray:[self samples:_deltaSensor.samples fromTime:t0 toTime:tn]];
    
    _timingView.maxSampleCount = marginIntervals + deltaIntervals + marginIntervals;
    
    NSTimeInterval duration = deltaSample.time - alphaSample.time;
    _timingView.duration = [NSString stringWithFormat:@"%0.2f", duration];
    
    [_timingView setNeedsDisplay];
}

- (void)showLatest
{
    // show latest 10 seconds
    FDSensorSample *last = [_deltaSensor.samples lastObject];
    NSTimeInterval tn = last.time;
    NSTimeInterval t0 = tn - 10 * _interval;

    [_timingView.alphaSamples removeAllObjects];
    [_timingView.alphaSamples addObjectsFromArray:[self samples:_alphaSensor.samples fromTime:t0 toTime:tn]];
    
    [_timingView.deltaSamples removeAllObjects];
    [_timingView.deltaSamples addObjectsFromArray:[self samples:_deltaSensor.samples fromTime:t0 toTime:tn]];
    
    _timingView.duration = @"n/a";
    
    [_timingView setNeedsDisplay];
}

- (FDSensor *)getSensor:(FDFireflyIce *)fireflyIce
{
    if (_alphaSensor.fireflyIce == fireflyIce) {
        return _alphaSensor;
    }
    if (_deltaSensor.fireflyIce == fireflyIce) {
        return _deltaSensor;
    }
    return nil;
}

- (void)sensor:(FDSensor *)sensor syncProgress:(float)progress
{
    sensor.progress = progress;
    
    _progressView.progress = _alphaSensor.progress < _deltaSensor.progress ? _alphaSensor.progress : _deltaSensor.progress;
}

- (void)sensorSyncComplete:(FDSensor *)sensor
{
    sensor.complete = YES;
    
    if (_alphaSensor.complete && _deltaSensor.complete) {
        _progressView.hidden = YES;
        
        FDRecognition *recognition = [self recognize];
        if (recognition != nil) {
            [self showRecognition:recognition];
        } else {
            [self showLatest];
        }
    }
}

- (void)sensor:(FDSensor *)sensor syncError:(NSError *)error
{
    NSLog(@"sensor sync error %@", error);
    
    [self sensorSyncComplete:sensor];
}

- (void)sensor:(FDSensor *)sensor syncSamples:(NSArray *)samples
{
    [sensor.samples addObjectsFromArray:samples];
}

- (void)syncTask:(FDSyncTask *)syncTask progress:(float)progress;
{
    FDSensor *sensor = [self getSensor:syncTask.fireflyIce];
    dispatch_async(dispatch_get_main_queue(), ^() {
        [self sensor:sensor syncProgress:progress];
    });
}

- (void)syncTaskComplete:(FDSyncTask *)syncTask;
{
    FDSensor *sensor = [self getSensor:syncTask.fireflyIce];
    dispatch_async(dispatch_get_main_queue(), ^() {
        [self sensorSyncComplete:sensor];
    });
}

- (void)syncTask:(FDSyncTask *)syncTask error:(NSError *)error
{
    FDSensor *sensor = [self getSensor:syncTask.fireflyIce];
    dispatch_async(dispatch_get_main_queue(), ^() {
        [self sensor:sensor syncError:error];
    });
}

- (void)syncTask:(FDSyncTask *)syncTask site:(NSString *)site hardwareId:(NSString *)hardwareId time:(NSTimeInterval)time interval:(NSTimeInterval)interval accs:(NSArray *)accs backlog:(NSUInteger)backlog
{
    NSMutableArray *samples = [NSMutableArray array];
    for (FDSyncTaskAcc *acc in accs) {
        FDSensorSample *sample = [[FDSensorSample alloc] init];
        sample.ax = acc.x;
        sample.ay = acc.y;
        sample.az = acc.z;
        sample.time = time;
        NSLog(@"sync %@ %0.3f %0.3f %0.3f %0.3f", hardwareId, sample.time, sample.ax, sample.ay, sample.az);
        [samples addObject:sample];
        time += interval / 1000.0;
    }
    
    FDSensor *sensor = [self getSensor:syncTask.fireflyIce];
    dispatch_async(dispatch_get_main_queue(), ^() {
        [self sensor:sensor syncSamples:samples];
    });
}

- (void)sensorStartSync:(FDSensor *)sensor
{
    sensor.progress = 0.0f;
    sensor.complete = NO;
    FDFireflyIce *fireflyIce = sensor.fireflyIce;
    id<FDFireflyIceChannel> channel = sensor.channel;
    [fireflyIce.executor execute:[FDSyncTask syncTask:sensor.hardwareId fireflyIce:fireflyIce channel:channel delegate:self identifier:@"FDDetailTimingViewController"]];
}

- (NSDictionary *)getOpenDevice:(NSArray *)devices except:(NSDictionary *)except
{
    for (NSDictionary *device in devices) {
        if (device == except) {
            continue;
        }
        id<FDFireflyIceChannel> channel = device[@"channel"];
        if (channel.status == FDFireflyIceChannelStatusOpen) {
            return device;
        }
    }
    return nil;
}

- (IBAction)startSync:(id)sender
{
    _alphaSensor = [[FDSensor alloc] init];
    _alphaSensor.fireflyIce = self.device[@"fireflyIce"];
    _alphaSensor.channel = self.device[@"channel"];
    _alphaSensor.hardwareId = _alphaSensor.fireflyIce.name;
    
    UIApplication *application = [UIApplication sharedApplication];
    FDAppDelegate *appDelegate = (FDAppDelegate *)application.delegate;
    FDMasterViewController *masterViewController = appDelegate.masterViewController;
    NSDictionary *delta = [self getOpenDevice:masterViewController.devices except:self.device];
    _deltaSensor = [[FDSensor alloc] init];
    _deltaSensor.fireflyIce = delta[@"fireflyIce"];
    _deltaSensor.channel = delta[@"channel"];
    _deltaSensor.hardwareId = _deltaSensor.fireflyIce.name;
    
    _progressView.progress = 0.0f;
    _progressView.hidden = NO;
    
    [self sensorStartSync:_alphaSensor];
    [self sensorStartSync:_deltaSensor];
}

- (IBAction)recognitionSwitchChanged:(id)sender
{
    BOOL enabled = _recognitionSwitch.on;
    FDFireflyIce *fireflyIce = self.device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = self.device[@"channel"];
    [fireflyIce.coder sendSetPropertyRecognition:channel recognition:enabled];
}

@end
