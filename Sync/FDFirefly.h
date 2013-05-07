//
//  FDFirefly.h
//  Sync
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FDFirefly;

@protocol FDFireflyDelegate <NSObject>

- (void)fireflyPacket:(id<FDFirefly>)firefly data:(NSData *)data;

@end

@protocol FDFirefly <NSObject>

- (void)send:(NSData *)data;

@end

#define FD_SYNC_START 1
#define FD_SYNC_DATA 2
#define FD_SYNC_ACK 3