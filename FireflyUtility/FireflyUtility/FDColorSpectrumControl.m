//
//  FDColorSpectrumControl.m
//  FireflyUtility
//
//  Created by Denis Bohm on 2/7/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDColorSpectrumControl.h"
#import "FDColorTouchView.h"

@interface FDColorSpectrumControl ()

@property FDColorTouchView *touchView;

@property CGFloat span;
@property CGFloat inset;

@property(nonatomic) CGFloat location;

@end

@implementation FDColorSpectrumControl

- (void)initialize
{
    _span = 24.0f;
    _inset = 20.0f;
    _location = 0.0f;
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

- (void) layoutSubviews
{
    [super layoutSubviews];
    
	if (_touchView == nil) {
		_touchView = [[FDColorTouchView alloc] initWithFrame:CGRectMake(0, 0, _span, _span)];
		[self addSubview:_touchView];
	}
	
	_touchView.color = [UIColor colorWithHue:self.hue saturation:1.0f brightness:1.0f alpha:1.0f];
	
	CGFloat x = _inset + (_location * (self.bounds.size.width - 2 * _inset));
    CGFloat y = CGRectGetMidY(self.bounds);
	_touchView.center = CGPointMake(x, y);
}

- (void)setLocation:(CGFloat)location
{
	if (_location != location) {
		_location = location;
		
		[self sendActionsForControlEvents:UIControlEventValueChanged];
		[self setNeedsLayout];
	}
}

- (void)setHue:(CGFloat)hue
{
    hue = FDRangeLimitValueToRange(_hueRange, hue);
    CGFloat span = _hueRange.max - _hueRange.min;
    CGFloat location = (span == 0.0f) ? _hueRange.min : ((hue - _hueRange.min) / span);
    [self setLocation:location];
}

- (CGFloat)hue
{
    CGFloat span = _hueRange.max - _hueRange.min;
    return _hueRange.min + _location * span;
}

- (void)setValue:(CGFloat)value
{
    self.hue = value;
}

- (CGFloat)value
{
    return self.hue;
}

- (void)trackTouch:(UITouch *)touch
{
	CGFloat location = ([touch locationInView:self].x - _inset) / (self.bounds.size.width - 2 * _inset);
	FDRange range = FDRangeMake(0.0f, 1.0f);
	self.location = FDRangeLimitValueToRange(range, location);
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
