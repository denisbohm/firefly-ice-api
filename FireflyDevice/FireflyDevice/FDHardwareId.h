//
//  FDHardwareId.h
//  FireflyDevice
//
//  Created by Denis Bohm on 3/2/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDHardwareId : NSObject

+ (NSString *)hardwareId:(NSData *)unique;

@end
