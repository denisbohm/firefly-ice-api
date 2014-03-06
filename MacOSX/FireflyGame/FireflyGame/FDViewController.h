//
//  FDViewController.h
//  FireflyGame
//

//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import <FireflyDevice/FDFireflyIceManager.h>

@class FDFileLog;

@interface FDViewController : NSView

@property FDFileLog *fileLog;
@property FDFireflyIceManager *fireflyIceManager;

@end
