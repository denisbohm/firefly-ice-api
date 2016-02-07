//
//  FDVMADecoder.h
//  FireflyDevice
//
//  Created by Denis Bohm on 5/8/15.
//  Copyright (c) 2015 Firefly Design. All rights reserved.
//

#import <FireflyDevice/FDPullTask.h>

@interface FDVMAItem : NSObject
@property NSTimeInterval time;
@property uint16_t interval;
@property NSArray *vmas;
@end

@interface FDVMADecoder : NSObject <FDPullTaskDecoder>

@property id<FDFireflyDeviceLog> log;

@end
