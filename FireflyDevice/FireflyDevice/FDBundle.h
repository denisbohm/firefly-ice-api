//
//  FDBundle.h
//  FireflyDevice
//
//  Created by Denis Bohm on 2/14/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FDBundleInfo <NSObject>

- (NSDictionary *)infoDictionary;

@end

@interface FDBundle : NSObject <FDBundleInfo>

@end
