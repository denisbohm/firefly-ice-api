//
//  FDColorPickerViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 2/7/14.
//  Copyright (c) 2014 Firefly Design. All rights reserved.
//

#import "FDColorPickerViewController.h"
#import "FDColorGamutControl.h"
#import "FDColorGamutView.h"
#import "FDColorSpectrumControl.h"
#import "FDColorSpectrumView.h"

@interface FDColorPickerViewController ()

@property IBOutlet UIView *colorView;
@property IBOutlet FDColorGamutControl *gamutControl;
@property IBOutlet FDColorGamutView *gamutView;
@property IBOutlet FDColorSpectrumControl *spectrumControl;
@property IBOutlet FDColorSpectrumView *spectrumView;

@end

@implementation FDColorPickerViewController

+ (FDColorPickerViewController *)colorPickerViewController
{
	return [[self alloc] initWithNibName:@"FDColorPicker_iPhone" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.navigationItem.title = NSLocalizedString(@"Select Color", @"");
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
        
        _hueRange = FDRangeMake(0.0f, 1.0f);
        _saturationRange = FDRangeMake(0.0f, 1.0f);
        _brightnessRange = FDRangeMake(0.0f, 1.0f);
        _color = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    CGFloat hue = 0.0f;
    CGFloat saturation = 0.0f;
    CGFloat brightness = 0.0f;
    CGFloat alpha = 1.0f;
    [self.color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    // hue wraps around at 1.0f, we want unique values so keep hue in range [0.0f, 1.0f).
    if (hue >= 1.0f) {
        hue = 0.0f;
    }
    hue = FDRangeLimitValueToRange(_hueRange, hue);
    saturation = FDRangeLimitValueToRange(_saturationRange, saturation);
    brightness = FDRangeLimitValueToRange(_brightnessRange, brightness);
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1.0f];
    
    self.colorView.backgroundColor = color;
    self.gamutView.saturationRange = _saturationRange;
    self.gamutView.brightnessRange = _brightnessRange;
    self.gamutView.hue = hue;
    self.gamutControl.saturationRange = _saturationRange;
    self.gamutControl.brightnessRange = _brightnessRange;
    self.gamutControl.hue = hue;
    self.gamutControl.saturation = saturation;
    self.gamutControl.brightness = brightness;
    self.spectrumControl.hueRange = _hueRange;
    self.spectrumControl.hue = hue;
    self.spectrumView.hueRange = _hueRange;
}

- (IBAction)spectrumControlValueChanged:(id)sender
{
    _gamutView.hue = _spectrumControl.hue;
    _gamutControl.hue = _spectrumControl.hue;
}

- (IBAction)gamutControlValueChanged:(id)sender
{
    _colorView.backgroundColor = self.gamutControl.value;
}

- (IBAction)done:(id)sender
{
    if (_doneBlock != nil) {
        _doneBlock(self.gamutControl.value);
    }
}

@end
