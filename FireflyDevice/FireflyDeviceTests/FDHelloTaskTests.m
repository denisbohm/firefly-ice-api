//
//  FireflyDeviceTests.m
//  FireflyDevice
//
//  Created by Denis Bohm on 10/13/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDHelloTask.h>

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

@interface FDHelloTask (ExposePrivateMethodsUsedForTesting)

- (void)checkVersion;

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
    
    [helloTask checkVersion];
    
    [channel verify];
}

@end
