//
//  FDColorGamutControl.m
//  FireflyUtility
//
//  Created by Denis Bohm on 2/8/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDColorGamutControl.h"
#import "FDColorTouchview.h"

@interface FDColorGamutControl ()

@property FDColorTouchView *touchView;

@property CGSize span;
@property CGSize inset;

@property(nonatomic) CGPoint location;

@end

@implementation FDColorGamutControl

- (void)initialize
{
    _saturationRange.min = 0.0f;
    _saturationRange.max = 1.0f;
    
    _brightnessRange.min = 0.0f;
    _brightnessRange.max = 1.0f;
    
    _location.x = 0.0f;
    _location.y = 0.0f;
    
    _span.width = 24.0f;
    _span.height = 24.0f;
    _inset.width = 20;
    _inset.height = 20;
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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
	if (_touchView == nil) {
		_touchView = [[FDColorTouchView alloc] initWithFrame:CGRectMake(0, 0, _span.width, _span.height)];
		[self addSubview:_touchView];
	}
	
	_touchView.color = [UIColor colorWithHue:self.hue saturation:self.saturation brightness:self.brightness alpha:1.0f];
	
    CGSize size = self.bounds.size;
	CGFloat x = _inset.width + (_location.x * (size.width - 2 * _inset.width));
	CGFloat y = _inset.height + (_location.y * (size.height - 2 * _inset.height));
	_touchView.center = CGPointMake(x, size.height - y);
}

- (void)valueChanged
{
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    [self setNeedsLayout];
}

- (void)setHue:(CGFloat)hue
{
    if (hue != _hue) {
        _hue = hue;
        
		[self valueChanged];
    }
}

- (CGFloat)saturationLocation:(CGFloat)saturation
{
    saturation = FDRangeLimitValueToRange(_saturationRange, saturation);
    CGFloat span = _saturationRange.max - _saturationRange.min;
    return (span == 0.0f) ? _saturationRange.min : ((saturation - _saturationRange.min) / span);
}

- (void)setSaturation:(CGFloat)saturation
{
    self.location = CGPointMake([self saturationLocation:saturation], _location.y);
}

- (CGFloat)saturation
{
    return _saturationRange.min + _location.x * (_saturationRange.max - _saturationRange.min);
}

- (CGFloat)brightnessLocation:(CGFloat)brightness
{
    brightness = FDRangeLimitValueToRange(_brightnessRange, brightness);
    CGFloat span = _brightnessRange.max - _brightnessRange.min;
    return (span == 0.0f) ? _brightnessRange.min : ((brightness - _brightnessRange.min) / span);
}

- (void)setBrightness:(CGFloat)brightness
{
    self.location = CGPointMake(_location.x, [self brightnessLocation:brightness]);
}

- (CGFloat)brightness
{
    return _brightnessRange.min + _location.y * (_brightnessRange.max - _brightnessRange.min);
}

- (UIColor *)value
{
    return [UIColor colorWithHue:self.hue saturation:self.saturation brightness:self.brightness alpha:1.0f];
}

- (void)setValue:(UIColor *)value
{
    CGFloat hue, saturation, brightness, alpha;
    [value getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    saturation = FDRangeLimitValueToRange(_saturationRange, saturation);
    brightness = FDRangeLimitValueToRange(_brightnessRange, brightness);
    if ((self.hue != hue) || (self.saturation != saturation) || (self.brightness != brightness)) {
        _location = CGPointMake([self saturationLocation:saturation], [self brightnessLocation:brightness]);
        _hue = hue;
        
		[self valueChanged];
    }
}

- (void)setLocation:(CGPoint)location
{
	if (!CGPointEqualToPoint(_location, location)) {
		_location = location;
		
		[self valueChanged];
	}
}

- (void)trackTouch:(UITouch *)touch
{
    CGSize size = self.bounds.size;
    CGPoint location = [touch locationInView:self];
	CGFloat x = (location.x - _inset.width) / (size.width - 2 * _inset.width);
	CGFloat y = (location.y - _inset.height) / (size.height - 2 * _inset.height);
    FDRange range = FDRangeMake(0.0f, 1.0f);
    x = FDRangeLimitValueToRange(range, x);
    y = FDRangeLimitValueToRange(range, y);
    self.location = CGPointMake(x, 1.0f - y);
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super beginTrackingWithTouch:touch withEvent:event];
	[self trackTouch:touch];
	return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super continueTrackingWithTouch:touch withEvent:event];
	[self trackTouch:touch];
	return YES;
}

@end
