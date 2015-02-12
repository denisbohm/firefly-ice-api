//
//  FDJSON.h
//  FireflyDevice
//
//  Created by Denis Bohm on 1/15/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FDJSONSerializer;

@protocol FDJSONSerializable

- (void)serialize:(FDJSONSerializer *)serializer;

@end

@interface FDJSONSerializer : NSObject

+ (NSData *)serialize:(id)object;

- (void)value:(id)object;
- (void)numberUInt32:(uint32_t)value;
- (void)number:(double)value;
- (void)boolean:(BOOL)value;

- (void)objectBegin;
- (void)objectValue:(id)value key:(NSString *)key;
- (void)objectNumberUInt32:(uint32_t)value key:(NSString *)key;
- (void)objectNumber:(double)value key:(NSString *)key;
- (void)objectBoolean:(BOOL)value key:(NSString *)key;
- (void)objectEnd;

- (void)arrayBegin;
- (void)arrayValue:(id)value;
- (void)arrayNumberUInt32:(uint32_t)value;
- (void)arrayNumber:(double)value;
- (void)arrayBoolean:(BOOL)value;
- (void)arrayEnd;

@end

@interface FDJSON : NSObject

+ (NSDictionary *)JSONObjectWithData:(NSData *)data;
+ (NSData *)dataWithJSONObject:(id)object;

@end
