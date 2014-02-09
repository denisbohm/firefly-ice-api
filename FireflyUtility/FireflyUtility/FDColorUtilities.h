//
//  FDColorUtilities.h
//  FireflyUtility
//
//  Created by Denis Bohm on 2/7/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    CGFloat min;
    CGFloat max;
} FDRange;

CG_INLINE FDRange
FDRangeMake(CGFloat min, CGFloat max)
{
    FDRange r; r.min = min; r.max = max; return r;
}

CG_INLINE bool
__FDRangeEqualToRange(FDRange range1, FDRange range2)
{
    return range1.min == range2.min && range1.max == range2.max;
}
#define FDRangeEqualToRange __FDRangeEqualToRange

CG_INLINE float
__FDRangeLimitValueToRange(FDRange range, CGFloat value)
{
	if (range.min > value) {
		return range.min;
	}
    if (range.max < value) {
		return range.max;
    }
    return value;
}
#define FDRangeLimitValueToRange __FDRangeLimitValueToRange

@interface FDColorUtilities : NSObject

+ (void)hueToComponentFactors:(CGFloat)h r:(CGFloat *)r g:(CGFloat *)g b:(CGFloat *)b;

+ (CGContextRef)createBGRxImageContext:(void *)data w:(int)w h:(int)h;

+ (CGFloat)luminance:(UIColor *)color;

+ (UIColor *)textColorForBackgroundColor:(UIColor *)backgroundColor;

@end
