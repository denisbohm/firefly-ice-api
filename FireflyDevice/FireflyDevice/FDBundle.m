//
//  FDBundle.m
//  FireflyDevice
//
//  Created by scripts/plistToDictionary.sh
//

#import <FireflyDevice/FDBundle.h>

#import <FireflyDevice/FDBundleManager.h>

@implementation FDBundle

+ (void)loadBundle
{
    [FDBundleManager addLibraryBundle:[[FDBundle alloc] init]];
}

- (NSDictionary *)infoDictionary
{
    return @{
        @"CFBundleName": @"FireflyDevice",
        @"CFBundleShortVersionString": @"1.0.21",
        @"CFBundleVersion": @"21",
        @"NSHumanReadableCopyright": @"Copyright © 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.",
    };
}

@end
