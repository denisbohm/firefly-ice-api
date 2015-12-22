//
//  FDFireflyIceServiceBrowser.h
//  FireflyDevice
//
//  Created by Denis Bohm on 12/21/15.
//  Copyright © 2015 Firefly Design. All rights reserved.
//

#import <FireflyDevice/FDFireflyIce.h>

@class FDFireflyIceServiceBrowser;

@protocol FDFireflyIceServiceBrowserDelegate <NSObject>

- (void)fireflyIceServiceBrowser:(FDFireflyIceServiceBrowser *)browser discovered:(FDFireflyIce *)fireflyIce;
- (void)fireflyIceServiceBrowser:(FDFireflyIceServiceBrowser *)browser removed:(FDFireflyIce *)fireflyIce;

@end

@interface FDFireflyIceServiceBrowser : NSObject

@property id<FDFireflyIceServiceBrowserDelegate> delegate;

- (void)scan;

@end
