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

- (id _Nullable )decode:(uint32_t)type data:(NSData * _Nonnull)data responseData:(NSData * _Nonnull)responseData;

@end

@protocol FDPullTaskUpload;

@protocol FDPullTaskUploadDelegate <NSObject>

- (void)upload:(id <FDPullTaskUpload> _Nonnull)upload complete:(NSError * _Nullable)error;

@end

@protocol FDPullTaskUpload <NSObject>

@property(FDWeak) id<FDPullTaskUploadDelegate> _Nullable delegate;

@property(readonly) BOOL isConnectionOpen;
@property(readonly) NSString * _Nullable site;

- (void)post:(NSString * _Nullable)site items:(NSArray * _Nonnull)items backlog:(NSUInteger)backlog;
- (void)cancel:(NSError * _Nullable)error;

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
- (void)pullTaskActive:(nonnull FDPullTask *)pullTask;

// Called when there is an error uploading.
- (void)pullTask:(nonnull FDPullTask *)pullTask error:(nullable NSError *)error;

// Called when there is no uploader.
- (void)pullTask:(nonnull FDPullTask *)pullTask items:(nonnull NSArray *)items;

// Called after each successful upload.
- (void)pullTask:(nonnull FDPullTask *)pullTask progress:(float)progress;

// Called when all the data has been read from the device and sent to the upload service.
- (void)pullTaskComplete:(nonnull FDPullTask *)pullTask;

// Called when the pull task becomes inactive.
- (void)pullTaskInactive:(nonnull FDPullTask *)pullTask;

@end

@interface FDPullTask : NSObject <FDExecutorTask, FDFireflyIceObserver, FDPullTaskUploadDelegate>

+ (FDPullTask * _Nonnull)pullTask:(NSString * _Nonnull)hardwareId fireflyIce:(FDFireflyIce * _Nonnull)fireflyIce channel:(id <FDFireflyIceChannel> _Nonnull)channel delegate:(id <FDPullTaskDelegate> _Nullable)delegate identifier:(NSString * _Nullable)identifier;

@property NSString * _Nullable hardwareId;
@property FDFireflyIce * _Nonnull fireflyIce;
@property id<FDFireflyIceChannel> _Nonnull channel;
@property id<FDPullTaskDelegate> _Nullable delegate;
@property NSString * _Nullable identifier;
@property NSMutableDictionary * _Nonnull decoderByType;
@property id<FDPullTaskUpload> _Nullable upload;
@property NSUInteger pullAheadLimit;
@property NSUInteger totalBytesReceived;

@property BOOL reschedule;

@property(readonly) NSUInteger initialBacklog;
@property(readonly) NSUInteger currentBacklog;

@property(readonly) NSError * _Nullable error;

@end
