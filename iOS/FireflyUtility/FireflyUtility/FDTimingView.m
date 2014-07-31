//
//  FDSensorView.m
//  FireflyUtility
//
//  Created by Denis Bohm on 7/7/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDTimingView.h"

#import <CoreText/CoreText.h>

@implementation FDSensorSample

- (CGFloat)a
{
    return sqrt(_ax * _ax + _ay * _ay + _az * _az);
}

@end

@interface FDTimingView ()


@property CGPoint scale;

@end

@implementation FDTimingView

- (void)updateViewInit
{
    _maxAcceleration = 2.0;
    
    _maxSampleCount = 250;
    _alphaSamples = [NSMutableArray array];
    _deltaSamples = [NSMutableArray array];
    
    for (int i = 0; i < 250; ++i) {
        FDSensorSample *sample = [[FDSensorSample alloc] init];
        sample.ax = sin(i / 10.0);
        sample.ay = sin((i + 3) / 10.0);
        sample.az = sin((i + 6) / 10.0);
        [_alphaSamples addObject:sample];
        [_deltaSamples addObject:sample];
    }
    
    _duration = @"0.84";
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self updateViewInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        [self updateViewInit];
    }
    return self;
}

- (CGPoint)toCoord:(CGRect)rect index:(NSUInteger)index sample:(FDSensorSample *)sample key:(NSString *)key
{
    id object = [sample valueForKey:key];
    CGFloat value = [object floatValue];
    return CGPointMake(index * _scale.x, rect.size.height / 2.0 - value * _scale.y);
}

- (void)drawPath:(CGContextRef)context rect:(CGRect)rect key:(NSString *)key samples:(NSArray *)samples
{
    if (samples.count <= 0) {
        return;
    }
    
    CGMutablePathRef path = CGPathCreateMutable();
    FDSensorSample *sample = samples.firstObject;
    NSUInteger index = 0;
    CGPoint p = [self toCoord:rect index:index++ sample:sample key:key];
    CGPathMoveToPoint(path, NULL, p.x, p.y);
    for (FDSensorSample *sample in samples) {
        CGPoint p = [self toCoord:rect index:index++ sample:sample key:key];
        CGPathAddLineToPoint(path, NULL, p.x, p.y);
    }
    CGContextBeginPath(context);
    CGContextAddPath(context, path);
    CGContextStrokePath(context);
}

- (void)drawGraph:(CGContextRef)context rect:(CGRect)rect samples:(NSArray *)samples
{
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, rect.origin.x, rect.origin.y);
    
    CGFloat y = rect.size.height / 2.0;
    CGContextSetRGBStrokeColor(context, 0.9, 0.9, 0.9, 1.0);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, y);
    CGContextAddLineToPoint(context, rect.size.width, y);
    CGContextStrokePath(context);
    
    CGContextSetRGBStrokeColor(context, 1.0, 0.6, 0.6, 1.0);
    [self drawPath:context rect:rect key:@"ax" samples:samples];
    CGContextSetRGBStrokeColor(context, 0.4, 0.8, 0.4, 1.0);
    [self drawPath:context rect:rect key:@"ay" samples:samples];
    CGContextSetRGBStrokeColor(context, 0.6, 0.6, 1.0, 1.0);
    [self drawPath:context rect:rect key:@"az" samples:samples];
    CGContextSetRGBStrokeColor(context, 0.7, 0.7, 0.7, 1.0);
    [self drawPath:context rect:rect key:@"a" samples:samples];
    
    CGContextRestoreGState(context);
}

- (void)drawCenteredText:(CGContextRef)context attributes:(CFDictionaryRef)attributes string:(CFStringRef)string
{
    CTLineRef line = CTLineCreateWithAttributedString(CFAttributedStringCreate(kCFAllocatorDefault, string, attributes));
    CGRect bounds = CTLineGetImageBounds(line, context);
    CGFloat x = (self.frame.size.width - bounds.size.width) / 2.0;
    CGFloat y = (self.frame.size.height - bounds.size.height) / 2.0;
    CGContextSetTextPosition(context, x, y);
    CTLineDraw(line, context);
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat h = self.frame.size.height / 2.0;
    CGRect trect = CGRectMake(0, 0, self.frame.size.width, h);
    CGRect brect = CGRectMake(0, self.frame.size.height - h, self.frame.size.width, h);
    
    _scale.x = self.frame.size.width / _maxSampleCount;
    _scale.y = h / _maxAcceleration / 2.0;
    
    // draw alpha raw data
    [self drawGraph:context rect:trect samples:_alphaSamples];
    // draw delta raw data
    [self drawGraph:context rect:brect samples:_deltaSamples];
    
    if (_duration == nil) {
        return;
    }
    
    // draw line from event 1 to event 2 with gap in the center for the duration
    CGContextSaveGState(context);
    CGFloat x1 = 0.2 * self.frame.size.width;
    CGFloat x2 = 0.8 * self.frame.size.width;
    CGFloat tl = 0.4 * self.frame.size.width;
    CGFloat tr = 0.6 * self.frame.size.width;
    CGFloat r = 8.0; // corner radius
    CGFloat ah = 10.0; // arrow head height
    CGFloat aw = 2.0; // arrow head width on each side
    CGContextSetRGBStrokeColor(context, 0.6, 0.6, 0.6, 1.0);
    CGContextSetLineWidth(context, 2.0);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, x1, 0);
    CGContextAddLineToPoint(context, x1, h - r);
    CGContextAddArc(context, x1 + r, h - r, r, M_PI, M_PI_2, 1);
    CGContextAddLineToPoint(context, tl, h);
    CGContextMoveToPoint(context, tr, h);
    CGContextAddLineToPoint(context, x2 - r, h);
    CGContextAddArc(context, x2 - r, h + r, r, 3.0 * M_PI_2, 0.0, 0);
    CGContextAddLineToPoint(context, x2, self.frame.size.height - ah);
    CGContextStrokePath(context);
    CGContextSetRGBFillColor(context, 0.6, 0.6, 0.6, 1.0);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, x2, self.frame.size.height);
    CGContextAddLineToPoint(context, x2 - aw, self.frame.size.height - ah);
    CGContextAddLineToPoint(context, x2 + aw, self.frame.size.height - ah);
    CGContextClosePath(context);
    CGContextFillPath(context);
    CGContextRestoreGState(context);

    // flip coordinate system
    CGContextSetTextMatrix(context, CGAffineTransformIdentity); // 2-1
    CGContextTranslateCTM(context, 0, self.bounds.size.height); // 3-1
    CGContextScaleCTM(context, 1.0, -1.0);

    CTFontRef font = CTFontCreateWithName(CFSTR("Helvetica"), 18.0, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGFloat components[] = {1.0, 1.0, 1.0, 1.0};
    CGColorRef strokeColor = CGColorCreate(colorspace, components);
    float width = -10.0;
    CFTypeRef keys[] = { kCTFontAttributeName };
    CFTypeRef values[] = { font };
    CFDictionaryRef attributes = CFDictionaryCreate(kCFAllocatorDefault,
                                                    (const void**)keys,
                                                    (const void**)values,
                                                    sizeof(keys) / sizeof(keys[0]), // CFIndex numValues
                                                    &kCFTypeDictionaryKeyCallBacks,
                                                    &kCFTypeDictionaryValueCallBacks);
    CFTypeRef backgroundKeys[] = { kCTFontAttributeName, kCTStrokeColorAttributeName, kCTStrokeWidthAttributeName };
    CFTypeRef backgroundValues[] = { font, strokeColor, CFNumberCreate(NULL, kCFNumberFloatType, &width) };
    CFDictionaryRef background = CFDictionaryCreate(kCFAllocatorDefault,
                                                    (const void**)backgroundKeys,
                                                    (const void**)backgroundValues,
                                                    sizeof(backgroundKeys) / sizeof(backgroundKeys[0]), // CFIndex numValues
                                                    &kCFTypeDictionaryKeyCallBacks,
                                                    &kCFTypeDictionaryValueCallBacks);

    // draw duration
    CFStringRef string = (__bridge CFStringRef)_duration;
    [self drawCenteredText:context attributes:background string:string];
    [self drawCenteredText:context attributes:attributes string:string];
}

@end
