//
//  FDBundle.m
//  FireflyDevice
//
//  Created by scripts/plistToDictionary.sh on Thu Mar 13 19:41:27 CDT 2014.
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
        @"CFBundleShortVersionString": @"1.0.12",
        @"CFBundleVersion": @"12",
        @"NSHumanReadableCopyright": @"Copyright © 2013 Firefly Design. All rights reserved.",
    };
}

@end
