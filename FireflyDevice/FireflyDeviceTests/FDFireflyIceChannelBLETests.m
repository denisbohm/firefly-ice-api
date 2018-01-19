//
//  FDFireflyIceChannelBLETests.m
//  FireflyDevice
//
//  Created by Denis Bohm on 11/7/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDFireflyIceChannelBLE.h>

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import <CoreBluetooth/CoreBluetooth.h>

@interface FDFireflyIceChannelBLE (ExposePrivateMethodsUsedForTesting)

- (void)didUpdateValueForCharacteristic:(NSData *)data error:(NSError *)error;

@end

@interface NilFireflyIceChannelDelegate : NSObject <FDFireflyIceChannelDelegate>
@end

@implementation NilFireflyIceChannelDelegate
@end

@interface FDFireflyIceChannelBLETests : XCTestCase

@end

@implementation FDFireflyIceChannelBLETests

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

- (void)testOptionalDelegateMethods
{
    FDFireflyIceChannelBLE *channel = [[FDFireflyIceChannelBLE alloc] initWithCentralManager:nil withPeripheral:nil withServiceUUID:[CBUUID UUIDWithString:@"310a0001-1b95-5091-b0bd-b7a681846399"]];

    NilFireflyIceChannelDelegate *delegate = [[NilFireflyIceChannelDelegate alloc] init];
    channel.delegate = delegate;
    
    NSData *data = [NSData data];
    
    [channel didUpdateValueForCharacteristic:data error:nil];
}

@end
