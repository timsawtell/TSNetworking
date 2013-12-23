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
    return YES;
}

- (void)application:(UIApplication *)application
handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)())completionHandler
{
    [TSNetworking backgroundSession].sessionCompletionHandler = completionHandler;
}

@end
