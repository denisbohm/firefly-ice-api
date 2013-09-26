//
//  FDCrypto.h
//  FireflyProduction
//
//  Created by Denis Bohm on 9/15/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDCrypto : NSObject

+ (NSData *)sha1:(NSData *)data;

// AES-128 hash (result is last 20 bytes of encoding the data)
+ (NSData *)hash:(NSData *)key iv:(NSData *)iv data:(NSData *)data;
+ (NSData *)hash:(NSData *)data;

@end
