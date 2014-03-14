//
//  FDIEEE754Tests.m
//  FireflyDevice
//
//  Created by Denis Bohm on 12/10/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import "FDIEEE754.h"

#import <XCTest/XCTest.h>

@interface FDIEEE754Tests : XCTestCase

@end

@implementation FDIEEE754Tests

- (void)testConversion
{
    uint16_t bits = [FDIEEE754 floatToUint16:2.25];
    float value = [FDIEEE754 uint16ToFloat:bits];
    XCTAssertTrue(2.25 == value);
}

@end
