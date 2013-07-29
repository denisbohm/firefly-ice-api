//
//  FDObservable.h
//  Sync
//
//  Created by Denis Bohm on 7/28/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDObservable : NSObject

- (id)init:(Protocol *)protocol;

- (void)addObserver:(id)observer;
- (void)removeObserver:(id)observer;

@end
