//
//  FDColorGamutView.m
//  FireflyUtility
//
//  Created by Denis Bohm on 2/7/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDColorGamutView.h"
#import "FDColorUtilities.h"

@implementation FDColorGamutView

- (void)initialize
{
    _hue = 0.0f;
    _saturationRange.min = 0.0f;
    _saturationRange.max = 1.0f;
    _brightnessRange.min = 0.0f;
    _brightnessRange.max = 1.0f;
    [self updateImage];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self initialize];
}

static UInt8 blend(UInt8 value, UInt8 percentIn255)
{
	return (UInt8)((int)value * percentIn255 / 255);
}

- (CGImageRef)newImage
{
	void *data = nil;
    CGContextRef context = nil;
    CGImageRef image = nil;
    @try {
        data = malloc(256 * 256 * 4);
        if (data == nil) {
            return nil;
        }
        context = [FDColorUtilities newBGRxImageContext:data w:256 h:256];
        if (context == nil) {
            return nil;
        }
        
        UInt8 *dataPtr = data;
        size_t rowBytes = CGBitmapContextGetBytesPerRow(context);
        
        CGFloat r, g, b;
        [FDColorUtilities hueToComponentFactors:_hue r:&r g:&g b:&b];
        
        UInt8 r_s = (UInt8)((1.0f - r) * 255);
        UInt8 g_s = (UInt8)((1.0f - g) * 255);
        UInt8 b_s = (UInt8)((1.0f - b) * 255);
        
        for (int s = 0 ; s < 256; ++s) {
            register UInt8 *ptr = dataPtr;
            
            UInt8 saturation = (UInt8)(255.0f * (_saturationRange.min + (s / 255.0f) * (_saturationRange.max - _saturationRange.min)));
            register unsigned int r_hs = 255 - blend(saturation, r_s);
            register unsigned int g_hs = 255 - blend(saturation, g_s);
            register unsigned int b_hs = 255 - blend(saturation, b_s);
            
            for (register int b = 255; b >= 0; --b) {
                UInt8 brightness = (UInt8)(255.0f * (_brightnessRange.min + (b / 255.0f) * (_brightnessRange.max - _brightnessRange.min)));
                
                ptr[0] = (UInt8)(brightness * b_hs >> 8);
                ptr[1] = (UInt8)(brightness * g_hs >> 8);
                ptr[2] = (UInt8)(brightness * r_hs >> 8);
                
                // Really, these should all be of the form used in blend(),
                // which does a divide by 255. However, integer divide is
                // implemented in software on ARM7 (iPhone 4s and earlier),
                // so a divide by 256 (done as a bit shift) will be *nearly*
                // the same value, and is faster. The more-accurate versions
                // would look like:
                //	ptr[ 0 ] = blend( v, b_hs );
                // In ARM7s there is integer divide support (starting in iPhone 5).
                
                ptr += rowBytes;
            }
            
            dataPtr += 4;
        }
        
        image = CGBitmapContextCreateImage(context);
	} @finally {
        if (context != nil) {
            CGContextRelease(context);
        }
        if (data != nil) {
            free(data);
        }
	}
	return image;
}

- (void)updateImage
{
    CGImageRef imageRef = [self newImage];
    self.image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
}

- (void)setHue:(CGFloat)hue
{
    if (_hue != hue) {
        _hue = hue;
        
        [self updateImage];
    }
}

- (void)setSaturationRange:(FDRange)saturationRange
{
    if (!FDRangeEqualToRange(_saturationRange, saturationRange)) {
        _saturationRange = saturationRange;
        
        [self updateImage];
    }
}

- (void)setBrightnessRange:(FDRange)brightnessRange
{
    if (!FDRangeEqualToRange(_brightnessRange, brightnessRange)) {
        _brightnessRange = brightnessRange;
        
        [self updateImage];
    }
}

@end
