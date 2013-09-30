//
//  ZZActivityUploader.h
//  Activity
//
//  Created by Denis Bohm on 11/8/11.
//

#import <Foundation/Foundation.h>

#import "ZZActivity.h"

@interface ZZActivityUploader : NSObject<ZZActivityDelegate>

- (void)open;
- (void)close;

- (void)start;
- (void)fire;
- (void)stop;

@property(strong) NSString *filename;
@property(strong) NSURL *url;
@property(strong) NSString *username;
@property(strong) NSString *password;
@property(strong) NSString *platform;
@property int revision;
@property(strong) NSString *uuid;
@property(strong) NSString *hardwareId;
@property int activityInterval;
@property NSTimeInterval postInterval;

@end
