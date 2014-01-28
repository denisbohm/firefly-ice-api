//
//  BatteryView.m
//
//  Created by Nathan Scandella on 4/21/12.
//

#import "FDBatteryView.h"

static const float LOW_LEVEL = 0.25;     // 25%
static const float WARNING_LEVEL = 0.1;  // 10%

@interface FDBatteryView()
@property (nonatomic, strong) UIImageView* foregroundLayer;
@property (nonatomic, strong) UIImageView* backgroundLayer;
@end

@implementation FDBatteryView

@synthesize foregroundLayer, backgroundLayer;
@synthesize minimum, maximum, animate;

#pragma mark - Custom Properties

- (NSUInteger) currentValue {
    return currentValue_;
}

// get a nine patch image that stretches the insides without stretching the borders
- (UIImage*) stretchableImage: (UIImage*) image {
    // TODO: change these constants if you use a different set of battery images
    return [image stretchableImageWithLeftCapWidth: 17 topCapHeight: 14];
}

- (void) setCurrentValue:(NSUInteger)value {
    if (value != currentValue_) {
        // clip value to be within [minimum, maximum]
        value = MIN(value, maximum);
        value = MAX(value, minimum);
        
        // may need to change color of fuel based on the percentage charged
        float percentage = (float)(value - minimum) / (float)(maximum - minimum);
        if (percentage < WARNING_LEVEL) {
            if (imageCache[0] == nil) {
                UIImage* lowImage = [[UIImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"red_fuel" ofType:@"png"]];
                UIImage* stretchableBgImage = [self stretchableImage: lowImage];
                imageCache[0] = stretchableBgImage;
            }
            backgroundLayer.image = imageCache[0];            
        } else if (percentage < LOW_LEVEL) {
            if (imageCache[1] == nil) {
                UIImage* lowImage = [[UIImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"orange_fuel" ofType:@"png"]];
                UIImage* stretchableBgImage = [self stretchableImage: lowImage];
                imageCache[1] = stretchableBgImage;
            }
            backgroundLayer.image = imageCache[1];
        } else {
            backgroundLayer.image = imageCache[2];
        }
        int bgWidth = minBgWidth + percentage * (maxBgWidth - minBgWidth);
        
        if (animate) {
            [UIView beginAnimations: @"BatteryViewAnimation" context: NULL];
            [UIView setAnimationCurve: UIViewAnimationCurveLinear];
            [UIView setAnimationDuration: 1.0f];
        }
        
        CGRect newFrame = self.backgroundLayer.frame;
        newFrame.size.width = bgWidth;
        self.backgroundLayer.frame = newFrame;
        
        if (animate) {
            [UIView commitAnimations]; 
        }
        currentValue_ = value;
    }
}

#pragma mark - Initialization

- (void) initialize {
    // set defaults
    minimum = 0;
    maximum = 100;
    animate = YES;
    
    // the foreground is the battery shell
    UIImage* fgImage = [[UIImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"battery" ofType:@"png"]];
    foregroundLayer = [[UIImageView alloc] initWithImage: fgImage];
    foregroundLayer.hidden = NO;
    foregroundLayer.opaque = NO;
    foregroundLayer.backgroundColor = [UIColor clearColor];
    foregroundLayer.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    // the background is the fuel filling the transparent shell
    UIImage* bgImage = [[UIImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"green_fuel" ofType:@"png"]];
    // we define a 9-patch to let the fuel background stretch appropriately
    UIImage* stretchableBgImage = [self stretchableImage: bgImage];
    imageCache[2] = stretchableBgImage;
    backgroundLayer = [[UIImageView alloc] initWithImage: stretchableBgImage];
    backgroundLayer.contentMode = UIViewContentModeScaleToFill;
    backgroundLayer.hidden = NO;
    backgroundLayer.opaque = NO;
    backgroundLayer.backgroundColor = [UIColor clearColor];
    backgroundLayer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    minBgWidth = bgImage.size.width;
    // TODO: change this constant if you use a different set of battery images
    maxBgWidth = 200;
    
    [self addSubview: backgroundLayer];
    [self addSubview: foregroundLayer];
    
    int offset = (backgroundLayer.frame.size.height - foregroundLayer.frame.size.height) / 2;
    CGRect frame = foregroundLayer.frame;
    frame.origin.y = offset;
    foregroundLayer.frame = frame;
}

// explicit initialization
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

// initialized from .nib
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end
