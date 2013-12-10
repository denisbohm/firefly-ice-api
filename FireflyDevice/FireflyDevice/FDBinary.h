//
//  FDBinary.h
//  Sync
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDBinary : NSObject

- (id)init;
- (id)initWithData:(NSData *)data;

- (NSUInteger)length;
- (NSData *)dataValue;

- (NSUInteger)getRemainingLength;
- (NSData *)getRemainingData;
- (NSData *)getData:(NSUInteger)length;
- (uint8_t)getUInt8;
- (uint16_t)getUInt16;
- (uint32_t)getUInt32;
- (uint64_t)getUInt64;
- (float)getFloat16;
- (float)getFloat32;
- (NSTimeInterval)getTime64;

- (void)putData:(NSData *)data;
- (void)putUInt8:(uint8_t)value;
- (void)putUInt16:(uint16_t)value;
- (void)putUInt32:(uint32_t)value;
- (void)putUInt64:(uint64_t)value;
- (void)putFloat16:(float)value;
- (void)putFloat32:(float)value;
- (void)putTime64:(NSTimeInterval)value;

+ (uint8_t)unpackUInt8:(uint8_t *)buffer;
+ (uint16_t)unpackUInt16:(uint8_t *)buffer;
+ (uint32_t)unpackUInt32:(uint8_t *)buffer;
+ (uint64_t)unpackUInt64:(uint8_t *)buffer;
+ (float)unpackFloat16:(uint8_t *)buffer;
+ (float)unpackFloat32:(uint8_t *)buffer;
+ (NSTimeInterval)unpackTime64:(uint8_t *)buffer;

+ (void)packUInt8:(uint8_t *)buffer value:(uint8_t)value;
+ (void)packUInt16:(uint8_t *)buffer value:(uint16_t)value;
+ (void)packUInt32:(uint8_t *)buffer value:(uint32_t)value;
+ (void)packUInt64:(uint8_t *)buffer value:(uint64_t)value;
+ (void)packFloat16:(uint8_t *)buffer value:(float)value;
+ (void)packFloat32:(uint8_t *)buffer value:(float)value;
+ (void)packTime64:(uint8_t *)buffer value:(NSTimeInterval)value;

@end
