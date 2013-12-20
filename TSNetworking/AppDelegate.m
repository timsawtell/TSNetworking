//
//  AppDelegate.m
//  TSNetworking
//
//  Created by Tim Sawtell on 16/12/2013.
//  Copyright (c) 2013 Sawtell Software. All rights reserved.
//

#import "AppDelegate.h"
#import "TSNetworking.h"
#import "Reachability.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"Run the unit tests intstead!");
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    if (NotReachable != reachability.currentReachabilityStatus) {
        NSUInteger count = [[TSNetworking sharedSession] resumePausedDownloads];
        if (count > 0) {
            completionHandler(UIBackgroundFetchResultNewData);
        } else {
            completionHandler(UIBackgroundFetchResultNoData);
        }
    }
}

- (void)application:(UIApplication *)application
handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)())completionHandler
{
    // You must re-establish a reference to the background session,
    // or NSURLSessionDownloadDelegate and NSURLSessionDelegate methods will not be called
    // as no delegate is attached to the session. See backgroundURLSession above.
    [TSNetworking sharedSession].sessionCompletionHandler = completionHandler;
    UILocalNotification *notif = [[UILocalNotification alloc] init];
    notif.alertBody = @"handleEventsForBackgroundURLSession";
    notif.fireDate = [[NSDate date] dateByAddingTimeInterval:1];
    [[UIApplication sharedApplication] scheduleLocalNotification:notif];
}

@end
