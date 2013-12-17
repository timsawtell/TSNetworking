//
//  TSNetworkingTests.m
//  TSNetworkingTests
//
//  Created by Tim Sawtell on 16/12/2013.
//  Copyright (c) 2013 Sawtell Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TSNetworking.h"

@interface TSNetworkingTests : XCTestCase
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) NSString *baseURLString;
@end

@implementation TSNetworkingTests

- (void)setUp
{
    [super setUp];
    self.baseURLString = @"http://localhost:8080";
    [[TSNetworking sharedSession] setBaseURLString:self.baseURLString];
    [[TSNetworking sharedSession] setBasicAuthUsername:nil withPassword:nil];
    [[TSNetworking backgroundSession] setBaseURLString:self.baseURLString];
    [[TSNetworking backgroundSession] setBasicAuthUsername:nil withPassword:nil];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)signalFinished:(NSCondition *)condition
{
    [condition lock];
    [condition signal];
    [condition unlock];
}

#pragma mark - GET

- (void)testGet
{
    __block NSCondition *completed = NSCondition.new;
    [completed lock];
    __weak typeof (self) weakSelf = self;
    
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(resultObject, @"nil result obj");
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(error, @"nil error obj");
        [weakSelf signalFinished:completed];
    };

    [[TSNetworking sharedSession] performURLOperationWithRelativePath:nil
                                                    withMethod:HTTP_METHOD_GET
                                                withParameters:nil
                                                   withSuccess:successBlock
                                                     withError:errorBlock];
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}

- (void)testGetWithPameters
{
    __block NSCondition *completed = NSCondition.new;
    [completed lock];
    __weak typeof (self) weakSelf = self;
    
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(resultObject, @"nil result obj");
        NSString *shouldBeString = [NSString stringWithFormat:@"%@?key=value", weakSelf.baseURLString];
        XCTAssertTrue([[request.URL absoluteString] isEqualToString:shouldBeString]);
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(error, @"nil error obj");
        [weakSelf signalFinished:completed];
    };
    
    [[TSNetworking sharedSession] performURLOperationWithRelativePath:nil
                                                    withMethod:HTTP_METHOD_GET
                                                withParameters:@{@"key": @"value"}
                                                   withSuccess:successBlock
                                                     withError:errorBlock];
    
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}

- (void)testGetWithUsernameAndPassword

{
    __block NSCondition *completed = NSCondition.new;
    [completed lock];
    __weak typeof(self) weakSelf = self;
    
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(resultObject, @"nil result obj");
        NSDictionary *headers = [request allHTTPHeaderFields];
        XCTAssertNotNil([headers valueForKey:@"Authorization"], @"auth missing");
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(error, @"nil error obj");
        [weakSelf signalFinished:completed];
    };
    
    [[TSNetworking sharedSession] setBasicAuthUsername:@"hack" withPassword:@"thegibson"];
    
    [[TSNetworking sharedSession] performURLOperationWithRelativePath:nil
                                                    withMethod:HTTP_METHOD_GET
                                                withParameters:nil
                                                   withSuccess:successBlock
                                                     withError:errorBlock];
    
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}

#pragma mark - POST

- (void)testPostWithPameters
{
    __block NSCondition *completed = NSCondition.new;
    [completed lock];
    __weak typeof(self) weakSelf = self;
    
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(resultObject, @"nil result obj");
        NSString *string = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
        XCTAssertNotNil(string, @"request body had no content");
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(error, @"nil error obj");
        [weakSelf signalFinished:completed];
    };
    
    [[TSNetworking sharedSession] performURLOperationWithRelativePath:nil
                                                    withMethod:HTTP_METHOD_POST
                                                withParameters:@{@"key": @"value"}
                                                   withSuccess:successBlock
                                                     withError:errorBlock];
    
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}

#pragma mark - Download

- (void)testDownloadFile
{
    __block NSCondition *completed = NSCondition.new;
    [completed lock];
    __weak typeof(self) weakSelf = self;
    
    NSString *destinationPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    destinationPath = [destinationPath stringByAppendingPathComponent:@"1mb.mp4"];
    
    __block NSFileManager *fm = [NSFileManager new];
    
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertTrue([fm fileExistsAtPath:destinationPath isDirectory:NO], @"resulting file does not exist");
        [weakSelf signalFinished:completed];
        [fm removeItemAtPath:destinationPath error:nil];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(error, @"nil error obj");
        NSLog(@"%@", error.localizedDescription);
        [weakSelf signalFinished:completed];
        [fm removeItemAtPath:destinationPath error:&error];
    };
    
    TSNetworkDownloadTaskProgressBlock progressBlock = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        NSLog(@"Download written: %lld, total written: %lld, total expected: %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    };
    
    [[TSNetworking backgroundSession] downloadFromFullPath:@"https://archive.org/download/1mbFile/1mb.mp4"
                                                    toPath:destinationPath
                                         withProgressBlock:progressBlock
                                               withSuccess:successBlock
                                                 withError:errorBlock];
    
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}

#pragma mark - Upload

- (void)testUpload
{
    __block NSCondition *completed = NSCondition.new;
    [completed lock];
    __weak typeof(self) weakSelf = self;
    
    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"ourLord" ofType:@"jpg"];
    XCTAssertNotNil(sourcePath, @"Couldn't find local picture of our lord");
    
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkDownloadTaskProgressBlock progressBlock = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        NSLog(@"uploaded: %lld, total written: %lld, total expected: %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    };
    
    [[TSNetworking backgroundSession] uploadFromFullPath:sourcePath
                                                  toPath:@"http://localhost:8080"
                                       withProgressBlock:progressBlock
                                             withSuccess:successBlock
                                               withError:errorBlock];
    
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}

@end
