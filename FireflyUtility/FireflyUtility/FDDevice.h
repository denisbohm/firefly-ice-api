//
//  FDDevice.h
//  FireflyUtility
//
//  Created by Denis Bohm on 9/25/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <FireflyDevice/FDFireflyIce.h>

#import "FDFireflyIceCollector.h"

#import <Foundation/Foundation.h>

@interface FDDevice : NSObject

@property FDFireflyIce *fireflyIce;
@property FDFireflyIceCollector *collector;

@end
