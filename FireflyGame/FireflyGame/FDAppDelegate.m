//
//  FDAppDelegate.m
//  FireflyGame
//
//  Created by Denis Bohm on 10/21/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDAppDelegate.h"
#import "FDViewController.h"

#import <FireflyDevice/FDFireflyDeviceLogger.h>
#import <FireflyDevice/FDFileLog.h>

@interface FDAppDelegate ()

@property id<FDFireflyDeviceLog> log;
@property FDFileLog *fileLog;

@end

@implementation FDAppDelegate

#define BACKGROUND_FETCH 0

// 1 hour (+5 minutes)
#define AUTOMATICALLY_SYNC_INTERVAL 3900

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    _fileLog = [[FDFileLog alloc] init];
//    [FDFireflyDeviceLogger setLog:_fileLog];
    
    NSArray *centralManagerIdentifiers = launchOptions[UIApplicationLaunchOptionsBluetoothCentralsKey];
    for (NSString *identifier in centralManagerIdentifiers) {
        FDFireflyDeviceLogInfo(@"launched with Bluetooth central manager identifier %@", identifier);
    }
    
#if BACKGROUND_FETCH
    NSTimeInterval interval = UIApplicationBackgroundFetchIntervalMinimum;
    if (interval < AUTOMATICALLY_SYNC_INTERVAL) {
        interval = AUTOMATICALLY_SYNC_INTERVAL;
    }
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:interval];
#endif

    FDViewController* viewController = (FDViewController *)self.window.rootViewController;
    viewController.fileLog = _fileLog;
    
    return YES;
}

#if BACKGROUND_FETCH
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    FDFireflyDeviceLogInfo(@"application:performFetchWithCompletionHandler: called");
    FDViewController* viewController = (FDViewController *)self.window.rootViewController;
    FDFireflyIceManager *fireflyIceManager = viewController.fireflyIceManager;
    [fireflyIceManager automaticallySync:^(ZZBackgroundSyncResult result) {
        FDFireflyDeviceLogInfo(@"application:performFetchWithCompletionHandler: completion handler result %u", (unsigned)result);
        switch (result) {
            case ZZBackgroundSyncResultNewData:
                completionHandler(UIBackgroundFetchResultNewData);
                break;
            case ZZBackgroundSyncResultNoData:
                completionHandler(UIBackgroundFetchResultNoData);
                break;
            case ZZBackgroundSyncResultFailed:
                completionHandler(UIBackgroundFetchResultFailed);
                break;
            default:
                completionHandler(UIBackgroundFetchResultFailed);
                break;
        }
    }];
}
#endif

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    FDFireflyDeviceLogInfo(@"applicationWillResignActive: called");
    
    SKView *view = (SKView *)self.window.rootViewController.view;
    view.paused = YES;
    
    FDViewController* viewController = (FDViewController *)self.window.rootViewController;
    FDFireflyIceManager *fireflyIceManager = viewController.fireflyIceManager;
    fireflyIceManager.active = NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    FDFireflyDeviceLogInfo(@"applicationDidEnterBackground: called");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    FDFireflyDeviceLogInfo(@"applicationWillEnterForeground: called");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    FDFireflyDeviceLogInfo(@"applicationDidBecomeActive: called");

    SKView *view = (SKView *)self.window.rootViewController.view;
    view.paused = NO;
    
    FDViewController* viewController = (FDViewController *)self.window.rootViewController;
    FDFireflyIceManager *fireflyIceManager = viewController.fireflyIceManager;
    fireflyIceManager.active = YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

    FDFireflyDeviceLogInfo(@"applicationWillTerminate: called");
}

@end
