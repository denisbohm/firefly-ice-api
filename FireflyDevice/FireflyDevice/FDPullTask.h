//
//  FDPullTask.h
//  FireflyDevice
//
//  Created by Denis Bohm on 9/25/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDExecutor.h>
#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDWeak.h>

#define FD_STORAGE_TYPE(a, b, c, d) (a | (b << 8) | (c << 16) | (d << 24))

@protocol FDPullTaskDecoder <NSObject>

- (id)decode:(uint32_t)type data:(NSData *)data responseData:(NSData *)responseData;

@end

@protocol FDPullTaskUpload;

@protocol FDPullTaskUploadDelegate <NSObject>

- (void)upload:(id<FDPullTaskUpload>)upload complete:(NSError *)error;

@end

@protocol FDPullTaskUpload <NSObject>

@property(FDWeak) id<FDPullTaskUploadDelegate> delegate;

@property(readonly) BOOL isConnectionOpen;
@property(readonly) NSString *site;

- (void)post:(NSString *)site items:(NSArray *)items backlog:(NSUInteger)backlog;
- (void)cancel:(NSError *)error;

@end

#define FDPullTaskErrorDomain @"com.fireflydesign.device.FDPullTask"

enum {
    FDPullTaskErrorCodeCancelling,
    FDPullTaskErrorCodeException,
    FDPullTaskErrorCodeCouldNotAcquireLock
};

@class FDPullTask;
@class FDPullTaskUpload;

@protocol FDPullTaskDelegate <NSObject>

@optional

// Called when the pull task becomes active.
- (void)pullTaskActive:(FDPullTask *)pullTask;

// Called when there is an error uploading.
- (void)pullTask:(FDPullTask *)pullTask error:(NSError *)error;

// Called when there is no uploader.
- (void)pullTask:(FDPullTask *)pullTask items:(NSArray *)items;

// Called after each successful upload.
- (void)pullTask:(FDPullTask *)pullTask progress:(float)progress;

// Called when all the data has been read from the device and sent to the upload service.
- (void)pullTaskComplete:(FDPullTask *)pullTask;

// Called when the pull task becomes inactive.
- (void)pullTaskInactive:(FDPullTask *)pullTask;

@end

@interface FDPullTask : NSObject <FDExecutorTask, FDFireflyIceObserver, FDPullTaskUploadDelegate>

+ (FDPullTask *)pullTask:(NSString *)hardwareId fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel delegate:(id<FDPullTaskDelegate>)delegate identifier:(NSString *)identifier;

@property NSString *hardwareId;
@property FDFireflyIce *fireflyIce;
@property id<FDFireflyIceChannel> channel;
@property id<FDPullTaskDelegate> delegate;
@property NSString *identifier;
@property NSMutableDictionary *decoderByType;
@property id<FDPullTaskUpload> upload;
@property NSUInteger pullAheadLimit;

@property BOOL reschedule;

@property(readonly) NSUInteger initialBacklog;
@property(readonly) NSUInteger currentBacklog;

@property(readonly) NSError *error;

@end