//
//  FDHelpController.h
//  FireflyUtility
//
//  Created by Denis Bohm on 2/19/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FDHelpController;

@protocol FDHelpControllerDelegate <NSObject>

- (UIView *)helpControllerHelpView:(FDHelpController *)helpController;

@end

@interface FDHelpController : NSObject

@property id<FDHelpControllerDelegate> delegate;
@property UIView *parentView;

- (UIBarButtonItem *)makeBarButtonItem;

- (void)showHelpOverlay;
- (void)hideHelpOverlay;
- (void)toggleHelpOverlay;
- (void)autoShowHelp:(NSString *)name;

@end
