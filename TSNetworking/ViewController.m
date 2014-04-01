//
//  ViewController.m
//  TSNetworking
//
//  Created by Tim Sawtell on 20/12/2013.
//  Copyright (c) 2013 Sawtell Software. All rights reserved.
//

#import "ViewController.h"
#import "TSNetworking.h"

@interface ViewController ()

@end

@implementation ViewController

- (IBAction)buttonTouched:(id)sender
{
    NSString *destinationPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    destinationPath = [destinationPath stringByAppendingPathComponent:@"ourLord.jpeg"];
    
    __weak typeof(self)weakSelf = self;
    
    TSNetworkDownloadTaskProgressBlock progress = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat progress = ((float)totalBytesWritten / (float)totalBytesExpectedToWrite) * 100;
            NSLog(@"Progress: %02.02f", progress);
            weakSelf.progressView.progress = progress / 100;
        });
    };
    
    TSNetworkErrorBlock error = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        NSLog(@"Error with download: %@", error.localizedDescription);
    };
    
    TSNetworkSuccessBlock success = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UILocalNotification *notif = [[UILocalNotification alloc] init];
            notif.alertBody = @"success (from block)";
            notif.fireDate = [[NSDate date] dateByAddingTimeInterval:1];
            [[UIApplication sharedApplication] scheduleLocalNotification:notif];
            NSLog(@"Successfully finished download");
        });
    };
    
    [[TSNetworking backgroundSession] downloadFromFullPath:@"http://images.dailytech.com/nimage/gabe_newell.jpeg"
                                                    toPath:destinationPath
                                      withAddtionalHeaders:nil
                                         withProgressBlock:progress
                                               withSuccess:success
                                                 withError:error];
}

- (IBAction)simpleGetTouched:(id)sender
{
    TSNetworkErrorBlock error = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        NSLog(@"Error with request: %@", error.localizedDescription);
    };
    
    TSNetworkSuccessBlock success = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        NSLog(@"Simple get finished with: %@\n\n", resultObject);
    };
    
    [[TSNetworking foregroundSession] setBaseURLString:@"http://stackoverflow.com/questions/12073776/iphone-convert-text-from-iso-8859-1-latin-1-encoding"];
    [[TSNetworking foregroundSession] performDataTaskWithRelativePath:nil
                                                       withMethod:HTTP_METHOD_GET
                                                   withParameters:nil
                                             withAddtionalHeaders:nil
                                                      withSuccess:success withError:error];
}

- (IBAction)simpleGetWithParamsTouched:(id)sender
{
    TSNetworkErrorBlock error = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        NSLog(@"Error with request: %@", error.localizedDescription);
    };
    
    TSNetworkSuccessBlock success = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        NSLog(@"Simple get with params finished with: %@\n\n", resultObject);
    };
    
    [[TSNetworking foregroundSession] setBaseURLString:@"http://www.google.com"];
    [[TSNetworking foregroundSession] performDataTaskWithRelativePath:@"/search"
                                                       withMethod:HTTP_METHOD_GET
                                                   withParameters:@{@"q":@"Gabe Newell"}
                                             withAddtionalHeaders:nil
                                                      withSuccess:success withError:error];
}

@end
