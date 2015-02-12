//
//  FDGZIP.h
//  FireflyDevice
//
//  Created by Denis Bohm on 2/10/15.
//  Copyright (c) 2015 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDGZIP : NSObject

+ (NSData *)compress:(NSData *)data;
+ (NSData *)decompress:(NSData *)data;

@end
