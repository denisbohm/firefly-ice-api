//
//  FDSyncTask.h
//  FireflyDevice
//
//  Created by Denis Bohm on 9/25/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDExecutor.h>
#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDWeak.h>

@protocol FDSyncTaskUpload;

@protocol FDSyncTaskUploadDelegate <NSObject>

- (void)upload:(id<FDSyncTaskUpload>)upload complete:(NSError *)error;

@end

@interface FDSyncTaskUploadItem : NSObject

@property NSString *hardwareId;
@property NSTimeInterval time;
@property NSTimeInterval interval;
@property NSArray *vmas;

@end

@protocol FDSyncTaskUpload <NSObject>

@property(FDWeak) id<FDSyncTaskUploadDelegate> delegate;

@property(readonly) BOOL isConnectionOpen;
@property(readonly) NSString *site;

- (void)post:(NSString *)site items:(NSArray *)items backlog:(NSUInteger)backlog;
- (void)cancel:(NSError *)error;

@end

#define FDSyncTaskErrorDomain @"com.fireflydesign.device.FDSyncTask"

enum {
    FDSyncTaskErrorCodeCancelling,
    FDSyncTaskErrorCodeException,
    FDSyncTaskErrorCodeCouldNotAcquireLock
};

@class FDSyncTask;
@class FDSyncTaskUpload;

@protocol FDSyncTaskDelegate <NSObject>

@optional

// Called when the sync task becomes active.
- (void)syncTaskActive:(FDSyncTask *)syncTask;

// Called if there is no upload object.
- (void)syncTask:(FDSyncTask *)syncTask site:(NSString *)site hardwareId:(NSString *)hardwareId time:(NSTimeInterval)time interval:(NSTimeInterval)interval vmas:(NSArray *)vmas backlog:(NSUInteger)backlog;

// Called when there is an error uploading.
- (void)syncTask:(FDSyncTask *)syncTask error:(NSError *)error;

// Called after each successful upload.
- (void)syncTask:(FDSyncTask *)syncTask progress:(float)progress;

// Called when all the data has been read from the device and synced to the web service.
- (void)syncTaskComplete:(FDSyncTask *)syncTask;

// Called when the sync task becomes inactive.
- (void)syncTaskInactive:(FDSyncTask *)syncTask;

@end

@interface FDSyncTask : NSObject <FDExecutorTask, FDFireflyIceObserver, FDSyncTaskUploadDelegate>

+ (FDSyncTask *)syncTask:(NSString *)hardwareId fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel delegate:(id<FDSyncTaskDelegate>)delegate identifier:(NSString *)identifier;

@property NSString *hardwareId;
@property FDFireflyIce *fireflyIce;
@property id<FDFireflyIceChannel> channel;
@property id<FDSyncTaskDelegate> delegate;
@property NSString *identifier;
@property id<FDSyncTaskUpload> upload;
@property NSUInteger syncAheadLimit;

@property BOOL reschedule;

@property(readonly) NSUInteger initialBacklog;
@property(readonly) NSUInteger currentBacklog;

@property(readonly) NSDate *lastDataDate;
@property(readonly) NSError *error;

@end