//
//  FDColorUtilities.m
//  FireflyUtility
//
//  Created by Denis Bohm on 2/7/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDColorUtilities.h"

@implementation FDColorUtilities

+ (void)hueToComponentFactors:(CGFloat)h r:(CGFloat *)r g:(CGFloat *)g b:(CGFloat *)b
{
	float h_prime = h / (60.0f / 360.0f);
	float x = 1.0f - fabsf(fmodf(h_prime, 2.0f) - 1.0f);
	
	if (h_prime < 1.0f) {
		*r = 1;
		*g = x;
		*b = 0;
	} else
    if (h_prime < 2.0f) {
		*r = x;
		*g = 1;
		*b = 0;
	} else
    if (h_prime < 3.0f) {
		*r = 0;
		*g = 1;
		*b = x;
	} else
    if (h_prime < 4.0f) {
		*r = 0;
		*g = x;
		*b = 1;
	} else
    if (h_prime < 5.0f) {
		*r = x;
		*g = 0;
		*b = 1;
	} else {
		*r = 1;
		*g = 0;
		*b = x;
	}
}

+ (CGContextRef)newBGRxImageContext:(void *)data w:(int)w h:(int)h
{
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo kBGRxBitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;
    // BGRA is the most efficient on the iPhone.
	CGContextRef context = CGBitmapContextCreate(data, w, h, 8, w * 4, colorSpace, kBGRxBitmapInfo);
	CGColorSpaceRelease(colorSpace);
	return context;
}

+ (CGFloat)luminance:(UIColor *)color
{
    CGFloat red, green, blue, alpha;
    if ([color getRed:&red green:&green blue:&blue alpha:&alpha]) {
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
    }
    CGFloat white;
    [color getWhite:&white alpha:&alpha];
    return white;
}

+ (UIColor *)textColorForBackgroundColor:(UIColor *)backgroundColor
{
    CGFloat luminance = [FDColorUtilities luminance:backgroundColor];
    return luminance < 0.5f ? [UIColor lightTextColor] : [UIColor darkTextColor];
}

@end
