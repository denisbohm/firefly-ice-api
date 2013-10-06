//
//  ZZUpload.h
//  FireflyUtility
//
//  Created by Denis Bohm on 10/5/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZZUpload;

@protocol ZZUploadDelegate <NSObject>

- (void)upload:(ZZUpload *)upload complete:(NSError *)error;

@end

@interface ZZUpload : NSObject

@property id<ZZUploadDelegate> delegate;
@property NSString *uuid;

@property NSString *username;
@property NSString *password;
@property NSString *platform;
@property NSInteger revision;

@property(readonly) BOOL isConnectionOpen;

- (void)post:(NSString *)site hardwareId:(NSString *)hardwareId time:(NSTimeInterval)time interval:(NSTimeInterval)interval vmas:(NSArray *)vmas backlog:(NSUInteger)backlog;

@end
