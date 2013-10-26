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

typedef enum {FDFireflyIceChannelStatusClosed, FDFireflyIceChannelStatusOpening, FDFireflyIceChannelStatusOpen} FDFireflyIceChannelStatus;

@optional

- (void)fireflyIceChannel:(id<FDFireflyIceChannel>)channel status:(FDFireflyIceChannelStatus)status;

- (void)fireflyIceChannelPacket:(id<FDFireflyIceChannel>)channel data:(NSData *)data;

@end

@protocol FDFireflyIceChannel <NSObject>

@property id<FDFireflyIceChannelDelegate> delegate;

@property(readonly) FDFireflyIceChannelStatus status;

- (void)fireflyIceChannelSend:(NSData *)data;

@end
