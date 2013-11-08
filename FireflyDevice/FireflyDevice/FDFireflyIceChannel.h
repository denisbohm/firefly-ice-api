//
//  FDFireflyIceChannel.h
//  Sync
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FDDetour;
@protocol FDFireflyIceChannel;

typedef enum {FDFireflyIceChannelStatusClosed, FDFireflyIceChannelStatusOpening, FDFireflyIceChannelStatusOpen} FDFireflyIceChannelStatus;

@protocol FDFireflyIceChannelDelegate <NSObject>

@optional

- (void)fireflyIceChannel:(id<FDFireflyIceChannel>)channel status:(FDFireflyIceChannelStatus)status;

- (void)fireflyIceChannelPacket:(id<FDFireflyIceChannel>)channel data:(NSData *)data;

- (void)fireflyIceChannel:(id<FDFireflyIceChannel>)channel detour:(FDDetour *)detour error:(NSError *)error;

@end

@protocol FDFireflyIceChannel <NSObject>

@property(readonly) NSString *name;

@property id<FDFireflyIceChannelDelegate> delegate;

@property(readonly) FDFireflyIceChannelStatus status;

- (void)fireflyIceChannelSend:(NSData *)data;

- (void)open;
- (void)close;

@end
