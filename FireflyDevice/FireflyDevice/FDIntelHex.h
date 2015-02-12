//
//  FDIntelHex.h
//  FireflyDevice
//
//  Created by Denis Bohm on 9/18/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDIntelHex : NSObject

+ (FDIntelHex *)intelHex:(NSString *)hex address:(uint32_t)address length:(uint32_t)length;
+ (NSData *)parse:(NSString *)hex address:(uint32_t)address length:(uint32_t)length;

- (NSString *)format;

@property NSData *data;
@property NSMutableDictionary *properties;

@end
