//
//  FDDataViewController.m
//  FireflyTest
//
//  Created by Denis Bohm on 9/18/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDataViewController.h"

@interface FDDataViewController ()

@end

@implementation FDDataViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.dataLabel.text = [self.dataObject description];
}

@end
