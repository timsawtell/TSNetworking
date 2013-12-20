//
//  AppDelegate.m
//  TSNetworking
//
//  Created by Tim Sawtell on 16/12/2013.
//  Copyright (c) 2013 Sawtell Software. All rights reserved.
//

#import "AppDelegate.h"
#import "TSNetworking.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"Run the unit tests intstead!");
    
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:5];    
    return YES;
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"entered background (no more NSLogs)");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
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
