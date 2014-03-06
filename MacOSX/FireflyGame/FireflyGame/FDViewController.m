
//
//  FDViewController.m
//  FireflyGame
//
//  Created by Denis Bohm on 10/21/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDPickScene.h"
#import "FDPlayScene.h"
#import "FDViewController.h"

#import <FireflyDevice/FDFireflyDeviceLogger.h>
#import <FireflyDevice/FDFileLog.h>
#import <FireflyDevice/FDSyncTask.h>
#import <FireflyDevice/FDHardwareId.h>

@interface FDViewController () <FDPickSceneDelegate, FDPlaySceneDelegate, FDFireflyIceManagerDelegate, FDSyncTaskDelegate>

@property id<FDFireflyDeviceLog> log;

@property FDPickScene *pickScene;
@property FDPlayScene *playScene;

@property FDFireflyIce *indicating;
@property NSString *syncIdentifier;
@property NSUInteger syncVmaCount;
@property double syncVmaTotal;

@property NSMutableArray *fireflyIces;

@end

@implementation FDViewController

- (SKView *)view
{
    NSArray *subviews = _subviews;
    return subviews.firstObject;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    SKView *skView = (SKView *)self.view;
//    skView.showsFPS = YES;
//    skView.showsNodeCount = YES;
    
    _pickScene = [FDPickScene sceneWithSize:skView.bounds.size];
    _pickScene.scaleMode = SKSceneScaleModeAspectFill;
    _pickScene.delegate = self;
    
    _playScene = [FDPlayScene sceneWithSize:skView.bounds.size];
    _playScene.scaleMode = SKSceneScaleModeAspectFill;
    _playScene.delegate = self;
    
    _fireflyIces = [NSMutableArray array];
    
    _fireflyIceManager = [FDFireflyIceManager manager];
    _fireflyIceManager.delegate = self;
    _fireflyIceManager.active = YES;
    
    [self showPickScene];
}

- (FDFireflyIce *)fireflyIceForHardwareId:(NSString *)hardwareId
{
    for (FDFireflyIce *fireflyIce in _fireflyIces) {
        if ([hardwareId isEqualToString:[FDHardwareId hardwareId:fireflyIce.hardwareId.unique]]) {
            return fireflyIce;
        }
    }
    return nil;
}

- (void)showPickScene
{
    SKView *skView = (SKView *)self.view;
    SKTransition *doors = [SKTransition doorsOpenVerticalWithDuration:0.5];
    [skView presentScene:_pickScene transition:doors];
    _fireflyIceManager.discovery = YES;
}

- (void)showPlayScene:(FDFireflyIce *)fireflyIce
{
    _fireflyIceManager.discovery = NO;
    
    _playScene.fireflyIce = fireflyIce;
    SKView *skView = (SKView *)self.view;
    SKTransition *doors = [SKTransition doorsOpenVerticalWithDuration:0.5];
    [skView presentScene:_playScene transition:doors];
}

- (void)pickSceneIndicate:(FDPickScene *)pickScene fireflyIce:(FDFireflyIce *)fireflyIce
{
    if (_indicating != nil) {
//        [_fireflyIceManager indicate:_indicating show:NO];
    }
    _indicating = fireflyIce;
    if (_indicating != nil) {
//        [_fireflyIceManager indicate:_indicating show:YES];
    }
}

- (void)pickSceneChoose:(FDPickScene *)pickScene fireflyIce:(FDFireflyIce *)fireflyIce
{
    if (_indicating != nil) {
//        [_fireflyIceManager indicate:_indicating show:NO];
    }
    [self showPlayScene:fireflyIce];
    
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    [channel open];
}

- (void)playSceneDone:(FDPlayScene *)playScene
{
    FDFireflyIceChannelBLE *channel = _playScene.fireflyIce.channels[@"BLE"];
    [channel close];
    _playScene.fireflyIce = nil;
    [self showPickScene];
}

- (void)playSceneSync:(FDPlayScene *)playScene
{
    FDFireflyIce *fireflyIce = _playScene.fireflyIce;
    FDFireflyIceChannelBLE *channel = fireflyIce.channels[@"BLE"];
    NSString *identifier = [channel.peripheral.identifier UUIDString];
    
    _syncIdentifier = [[NSUUID UUID] UUIDString];
    _syncVmaCount = 0;
    _syncVmaTotal = 0.0;
    FDSyncTask *syncTask = [FDSyncTask syncTask:identifier fireflyIce:fireflyIce channel:channel delegate:self identifier:_syncIdentifier];
    [fireflyIce.executor execute:syncTask];
}

- (void)fireflyIceManager:(FDFireflyIceManager *)manager discovered:(FDFireflyIce *)fireflyIce
{
    if (![_fireflyIces containsObject:fireflyIce]) {
        [_fireflyIces addObject:fireflyIce];
    }
    [_pickScene updateDevices:_fireflyIces];
}

- (void)syncTaskActive:(FDSyncTask *)syncTask
{
    FDFireflyDeviceLogInfo(@"sync active (hardwareId=%@ identifier=%@)", syncTask.hardwareId, syncTask.identifier);
}

- (void)syncTaskInactive:(FDSyncTask *)syncTask
{
    FDFireflyDeviceLogInfo(@"sync inactive (hardwareId=%@ identifier=%@)", syncTask.hardwareId, syncTask.identifier);
}

- (void)syncTask:(FDSyncTask *)syncTask site:(NSString *)site hardwareId:(NSString *)hardwareId time:(NSTimeInterval)time interval:(NSTimeInterval)interval vmas:(NSArray *)vmas backlog:(NSUInteger)backlog
{
    for (NSNumber *vma in vmas) {
        ++_syncVmaCount;
        _syncVmaTotal += vma.doubleValue;
    }
}

- (void)syncTask:(FDSyncTask *)syncTask progress:(float)progress
{
    FDFireflyDeviceLogInfo(@"sync progress (hardwareId=%@ identifier=%@)", syncTask.hardwareId, syncTask.identifier);
    if ([syncTask.identifier isEqualToString:_syncIdentifier]) {
        [_playScene syncProgress:progress];
    }
}

- (void)syncTaskComplete:(FDSyncTask *)syncTask
{
    FDFireflyDeviceLogInfo(@"sync complete (hardwareId=%@ identifier=%@ lastDataDate=%@)", syncTask.hardwareId, syncTask.identifier, syncTask.lastDataDate);
    if ([syncTask.identifier isEqualToString:_syncIdentifier]) {
        NSUInteger points = 0;
        if (_syncVmaCount > 0) {
            points = (NSUInteger)(10.0 * _syncVmaTotal / _syncVmaCount);
        }
        [_playScene syncComplete:points];
        _syncIdentifier = nil;
    }
}

- (void)syncTask:(FDSyncTask *)syncTask error:(NSError *)error
{
    FDFireflyDeviceLogInfo(@"sync error (hardwareId=%@ identifier=%@ error=%@)", syncTask.hardwareId, syncTask.identifier, error);
    if ([syncTask.identifier isEqualToString:_syncIdentifier]) {
        [_playScene syncError:error];
    }
}

@end
