//
//  FDJSON.h
//  FireflyDevice
//
//  Created by Denis Bohm on 1/15/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDJSON : NSObject

+ (NSDictionary *)JSONObjectWithData:(NSData *)data;
+ (NSData *)dataWithJSONObject:(id)object;

@end
