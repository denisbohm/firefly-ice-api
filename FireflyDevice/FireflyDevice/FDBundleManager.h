//
//  FDBundleManager.h
//  FireflyDevice
//
//  Created by Denis Bohm on 2/14/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import "FDBundle.h"

@interface FDBundleManager : NSObject

+ (void)addLibraryBundle:(id<FDBundleInfo>)bundle;

+ (NSArray *)allLibraryBundles;

@end
