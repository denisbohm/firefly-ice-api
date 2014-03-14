//
//  FDIEEE754.h
//  FireflyDevice
//
//  Created by Denis Bohm on 12/8/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDIEEE754 : NSObject

+ (uint16_t)floatToUint16:(float)value;
+ (float)uint16ToFloat:(uint16_t)value;

@end
