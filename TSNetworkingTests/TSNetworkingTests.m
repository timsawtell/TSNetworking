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
    self.semaphore = dispatch_semaphore_create(0);
    self.baseURLString = @"http://localhost:8080";
    [[TSNetworking sharedSession] setBaseURLString:self.baseURLString];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - GET

- (void)testGet
{
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(resultObject, @"nil result obj");
        NSLog(@"testGet successBlock");
        dispatch_semaphore_signal(self.semaphore);
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(error, @"nil error obj");
        NSLog(@"testGet errorBlock");
        dispatch_semaphore_signal(self.semaphore);
    };
    
    [[TSNetworking sharedSession] URLOperationWithPath:nil
                                            withMethod:HTTP_METHOD_GET
                                        withParameters:nil
                                           withSuccess:successBlock
                                             withError:errorBlock];
    
    while (dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

- (void)testGetWithPameters
{
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(resultObject, @"nil result obj");
        NSString *shouldBeString = [NSString stringWithFormat:@"%@?key=value", self.baseURLString];
        XCTAssertTrue([[request.URL absoluteString] isEqualToString:shouldBeString]);
        NSLog(@"testGetWithPameters successBlock");
        dispatch_semaphore_signal(self.semaphore);
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(error, @"nil error obj");
        NSLog(@"testGetWithPameters errorBlock");
        dispatch_semaphore_signal(self.semaphore);
    };
    
    [[TSNetworking sharedSession] URLOperationWithPath:nil
                                            withMethod:HTTP_METHOD_GET
                                        withParameters:@{@"key": @"value"}
                                           withSuccess:successBlock
                                             withError:errorBlock];
    
    while (dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

- (void)testGetWithUsernameAndPassword
{
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(resultObject, @"nil result obj");
        NSDictionary *headers = [request allHTTPHeaderFields];
        XCTAssertNotNil([headers valueForKey:@"Authorization"], @"auth missing");
        NSLog(@"testGetWithUsernameAndPassword successBlock");
        dispatch_semaphore_signal(self.semaphore);
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(error, @"nil error obj");
        NSLog(@"testGetWithUsernameAndPassword errorBlock");
        dispatch_semaphore_signal(self.semaphore);
    };
    
    [[TSNetworking sharedSession] setBasicAuthUsername:@"tim" withPassword:@"password"];
    
    [[TSNetworking sharedSession] URLOperationWithPath:nil
                                            withMethod:HTTP_METHOD_GET
                                        withParameters:nil
                                           withSuccess:successBlock
                                             withError:errorBlock];
    
    while (dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

#pragma mark - POST

- (void)testPostWithPameters
{
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(resultObject, @"nil result obj");
        NSLog(@"testPostWithPameters successBlock");
        NSString *string = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
        XCTAssertNotNil(string, @"request body had no content");
        dispatch_semaphore_signal(self.semaphore);
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(error, @"nil error obj");
        NSLog(@"testPostWithPameters errorBlock");
        dispatch_semaphore_signal(self.semaphore);
    };
    
    [[TSNetworking sharedSession] URLOperationWithPath:nil
                                            withMethod:HTTP_METHOD_POST
                                        withParameters:@{@"key": @"value"}
                                           withSuccess:successBlock
                                             withError:errorBlock];
    
    while (dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

@end
