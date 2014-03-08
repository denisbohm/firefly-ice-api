//
//  FDPlayScene.h
//  FireflyGame
//
//  Created by Denis Bohm on 10/21/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import <FireflyDevice/FDFireflyIce.h>

@class FDPlayScene;

@protocol FDPlaySceneDelegate <NSObject>

- (void)playSceneDone:(FDPlayScene *)playScene;

- (void)playSceneSync:(FDPlayScene *)playScene;

@end

@interface FDPlayScene : SKScene

@property id<FDPlaySceneDelegate> delegate;

@property FDFireflyIce *fireflyIce;

- (void)syncProgress:(double)progress;
- (void)syncComplete:(NSUInteger)points;
- (void)syncError:(NSError *)error;
- (void)syncAbort:(NSError *)error;

@end
