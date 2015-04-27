//
//  FDIntelHex.h
//  FireflyDevice
//
//  Created by Denis Bohm on 9/18/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDIntelHexChunk : NSObject

+ (FDIntelHexChunk *)chunk:(uint32_t)address data:(NSData *)data;
+ (FDIntelHexChunk *)chunk:(uint32_t)address bytes:(uint8_t *)bytes length:(uint32_t)length;

@property uint32_t address;
@property NSData *data;

@end

@interface FDIntelHex : NSObject

+ (FDIntelHex *)intelHex:(NSString *)hex address:(uint32_t)address length:(uint32_t)length;
+ (NSData *)parse:(NSString *)hex address:(uint32_t)address length:(uint32_t)length;

- (NSString *)format:(NSArray *)chunks comment:(BOOL)comment;
- (NSString *)format;

@property NSData *data;
@property NSMutableDictionary *properties;

@end
