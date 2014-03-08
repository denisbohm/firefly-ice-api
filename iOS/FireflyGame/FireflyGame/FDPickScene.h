//
//  FDPickScene.h
//  FireflyGame
//

//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import <FireflyDevice/FDFireflyIce.h>

@class FDPickScene;

@protocol FDPickSceneDelegate <NSObject>

- (void)pickSceneIndicate:(FDPickScene *)pickScene fireflyIce:(FDFireflyIce *)fireflyIce;
- (void)pickSceneChoose:(FDPickScene *)pickScene fireflyIce:(FDFireflyIce *)fireflyIce;

@end

@interface FDPickScene : SKScene

@property id<FDPickSceneDelegate> delegate;

- (void)updateDevices:(NSArray *)fireflyIces;

@end
