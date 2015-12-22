//
//  FDFireflyIceService.h
//  FireflyDevice
//
//  Created by Denis Bohm on 12/21/15.
//  Copyright © 2015 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FDFireflyIceService;

@protocol FDFireflyIceServiceDelegate <NSObject>

- (void)fireflyIceService:(FDFireflyIceService *)service connectionAccepted:(NSFileHandle *)handle;

@end

@interface FDFireflyIceService : NSObject

@property id<FDFireflyIceServiceDelegate> delegate;

- (BOOL)publish;

@end
