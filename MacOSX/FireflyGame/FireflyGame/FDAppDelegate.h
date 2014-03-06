//
//  FDAppDelegate.h
//  FireflyGame
//

//  Copyright (c) 2014 Firefly Design LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SpriteKit/SpriteKit.h>

@interface FDAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet SKView *skView;

@end
