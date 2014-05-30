//
//  FDJSON.m
//  FireflyDevice
//
//  Created by Denis Bohm on 1/15/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDJSON.h>

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
