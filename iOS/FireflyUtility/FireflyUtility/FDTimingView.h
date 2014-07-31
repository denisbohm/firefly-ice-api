//
//  FDSensorView.h
//  FireflyUtility
//
//  Created by Denis Bohm on 7/7/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FDSensorSample : NSObject

@property CGFloat ax;
@property CGFloat ay;
@property CGFloat az;

@property (nonatomic, readonly) CGFloat a;

@property NSTimeInterval time;

@end

@interface FDTimingView : UIView

@property CGFloat maxAcceleration;

@property NSUInteger maxSampleCount;
@property NSMutableArray *alphaSamples;
@property NSMutableArray *deltaSamples;

@property NSString *duration;

@end
