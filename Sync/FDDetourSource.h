//
//  FDDetourSource.h
//  Sync
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDDetourSource : NSObject

- (id)initWithSize:(NSUInteger)size data:(NSData *)data;

- (NSData *)next;

@end
