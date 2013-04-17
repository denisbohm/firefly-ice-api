//
//  FDDetour.h
//  Sync
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    FDDetourStateClear,
    FDDetourStateIntermediate,
    FDDetourStateSuccess,
    FDDetourStateError
} FDDetourState;

@interface FDDetour : NSObject

@property(readonly) FDDetourState state;
@property(readonly) NSData *data;

- (id)init;
- (void)clear;
- (void)detourEvent:(NSData *)data;

@end
