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

    [[TSNetworking sharedSession] URLOperationWithRelativePath:nil
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
    
    [[TSNetworking sharedSession] URLOperationWithRelativePath:nil
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
    
    [[TSNetworking sharedSession] URLOperationWithRelativePath:nil
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
    
    [[TSNetworking sharedSession] URLOperationWithRelativePath:nil
                                            withMethod:HTTP_METHOD_POST
                                        withParameters:@{@"key": @"value"}
                                           withSuccess:successBlock
                                             withError:errorBlock];
    
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}

@end
