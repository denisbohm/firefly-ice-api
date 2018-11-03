//
//  FDCobsTests.m
//  FireflyDeviceTests
//
//  Created by Denis Bohm on 11/2/18.
//  Copyright © 2018 Firefly Design. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "FDCobs.h"

@interface FDCobsTests : XCTestCase

@end

@implementation FDCobsTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)encodeDecode:(uint8_t *)src_bytes length:(size_t)src_length {
    NSData *srcData = [NSData dataWithBytes:src_bytes length:src_length];
    NSData *encodedData = [FDCobs encode:srcData];
    NSData *decodedData = [FDCobs decode:encodedData];
    XCTAssert([srcData isEqualToData:decodedData]);
}

- (void)testExamples {
    uint8_t example1[] = {0x00};
    [self encodeDecode:example1 length:sizeof(example1)];
    
    uint8_t example2[] = {0x00, 0x00};
    [self encodeDecode:example2 length:sizeof(example2)];
    
    uint8_t example3[] = {0x11, 0x22, 0x00, 0x33};
    [self encodeDecode:example3 length:sizeof(example3)];
    
    uint8_t example4[] = {0x11, 0x22, 0x33, 0x44};
    [self encodeDecode:example4 length:sizeof(example4)];
    
    uint8_t example5[] = {0x11, 0x00, 0x00, 0x00};
    [self encodeDecode:example5 length:sizeof(example5)];
}

@end
