//
//  FDBundleManager.m
//  FireflyDevice
//
//  Created by Denis Bohm on 2/14/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDBundleManager.h>

static NSMutableArray *libraryBundles = nil;

@implementation FDBundleManager

+ (void)addLibraryBundle:(id<FDBundleInfo>)bundle
{
    if (libraryBundles == nil) {
        libraryBundles = [NSMutableArray array];
    }
    [libraryBundles addObject:bundle];
}

+ (NSArray *)allLibraryBundles
{
    return [NSArray arrayWithArray:libraryBundles];
}

@end
