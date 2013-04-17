//
//  FDBinary.h
//  Sync
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDBinary : NSObject

- (id)initWithData:(NSData *)data;

- (NSData *)getRemainingData;
- (uint8_t)getUint8;
- (uint16_t)getUint16;
- (uint32_t)getUint32;
- (uint64_t)getUint64;
- (float)getFloat32;
- (NSTimeInterval)getTime;

@end
