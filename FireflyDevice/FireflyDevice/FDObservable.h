//
//  FDObservable.h
//  FireflyDevice
//
//  Created by Denis Bohm on 7/28/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FDFireflyDeviceLog;

@interface FDObservable : NSObject

- (id)init:(Protocol *)protocol;

- (void)addObserver:(id)observer;
- (void)removeObserver:(id)observer;

@property id<FDFireflyDeviceLog> log;

@end
