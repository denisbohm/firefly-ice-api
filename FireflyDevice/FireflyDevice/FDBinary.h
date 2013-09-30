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
- (float)getFloat32;
- (NSTimeInterval)getTime64;

- (void)putData:(NSData *)data;
- (void)putUInt8:(uint8_t)value;
- (void)putUInt16:(uint16_t)value;
- (void)putUInt32:(uint32_t)value;
- (void)putUInt64:(uint64_t)value;
- (void)putFloat32:(float)value;
-(void)putTime64:(NSTimeInterval)value;

@end
