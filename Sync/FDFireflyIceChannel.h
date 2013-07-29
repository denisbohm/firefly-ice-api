//
//  FDFireflyIceChannel.h
//  Sync
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FDFireflyIceChannel;

@protocol FDFireflyIceChannelDelegate <NSObject>

@optional

- (void)fireflyIceChannelOpen:(id<FDFireflyIceChannel>)channel;
- (void)fireflyIceChannelPacket:(id<FDFireflyIceChannel>)channel data:(NSData *)data;

@end

@protocol FDFireflyIceChannel <NSObject>

- (void)fireflyIceChannelSend:(NSData *)data;

@end
