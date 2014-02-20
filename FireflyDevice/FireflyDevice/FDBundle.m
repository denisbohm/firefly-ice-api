//
//  FDBundle.m
//  FireflyDevice
//
//  Created by scripts/plistToDictionary.sh on Wed Feb 19 19:36:33 PST 2014.
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
