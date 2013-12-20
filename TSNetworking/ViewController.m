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

- (void)viewDidLoad
{
    NSString *color = [[NSUserDefaults standardUserDefaults] objectForKey:@"bgColor"];
    self.view.backgroundColor = color == nil ? [UIColor whiteColor] : [UIColor redColor];
}


- (IBAction)buttonTouched:(id)sender
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"bgColor"];
    self.view.backgroundColor = [UIColor whiteColor];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *destinationPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    destinationPath = [destinationPath stringByAppendingPathComponent:@"5megs.jpg"];
    
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
            weakSelf.view.backgroundColor = [UIColor redColor];
            [[NSUserDefaults standardUserDefaults] setObject:@"red" forKey:@"bgColor"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        });
    };
    
    [[TSNetworking backgroundSession] downloadFromFullPath:@"http://upload.wikimedia.org/wikipedia/commons/2/2d/Snake_River_%285mb%29.jpg"
                                                    toPath:destinationPath
                                      withAddtionalHeaders:nil
                                         withProgressBlock:progress
                                               withSuccess:success
                                                 withError:error];
}

@end
