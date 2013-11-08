//
//  FDFireflyIceChannelBLETests.m
//  FireflyDevice
//
//  Created by Denis Bohm on 11/7/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIceChannelBLE.h"

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

@interface FDFireflyIceChannelBLE (ExposePrivateMethodsUsedForTesting)

- (void)didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

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
    FDFireflyIceChannelBLE *channel = [[FDFireflyIceChannelBLE alloc] initWithCentralManager:nil withPeripheral:nil];

    NilFireflyIceChannelDelegate *delegate = [[NilFireflyIceChannelDelegate alloc] init];
    channel.delegate = delegate;
    
    id characteristic = [OCMockObject mockForClass:[CBCharacteristic class]];
    NSData *data = [NSData data];
    [(CBCharacteristic *)[[characteristic expect] andReturn:data] value];
    
    [channel didUpdateValueForCharacteristic:characteristic error:nil];
    
    [characteristic verify];
}

@end
