//
//  FDBundle.m
//  FireflyDevice
//
//  Created by scripts/plistToDictionary.sh on Tue Feb 25 09:40:52 CST 2014.
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
