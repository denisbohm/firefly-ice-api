//
//  FDBinary.h
//  FireflyDevice
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDBinary : NSObject

- (nonnull id)init;
- (nonnull id)initWithData:(nonnull NSData *)data;

- (NSUInteger)length;
- (nonnull NSData *)dataValue;

@property uint32_t getIndex;
- (NSUInteger)getRemainingLength;
- (nonnull NSData *)getRemainingData;
- (nonnull NSData *)getData:(NSUInteger)length;
- (uint8_t)getUInt8;
- (uint16_t)getUInt16;
- (uint32_t)getUInt24;
- (uint32_t)getUInt32;
- (uint64_t)getUInt64;
- (float)getFloat16;
- (float)getFloat32;
- (NSTimeInterval)getTime64;

- (void)putData:(nonnull NSData *)data;
- (void)putUInt8:(uint8_t)value;
- (void)putUInt16:(uint16_t)value;
- (void)putUInt24:(uint32_t)value;
- (void)putUInt32:(uint32_t)value;
- (void)putUInt64:(uint64_t)value;
- (void)putFloat16:(float)value;
- (void)putFloat32:(float)value;
- (void)putTime64:(NSTimeInterval)value;

+ (uint8_t)unpackUInt8:(nonnull uint8_t *)buffer;
+ (uint16_t)unpackUInt16:(nonnull uint8_t *)buffer;
+ (uint32_t)unpackUInt24:(nonnull uint8_t *)buffer;
+ (uint32_t)unpackUInt32:(nonnull uint8_t *)buffer;
+ (uint64_t)unpackUInt64:(nonnull uint8_t *)buffer;
+ (float)unpackFloat16:(nonnull uint8_t *)buffer;
+ (float)unpackFloat32:(nonnull uint8_t *)buffer;
+ (NSTimeInterval)unpackTime64:(nonnull uint8_t *)buffer;

+ (void)packUInt8:(nonnull uint8_t *)buffer value:(uint8_t)value;
+ (void)packUInt16:(nonnull uint8_t *)buffer value:(uint16_t)value;
+ (void)packUInt24:(nonnull uint8_t *)buffer value:(uint32_t)value;
+ (void)packUInt32:(nonnull uint8_t *)buffer value:(uint32_t)value;
+ (void)packUInt64:(nonnull uint8_t *)buffer value:(uint64_t)value;
+ (void)packFloat16:(nonnull uint8_t *)buffer value:(float)value;
+ (void)packFloat32:(nonnull uint8_t *)buffer value:(float)value;
+ (void)packTime64:(nonnull uint8_t *)buffer value:(NSTimeInterval)value;

@end
