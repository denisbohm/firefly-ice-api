//
//  FDBundle.m
//  FireflyDevice
//
//  Created by scripts/plistToDictionary.sh on Sat Feb 22 16:39:26 CST 2014.
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
        @"CFBundleShortVersionString": @"1.0.10",
        @"CFBundleVersion": @"10",
        @"NSHumanReadableCopyright": @"Copyright © 2013 Firefly Design. All rights reserved.",
    };
}

@end
