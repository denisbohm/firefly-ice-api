//
//  FDCobs.h
//  FireflyDevice
//
//  Created by Denis Bohm on 11/2/18.
//  Copyright © 2018 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FDCobs : NSObject

+ (NSData *)encode:(NSData *)src;
+ (NSData *)decode:(NSData *)src;

@end

NS_ASSUME_NONNULL_END
