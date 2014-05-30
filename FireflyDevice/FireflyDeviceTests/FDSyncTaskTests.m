//
//  FDSyncTaskTests.m
//  FireflyDevice
//
//  Created by Denis Bohm on 5/1/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDBinary.h>
#import <FireflyDevice/FDFireflyIceCoder.h>
#import <FireflyDevice/FDSyncTask.h>

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

@interface FDSyncTaskTests : XCTestCase

@end

@interface FDSyncTask () <FDSyncTaskUploadDelegate>
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

- (NSData *)noData
{
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt64:0]; // product
    [binary putUInt64:0]; // unique
    [binary putUInt32:0xfffffffe]; // page (no data)
    [binary putUInt16:0]; // length
    [binary putUInt16:0]; // hash
    [binary putUInt32:0]; // type
    return binary.dataValue;
}

- (void)testSyncUploadNone
{
    id fireflyIce = [OCMockObject mockForClass:[FDFireflyIce class]];
    id observable = [OCMockObject mockForClass:[FDFireflyIceObservable class]];
    id executor = [OCMockObject mockForClass:[FDExecutor class]];
    id channel = [OCMockObject mockForProtocol:@protocol(FDFireflyIceChannel)];
    id coder = [OCMockObject mockForClass:[FDFireflyIceCoder class]];
    id delegate = [OCMockObject mockForProtocol:@protocol(FDSyncTaskDelegate)];
    id upload = [OCMockObject mockForProtocol:@protocol(FDSyncTaskUpload)];
    FDFireflyIceVersion *version = [[FDFireflyIceVersion alloc] init];
    version.capabilities = FD_CONTROL_CAPABILITY_LOCK | FD_CONTROL_CAPABILITY_SYNC_AHEAD;
    FDFireflyIceLock *lock = [[FDFireflyIceLock alloc] init];
    lock.identifier = fd_lock_identifier_sync;
    lock.owner = fd_lock_owner_ble;
    FDFireflyIceStorage *storage = [[FDFireflyIceStorage alloc] init];
    storage.pageCount = 0;
    
    FDSyncTask *syncTask = [FDSyncTask syncTask:@"hwid-1" fireflyIce:fireflyIce channel:channel delegate:delegate identifier:@"id-1"];
    syncTask.upload = upload;
    
    [[[fireflyIce stub] andReturn:nil] log];
    [[[fireflyIce stub] andReturn:executor] executor];
    [[[fireflyIce stub] andReturn:observable] observable];
    [[[fireflyIce stub] andReturn:coder] coder];
    [[[channel stub] andReturn:@"BLE"] name];
    
    // on task started
    [[delegate expect] syncTaskActive:syncTask];
    [[observable expect] addObserver:syncTask];
    [[[upload expect] andReturnValue:@NO] isConnectionOpen];
    [[coder expect] sendGetProperties:channel properties:FD_CONTROL_PROPERTY_VERSION];
    [[coder expect] sendLock:channel identifier:fd_lock_identifier_sync operation:fd_lock_operation_acquire];
    [[coder expect] sendGetProperties:channel properties:FD_CONTROL_PROPERTY_SITE | FD_CONTROL_PROPERTY_STORAGE];
    [[coder expect] sendSyncStart:channel offset:0];
    [[executor expect] feedWatchdog:syncTask];
    
    // on task completed
    [[[upload expect] andReturnValue:@NO] isConnectionOpen];
    [[coder expect] sendLock:channel identifier:fd_lock_identifier_sync operation:fd_lock_operation_release];
    [[executor expect] complete:syncTask];
    [[delegate expect] syncTaskComplete:syncTask];
    [[[upload expect] andReturnValue:@NO] isConnectionOpen];
    [[observable expect] removeObserver:syncTask];
    [[delegate expect] syncTaskInactive:syncTask];
    
    [syncTask executorTaskStarted:executor];
    [syncTask fireflyIce:fireflyIce channel:channel version:version];
    [syncTask fireflyIce:fireflyIce channel:channel lock:lock];
    [syncTask fireflyIce:fireflyIce channel:channel site:@"fireflydesign.com"];
    [syncTask fireflyIce:fireflyIce channel:channel storage:storage];
    [syncTask fireflyIce:fireflyIce channel:channel syncData:[self noData]];
    [syncTask executorTaskCompleted:executor];
    
    [fireflyIce verify];
    [observable verify];
    [executor verify];
    [channel verify];
    [coder verify];
    [delegate verify];
    [upload verify];
}

- (void)testSyncUploadRAM
{
    id fireflyIce = [OCMockObject mockForClass:[FDFireflyIce class]];
    id observable = [OCMockObject mockForClass:[FDFireflyIceObservable class]];
    id executor = [OCMockObject mockForClass:[FDExecutor class]];
    id channel = [OCMockObject mockForProtocol:@protocol(FDFireflyIceChannel)];
    id coder = [OCMockObject mockForClass:[FDFireflyIceCoder class]];
    id delegate = [OCMockObject mockForProtocol:@protocol(FDSyncTaskDelegate)];
    id upload = [OCMockObject mockForProtocol:@protocol(FDSyncTaskUpload)];
    FDFireflyIceVersion *version = [[FDFireflyIceVersion alloc] init];
    version.capabilities = FD_CONTROL_CAPABILITY_LOCK | FD_CONTROL_CAPABILITY_SYNC_AHEAD;
    FDFireflyIceLock *lock = [[FDFireflyIceLock alloc] init];
    lock.identifier = fd_lock_identifier_sync;
    lock.owner = fd_lock_owner_ble;
    FDFireflyIceStorage *storage = [[FDFireflyIceStorage alloc] init];
    storage.pageCount = 0;
    NSString *site = @"fireflydesign.com";
    
    FDSyncTask *syncTask = [FDSyncTask syncTask:@"hwid-1" fireflyIce:fireflyIce channel:channel delegate:delegate identifier:@"id-1"];
    syncTask.upload = upload;
    
    [[[fireflyIce stub] andReturn:nil] log];
    [[[fireflyIce stub] andReturn:executor] executor];
    [[[fireflyIce stub] andReturn:observable] observable];
    [[[fireflyIce stub] andReturn:coder] coder];
    [[[channel stub] andReturn:@"BLE"] name];
    
    // on task started
    [[delegate expect] syncTaskActive:syncTask];
    [[observable expect] addObserver:syncTask];
    [[[upload expect] andReturnValue:@NO] isConnectionOpen];
    [[coder expect] sendGetProperties:channel properties:FD_CONTROL_PROPERTY_VERSION];
    [[coder expect] sendLock:channel identifier:fd_lock_identifier_sync operation:fd_lock_operation_acquire];
    [[coder expect] sendGetProperties:channel properties:FD_CONTROL_PROPERTY_SITE | FD_CONTROL_PROPERTY_STORAGE];
    [[coder expect] sendSyncStart:channel offset:0];
    [[executor expect] feedWatchdog:syncTask];
    [[[upload expect] andReturnValue:@NO] isConnectionOpen];
    [[upload expect] post:site items:[OCMArg any] backlog:0]; // !!! check upload items -denis
    [[coder expect] sendSyncStart:channel offset:1];
    [[executor expect] feedWatchdog:syncTask];
    
    [[[upload expect] andReturnValue:@YES] isConnectionOpen];
    // async upload complete event
    [[delegate expect] syncTask:syncTask progress:1.0f];
    [[channel expect] fireflyIceChannelSend:[OCMArg any]]; // sync data ack

    // on task completed
    [[coder expect] sendLock:channel identifier:fd_lock_identifier_sync operation:fd_lock_operation_release];
    [[executor expect] complete:syncTask];
    [[delegate expect] syncTaskComplete:syncTask];
    [[[upload expect] andReturnValue:@NO] isConnectionOpen];
    [[observable expect] removeObserver:syncTask];
    [[delegate expect] syncTaskInactive:syncTask];
    
    [syncTask executorTaskStarted:executor];
    [syncTask fireflyIce:fireflyIce channel:channel version:version];
    [syncTask fireflyIce:fireflyIce channel:channel lock:lock];
    [syncTask fireflyIce:fireflyIce channel:channel site:site];
    [syncTask fireflyIce:fireflyIce channel:channel storage:storage];
    FDBinary *binary = [[FDBinary alloc] init];
    [binary putUInt64:0]; // product
    [binary putUInt64:0]; // unique
    [binary putUInt32:0xffffffff]; // page (RAM)
    [binary putUInt16:0]; // length
    [binary putUInt16:0]; // hash
    [binary putUInt32:0x32564446]; // type
    [binary putUInt32:0]; // time
    [binary putUInt16:10]; // interval
    [binary putFloat16:2.5f]; // VMA
    [syncTask fireflyIce:fireflyIce channel:channel syncData:binary.dataValue];
    [syncTask fireflyIce:fireflyIce channel:channel syncData:[self noData]];
    [syncTask upload:upload complete:nil];
    [syncTask executorTaskCompleted:executor];
    
    [fireflyIce verify];
    [observable verify];
    [executor verify];
    [channel verify];
    [coder verify];
    [delegate verify];
    [upload verify];
}

@end
