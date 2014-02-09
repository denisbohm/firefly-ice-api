//
//  FDColorButton.m
//  FireflyUtility
//
//  Created by Denis Bohm on 2/8/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDColorButton.h"
#import "FDColorUtilities.h"

@implementation FDColorButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setColor:(UIColor *)color
{
    if (![_color isEqual:color]) {
        _color = color;
        
        [self setTitle:@"Choose Color" forState:UIControlStateNormal];
        [self setTitleColor:[FDColorUtilities textColorForBackgroundColor:color] forState:UIControlStateNormal];
        
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, _color.CGColor);
    CGContextFillRect(context, self.bounds);
}

@end
