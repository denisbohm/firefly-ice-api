//
//  FDViewController.h
//  FireflyGame
//

//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>

#import <FireflyDevice/FDFireflyIceManager.h>

@class FDFileLog;

@interface FDViewController : UIViewController

@property FDFileLog *fileLog;
@property FDFireflyIceManager *fireflyIceManager;

@end
