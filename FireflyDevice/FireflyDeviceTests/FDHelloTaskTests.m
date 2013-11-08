//
//  FireflyDeviceTests.m
//  FireflyDeviceTests
//
//  Created by Denis Bohm on 10/13/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDHelloTask.h"

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

@interface FDHelloTask (ExposePrivateMethodsUsedForTesting)

- (void)checkTime;

@end

@interface FDHelloTaskTests : XCTestCase

@end

@implementation FDHelloTaskTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCloseChannelOnMissingProperties
{
    FDHelloTask *helloTask = [[FDHelloTask alloc] init];
    id channel = [OCMockObject mockForProtocol:@protocol(FDFireflyIceChannel)];
    [[channel expect] close];
    helloTask.channel = channel;
    
    [helloTask checkTime];
    
    [channel verify];
}

@end
