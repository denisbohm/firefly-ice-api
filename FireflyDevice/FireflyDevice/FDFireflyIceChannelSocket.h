//
//  FDFireflyIceChannelSocket.h
//  FireflyDevice
//
//  Created by Denis Bohm on 12/19/15.
//  Copyright © 2015 Firefly Design. All rights reserved.
//

#import <FireflyDevice/FDFireflyIceChannel.h>

@interface FDFireflyIceChannelSocket : NSObject <FDFireflyIceChannel>

@property id<FDFireflyIceChannelDelegate> delegate;

- (id)initWithAddress:(NSString *)address port:(int)port;

@end
