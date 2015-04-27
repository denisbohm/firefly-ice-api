//
//  FDCryptoTest.m
//  FireflyDevice
//
//  Created by Denis Bohm on 4/27/15.
//  Copyright (c) 2015 Firefly Design. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "FDCrypto.h"

@interface FDCryptoTest : XCTestCase

@end

@implementation FDCryptoTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSha1 {
    uint8_t inputBytes[] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0f};
    NSData *input = [NSData dataWithBytes:inputBytes length:sizeof(inputBytes)];
    NSData *actual = [FDCrypto sha1:input];
    uint8_t expectedBytes[] = {0xd4, 0x8a, 0xa2, 0x4e, 0x9f, 0xee, 0x0d, 0xe3, 0x40, 0xea, 0x7c, 0xd5, 0x13, 0x88, 0x6e, 0xf6, 0xe3, 0x20, 0xe9, 0x09};
    NSData *expected = [NSData dataWithBytes:expectedBytes length:sizeof(expectedBytes)];
    XCTAssert([actual isEqualToData:expected]);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
