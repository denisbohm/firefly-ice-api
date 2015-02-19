//
//  FDJSON.m
//  FireflyDevice
//
//  Created by Denis Bohm on 1/15/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import "FDJSON.h"

@interface FDJSONSerializerContext : NSObject
@property NSInteger count;
@end

@implementation FDJSONSerializerContext
@end

@interface FDJSONSerializer ()

@property NSMutableString *string;
@property NSMutableArray *contexts;

@end

@implementation FDJSONSerializer

- (id)init
{
    if (self = [super init]) {
        self.string = [NSMutableString string];
        self.contexts = [NSMutableArray array];
    }
    return self;
}

+ (NSData *)serialize:(id)object
{
    FDJSONSerializer *serializer = [[FDJSONSerializer alloc] init];
    [serializer value:object];
    return [serializer.string dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)objectBegin
{
    [self.contexts addObject:[[FDJSONSerializerContext alloc] init]];
    [self.string appendString:@"{"];
}

- (void)next
{
    FDJSONSerializerContext *context = self.contexts.lastObject;
    if (context.count > 0) {
        [self.string appendString:@","];
    }
    ++context.count;
}

- (void)objectValue:(id)value key:(NSString *)key
{
    [self next];
    [self string:key];
    [self.string appendString:@":"];
    [self value:value];
}

- (void)objectNumber:(double)value key:(NSString *)key
{
    [self next];
    [self string:key];
    [self.string appendString:@":"];
    [self number:value];
}

- (void)objectBoolean:(BOOL)value key:(NSString *)key
{
    [self next];
    [self string:key];
    [self.string appendString:@":"];
    [self boolean:value];
}

- (void)objectEnd
{
    [self.contexts removeLastObject];
    [self.string appendString:@"}"];
}

- (void)arrayBegin
{
    [self.contexts addObject:[[FDJSONSerializerContext alloc] init]];
    [self.string appendString:@"["];
}

- (void)arrayValue:(id)value
{
    [self next];
    [self value:value];
}

- (void)arrayNumber:(double)value
{
    [self next];
    [self number:value];
}

- (void)arrayBoolean:(BOOL)value
{
    [self next];
    [self boolean:value];
}

- (void)arrayEnd
{
    [self.contexts removeLastObject];
    [self.string appendString:@"]"];
}

- (void)string:(NSString *)value
{
    [self.string appendString:@"\""];
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t *bytes = (uint8_t *)data.bytes;
    for (NSInteger i = 0; i < data.length; ++i) {
        uint8_t c = bytes[i];
        switch (c) {
            case '\\':
                [self.string appendString:@"\\\\"];
                break;
            case '\"':
                [self.string appendString:@"\\\""];
                break;
            case '/':
                [self.string appendString:@"\\/"];
                break;
            case '\b':
                [self.string appendString:@"\\b"];
                break;
            case '\f':
                [self.string appendString:@"\\f"];
                break;
            case '\n':
                [self.string appendString:@"\\n"];
                break;
            case '\r':
                [self.string appendString:@"\\r"];
                break;
            case '\t':
                [self.string appendString:@"\\t"];
                break;
            default:
                [self.string appendFormat:@"%c", c];
                break;
        }
    }
    [self.string appendString:@"\""];
}

- (void)number:(double)value
{
    int32_t valueUInt32 = (int32_t)value;
    if (value == valueUInt32) {
        [self.string appendFormat:@"%d", valueUInt32];
    } else {
        [self.string appendFormat:@"%f", value];
    }
}

- (void)boolean:(BOOL)value
{
    [self.string appendString:value ? @"true" : @"false"];
}

- (void)null
{
    [self.string appendString:@"null"];
}

- (void)dictionary:(NSDictionary *)dictionary
{
    [self objectBegin];
    for (NSString *key in dictionary.allKeys) {
        id value = dictionary[key];
        [self objectValue:value key:key];
    }
    [self objectEnd];
}

- (void)array:(NSArray *)array
{
    [self arrayBegin];
    for (id value in array) {
        [self arrayValue:value];
    }
    [self arrayEnd];
}

- (void)value:(id)object
{
    if (object == nil) {
        [self null];
    } else
    if (object == (id)kCFBooleanTrue) {
        [self boolean:YES];
    } else
    if (object == (id)kCFBooleanFalse) {
        [self boolean:NO];
    } else
    if ([object isKindOfClass:[NSDictionary class]]) {
        [self dictionary:(NSDictionary *)object];
    } else
    if ([object isKindOfClass:[NSArray class]]) {
        [self array:(NSArray *)object];
    } else
    if ([object isKindOfClass:[NSString class]]) {
        [self string:(NSString *)object];
    } else
    if ([object isKindOfClass:[NSNumber class]]) {
        [self number:[((NSNumber *)object) doubleValue]];
    } else
    if ([[object class] conformsToProtocol:@protocol(FDJSONSerializable)]) {
        id<FDJSONSerializable> serializable = object;
        [serializable serialize:self];
    } else {
        @throw [NSException exceptionWithName:@"ObjectIsNotSerializable" reason:[NSString stringWithFormat:@"object is not serializable: %@", NSStringFromClass([object class])] userInfo:nil];
    }
}

@end

@implementation FDJSON

+ (NSDictionary *)JSONObjectWithData:(NSData *)data
{
    if (NSClassFromString(@"NSJSONSerialization")) {
        return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }

    // BSJSON fallback for old OS
    if ([[NSDictionary class] respondsToSelector:NSSelectorFromString(@"dictionaryWithJSONString:")]) {
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSDictionary *dictionary = [[NSDictionary class] performSelector:NSSelectorFromString(@"dictionaryWithJSONString:") withObject:string];
#pragma clang diagnostic pop
        return dictionary;
    }
    
    @throw [NSException exceptionWithName:@"JSON_NOT_SUPPORTED" reason:@"no JSON support found" userInfo:nil];
}

+ (NSData *)dataWithJSONObject:(id)object
{
    if (NSClassFromString(@"NSJSONSerialization")) {
        return [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
    }

    // BSJSON fallback for old OS
    if ([object respondsToSelector:NSSelectorFromString(@"jsonStringValue")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSString *string = [object performSelector:NSSelectorFromString(@"jsonStringValue")];
#pragma clang diagnostic pop
        return [string dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    @throw [NSException exceptionWithName:@"JSON_NOT_SUPPORTED" reason:@"no JSON support found" userInfo:nil];
}

@end
