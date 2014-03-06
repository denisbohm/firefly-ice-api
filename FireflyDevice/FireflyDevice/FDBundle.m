//
//  FDBundle.m
//  FireflyDevice
//
//  Created by scripts/plistToDictionary.sh on Wed Mar  5 17:20:25 CST 2014.
//

#import "FDBundle.h"
#import <FireflyDevice/FDBundleManager.h>

@implementation FDBundle

+ (void)load
{
    [FDBundleManager addLibraryBundle:[[FDBundle alloc] init]];
}

- (NSDictionary *)infoDictionary
{
    return @{
        @"CFBundleName": @"FireflyDevice",
        @"CFBundleShortVersionString": @"1.0.11",
        @"CFBundleVersion": @"11",
        @"NSHumanReadableCopyright": @"Copyright © 2013 Firefly Design. All rights reserved.",
    };
}

@end
