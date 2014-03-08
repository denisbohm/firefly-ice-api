//
//  BatteryView.h
//
//  Created by Nathan Scandella on 4/21/12.
//

#import <UIKit/UIKit.h>

@interface FDBatteryView : UIView {
@private
    NSUInteger minimum;
    NSUInteger maximum;
    NSUInteger minBgWidth;
    NSUInteger maxBgWidth;
    NSUInteger currentValue_;
    UIImageView* foregroundLayer;
    UIImageView* backgroundLayer;
    UIImage* imageCache[3];
    BOOL animate;
}

// the minimum value of this gage
@property (nonatomic, assign) NSUInteger minimum;
// the maximum value of this gage
@property (nonatomic, assign) NSUInteger maximum;
// the current value (will be between minimum and maximum)
@property (nonatomic, assign) NSUInteger currentValue;
// should the view animate when currentValue is changed?
@property (nonatomic, assign) BOOL animate;

@end
