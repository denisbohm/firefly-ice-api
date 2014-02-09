//
//  FDColorSpectrumView.m
//  FireflyUtility
//
//  Created by Denis Bohm on 2/7/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDColorSpectrumView.h"

@implementation FDColorSpectrumView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setHueRange:(FDRange)hueRange
{
    if (!FDRangeEqualToRange(_hueRange, hueRange)) {
        _hueRange = hueRange;
        
        [self setNeedsDisplay];
    }
}

- (void)drawHueSpectrum:(UInt8 *)data
{
    CGFloat span = _hueRange.max - _hueRange.min;
	for (int x = 0; x < 256; ++x) {
		CGFloat hue = _hueRange.min + ((float)x / 255.0f) * span;
		
        CGFloat r, g, b;
        [FDColorUtilities hueToComponentFactors:hue r:&r g:&g b:&b];

		data[0] = (UInt8)(b * 255.0f);
		data[1] = (UInt8)(g * 255.0f);
		data[2] = (UInt8)(r * 255.0f);
        
		data += 4;
	}
}

- (CGImageRef)createContentImage
{
	UInt8 imageData[256 * 4];
	CGContextRef context = [FDColorUtilities createBGRxImageContext:imageData w:256 h:1];
	if (context == nil) {
		return nil;
    }
	UInt8 *bitmapData = CGBitmapContextGetData(context);
	if (bitmapData == nil) {
		CGContextRelease(context);
		return nil;
	}
	
	[self drawHueSpectrum:bitmapData];
	
	CGImageRef image = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	return image;
}

- (void)drawRect:(CGRect)rect
{
	CGImageRef image = [self createContentImage];
	if (image) {
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextDrawImage(context, [self bounds], image);
		CGImageRelease(image);
	}
}

@end
