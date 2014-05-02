//
//  FDSyncTaskTests.m
//  FireflyDevice
//
//  Created by Denis Bohm on 5/1/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import "FDSyncTask.h"

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

@interface FDSyncTaskTests : XCTestCase

@end

@implementation FDSyncTaskTests

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

- (void)testSyncUploadConnectionOpen
{
    id fireflyIce = [OCMockObject mockForClass:[FDFireflyIce class]];
    id observable = [OCMockObject mockForClass:[FDFireflyIceObservable class]];
    id executor = [OCMockObject mockForClass:[FDExecutor class]];
    id channel = [OCMockObject mockForProtocol:@protocol(FDFireflyIceChannel)];
    id delegate = [OCMockObject mockForProtocol:@protocol(FDSyncTaskDelegate)];
    id upload = [OCMockObject mockForProtocol:@protocol(FDSyncTaskUpload)];
    
    FDSyncTask *syncTask = [FDSyncTask syncTask:@"hwid-1" fireflyIce:fireflyIce channel:channel delegate:delegate identifier:@"id-1"];
    syncTask.upload = upload;

    // on task started
    [[[fireflyIce stub] andReturn:nil] log];
    [[delegate expect] syncTaskActive:syncTask];
    [[[fireflyIce expect] andReturn:observable] observable];
    [[observable expect] addObserver:syncTask];
    [[[upload expect] andReturnValue:@YES] isConnectionOpen];
    [[executor expect] complete:syncTask];
    
    // on task completed
    [[[upload expect] andReturnValue:@YES] isConnectionOpen];
    [[upload expect] cancel:[OCMArg any]];
    [[[fireflyIce expect] andReturn:observable] observable];
    [[observable expect] removeObserver:syncTask];
    [[delegate expect] syncTaskInactive:syncTask];
    [[[fireflyIce expect] andReturn:executor] executor];
// if syncTask.reschedile
//    [(FDExecutor *)[[executor expect] andReturnValue:@YES] run];
//    [[executor expect] execute:syncTask];
//    [[delegate expect] syncTaskComplete:syncTask];
    
    [syncTask executorTaskStarted:executor];
    [syncTask executorTaskCompleted:executor];

    [fireflyIce verify];
    [observable verify];
    [executor verify];
    [channel verify];
    [delegate verify];
    [upload verify];
}

@end
