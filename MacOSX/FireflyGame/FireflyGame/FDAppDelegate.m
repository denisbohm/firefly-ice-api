//
//  FDAppDelegate.m
//  FireflyGame
//
//  Created by Denis Bohm on 3/5/14.
//  Copyright (c) 2014 Firefly Design LLC. All rights reserved.
//

#import "FDAppDelegate.h"

@implementation FDAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _window.acceptsMouseMovedEvents = YES;
    [_window makeFirstResponder:self.skView.scene];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
