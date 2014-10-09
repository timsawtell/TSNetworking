/*
 Copyright (c) 2013 Tim Sawtell
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 IN THE SOFTWARE.
 */

#import <XCTest/XCTest.h>
#import "TSNetworking.h"

NSString * const kNoAuthNeeded = @"http://localhost:8081";
NSString * const kAuthNeeded = @"http://localhost:8080";
NSString * const kJSON = @"http://localhost:8083";
NSString * const kMultipartUpload = @"http://localhost:8082/upload";

@interface TSNetworkingTests : XCTestCase
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) NSString *baseURLString;
@end

#warning if you want these tests to work you need to install node.js on your machine and have the all .js files running before Testing this code. The .js files are located in the TSNetworkingTests folder.
/*
 install instruction found at http://nodejs.org/
 once node is installed, you need node package manager (npm). Pretty sure it comes with node.js
 You need the node library `formidable`, install with "npm install formidable"
 */

@implementation TSNetworkingTests

- (void)setUp
{
    [super setUp];
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
        NSURL *requestURL = request.URL;
        XCTAssertTrue([[requestURL lastPathComponent] isEqualToString:@"something"], "path wasn't appended");
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(error, @"nil error obj");
        [weakSelf signalFinished:completed];
    };
    
    [[TSNetworking foregroundSession] setBaseURLString:kNoAuthNeeded];
    [[TSNetworking foregroundSession] performDataTaskWithRelativePath:@"something"
                                                       withMethod:HTTP_METHOD_GET
                                                   withParameters:nil
                                             withAddtionalHeaders:nil
                                                      withSuccess:successBlock
                                                        withError:errorBlock];
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}

- (void)testGetAdditonalHeaders
{
    __block NSCondition *completed = NSCondition.new;
    [completed lock];
    __weak typeof (self) weakSelf = self;
    
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(resultObject, @"nil result obj");
        NSDictionary *headers = [request allHTTPHeaderFields];
        XCTAssertTrue([[headers valueForKey:@"Accept"] isEqualToString:@"application/json"], "header missing");
        XCTAssertTrue([[headers valueForKey:@"Content-Type"] isEqualToString:@"application/json"], "header missing");
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(error, @"nil error obj");
        XCTAssertFalse(YES, @"Shouldn't be in error block");
        [weakSelf signalFinished:completed];
    };
    
    [[TSNetworking foregroundSession] setBaseURLString:kNoAuthNeeded];
    [[TSNetworking foregroundSession] addSessionHeaders:@{@"Accept":@"application/json"}];
    
    [[TSNetworking foregroundSession] performDataTaskWithRelativePath:nil
                                                       withMethod:HTTP_METHOD_GET
                                                   withParameters:nil
                                             withAddtionalHeaders:@{@"Content-Type":@"application/json"}
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
        NSString *shouldBeString = [NSString stringWithFormat:@"%@?key=value", kNoAuthNeeded];
        XCTAssertTrue([[request.URL absoluteString] isEqualToString:shouldBeString]);
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(error, @"nil error obj");
        XCTAssertFalse(YES, @"Shouldn't be in error block");
        [weakSelf signalFinished:completed];
    };
    
    [[TSNetworking foregroundSession] setBaseURLString:kNoAuthNeeded];
    [[TSNetworking foregroundSession] performDataTaskWithRelativePath:nil
                                                       withMethod:HTTP_METHOD_GET
                                                   withParameters:@{@"key": @"value"}
                                             withAddtionalHeaders:nil
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
        XCTAssertFalse(YES, @"Shouldn't be in error block");
        [weakSelf signalFinished:completed];
    };
    
    [[TSNetworking foregroundSession] setBaseURLString:kAuthNeeded];
    [[TSNetworking foregroundSession] setBasicAuthUsername:@"hack" withPassword:@"thegibson"];
    
    [[TSNetworking foregroundSession] performDataTaskWithRelativePath:nil
                                                       withMethod:HTTP_METHOD_GET
                                                   withParameters:nil
                                             withAddtionalHeaders:nil
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
        XCTAssertFalse(YES, @"Shouldn't be in error block");
        [weakSelf signalFinished:completed];
    };
    
    [[TSNetworking foregroundSession] setBaseURLString:kNoAuthNeeded];
    [[TSNetworking foregroundSession] performDataTaskWithRelativePath:nil
                                                       withMethod:HTTP_METHOD_POST
                                                   withParameters:@{@"key": @"value"}
                                             withAddtionalHeaders:nil
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
    destinationPath = [destinationPath stringByAppendingPathComponent:@"ourLord.jpeg"];
    
    __block NSFileManager *fm = [NSFileManager new];
    
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertTrue([fm fileExistsAtPath:destinationPath isDirectory:nil], @"resulting file does not exist");
        [fm removeItemAtPath:destinationPath error:nil];
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(error, @"nil error obj");
        NSLog(@"%@", error.localizedDescription);
        [fm removeItemAtPath:destinationPath error:&error];
        XCTAssertFalse(YES, @"Shouldn't be in error block");
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkDownloadTaskProgressBlock progressBlock = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        NSLog(@"Download written: %lld, total written: %lld, total expected: %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    };
    
    [[TSNetworking backgroundSession] downloadFromFullPath:@"http://images.dailytech.com/nimage/gabe_newell.jpeg"
                                                    toPath:destinationPath
                                      withAddtionalHeaders:nil
                                         withProgressBlock:progressBlock
                                               withSuccess:successBlock
                                                 withError:errorBlock];
    
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}

- (void)testCancelDownload
{
    __block NSCondition *completed = NSCondition.new;
    [completed lock];
    __weak typeof(self) weakSelf = self;
    
    NSString *destinationPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    destinationPath = [destinationPath stringByAppendingPathComponent:@"1mb.mp4"];
    
    __block NSFileManager *fm = [NSFileManager new];
    
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertTrue([fm fileExistsAtPath:destinationPath isDirectory:nil], @"resulting file does not exist");
        [fm removeItemAtPath:destinationPath error:nil];
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(error, @"nil error obj");
        NSLog(@"%@", error.localizedDescription);
        XCTAssertEqual(error.code, NSURLErrorCancelled, @"task was not cancelled, it was :%@", error.localizedDescription);
        if ([fm fileExistsAtPath:destinationPath isDirectory:nil]) {
            [fm removeItemAtPath:destinationPath error:&error];
        }
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkDownloadTaskProgressBlock progressBlock = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        NSLog(@"Download written: %lld, total written: %lld, total expected: %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    };
    
    NSURLSessionDownloadTask *task = [[TSNetworking backgroundSession] downloadFromFullPath:@"https://archive.org/download/1mbFile/1mb.mp4"
                                                                                     toPath:destinationPath
                                                                       withAddtionalHeaders:nil
                                                                          withProgressBlock:progressBlock
                                                                                withSuccess:successBlock
                                                                                  withError:errorBlock];
    double delayInSeconds = 2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void){
        if (NSURLSessionTaskStateRunning == task.state) {
            [task cancelByProducingResumeData:^(NSData *resumeData) {
                // sometimes the download hasn't actually started yet. For ease of using this test case, I wont check the resumeData, I trust apple (famous last words)
                // the real test is in the errorBlock to check the error code
            }];
        }
    });
    
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}
#pragma mark - Upload File

- (void)testUpload
{
    __block NSCondition *completed = NSCondition.new;
    [completed lock];
    __weak typeof(self) weakSelf = self;
    
    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"ourLord" ofType:@"jpg"];
    XCTAssertNotNil(sourcePath, @"Couldn't find local picture of our lord");
    
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        NSLog(@"%@", resultObject);
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        NSLog(@"%@", resultObject);
        XCTAssertFalse(YES, @"Shouldn't be in error block");
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkDownloadTaskProgressBlock progressBlock = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        NSLog(@"file uploaded: %lld, total written: %lld, total expected: %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    };
    
    [[TSNetworking backgroundSession] uploadInBackgroundFromLocalPath:sourcePath
                                                               toPath:kMultipartUpload
                                                 withAddtionalHeaders:nil
                                                    withProgressBlock:progressBlock
                                                          withSuccess:successBlock
                                                            withError:errorBlock];
    
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}

- (void)testCancelUpload
{
    __block NSCondition *completed = NSCondition.new;
    [completed lock];
    __weak typeof(self) weakSelf = self;
    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"ourLord" ofType:@"jpg"];
    XCTAssertNotNil(sourcePath, @"Couldn't find local picture of our lord");
    
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        NSLog(@"%@", resultObject);
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        NSLog(@"%@", resultObject);
        XCTAssertEqual(error.code, NSURLErrorCancelled, @"task was not cancelled, it was :%@", error.localizedDescription);
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkDownloadTaskProgressBlock progressBlock = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        NSLog(@"file uploaded: %lld, total written: %lld, total expected: %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    };
    
    NSURLSessionUploadTask *uploadTask = [[TSNetworking backgroundSession] uploadInBackgroundFromLocalPath:sourcePath
                                                                                                    toPath:kMultipartUpload
                                                                                      withAddtionalHeaders:nil
                                                                                         withProgressBlock:progressBlock
                                                                                               withSuccess:successBlock
                                                                                                 withError:errorBlock];
    
    double delayInSeconds = 0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void){
        [uploadTask cancel];
    });
    
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}

#pragma mark - Upload Data

- (void)testUploadData
{
    __block NSCondition *completed = NSCondition.new;
    [completed lock];
    __weak typeof(self) weakSelf = self;
    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"ourLord" ofType:@"jpg"];
    XCTAssertNotNil(sourcePath, @"Couldn't find local picture of our lord");
    
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        NSLog(@"%@", resultObject);
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        NSLog(@"%@", resultObject);
        XCTAssertFalse(YES, @"Shouldn't be in error block");
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkDownloadTaskProgressBlock progressBlock = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        NSLog(@"data uploaded: %lld, total written: %lld, total expected: %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    };
    
    NSFileManager *fm = [NSFileManager new];
    NSData *data = [fm contentsAtPath:sourcePath];
    
    [[TSNetworking foregroundSession] uploadInForegroundData:data
                                                  toPath:kMultipartUpload
                                    withAddtionalHeaders:nil
                                       withProgressBlock:progressBlock
                                             withSuccess:successBlock
                                               withError:errorBlock];
    
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}

- (void)testCancelUploadData
{
    __block NSCondition *completed = NSCondition.new;
    [completed lock];
    __weak typeof(self) weakSelf = self;
    
    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"ourLord" ofType:@"jpg"];
    XCTAssertNotNil(sourcePath, @"Couldn't find local picture of our lord");
    
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        NSLog(@"%@", resultObject);
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        NSLog(@"%@", resultObject);
        XCTAssertEqual(error.code, NSURLErrorCancelled, @"task was not cancelled, it was :%@", error.localizedDescription);
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkDownloadTaskProgressBlock progressBlock = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        NSLog(@"data uploaded: %lld, total written: %lld, total expected: %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    };
    
    NSFileManager *fm = [NSFileManager new];
    NSData *data = [fm contentsAtPath:sourcePath];
    
    NSURLSessionUploadTask *uploadTask = [[TSNetworking foregroundSession] uploadInForegroundData:data
                                                                                       toPath:kMultipartUpload
                                                                         withAddtionalHeaders:nil
                                                                            withProgressBlock:progressBlock
                                                                                  withSuccess:successBlock
                                                                                    withError:errorBlock];
    
    double delayInSeconds = 0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void){
        [uploadTask cancel];
    });
    
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}

- (void)testAddDownloadProgressBlock
{
    __block NSCondition *completed = NSCondition.new;
    [completed lock];
    __weak typeof(self) weakSelf = self;
    
    NSString *destinationPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    destinationPath = [destinationPath stringByAppendingPathComponent:@"ourLord.jpeg"];
    
    __block NSFileManager *fm = [NSFileManager new];
    
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertTrue([fm fileExistsAtPath:destinationPath isDirectory:nil], @"resulting file does not exist");
        [fm removeItemAtPath:destinationPath error:nil];
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(error, @"nil error obj");
        NSLog(@"%@", error.localizedDescription);
        [fm removeItemAtPath:destinationPath error:&error];
        XCTAssertFalse(YES, @"Shouldn't be in error block");
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkDownloadTaskProgressBlock progressBlock = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        NSLog(@"The progress block ran after being added!");
    };
    
    NSURLSessionDownloadTask *task = [[TSNetworking backgroundSession] downloadFromFullPath:@"http://images.dailytech.com/nimage/gabe_newell.jpeg"
                                                                                     toPath:destinationPath
                                                                       withAddtionalHeaders:nil
                                                                          withProgressBlock:nil
                                                                                withSuccess:successBlock
                                                                                  withError:errorBlock];
    
    [[TSNetworking backgroundSession] addDownloadProgressBlock:progressBlock toExistingDownloadTask:task];
    
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}

- (void)testAddUploadProgressBlock
{
    __block NSCondition *completed = NSCondition.new;
    [completed lock];
    __weak typeof(self) weakSelf = self;
    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"ourLord" ofType:@"jpg"];
    XCTAssertNotNil(sourcePath, @"Couldn't find local picture of our lord");
    
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        NSLog(@"%@", resultObject);
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        NSLog(@"%@", resultObject);
        XCTAssertFalse(YES, @"Shouldn't be in error block");
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkDownloadTaskProgressBlock progressBlock = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        NSLog(@"The upload progress block was added");
    };
    
    NSFileManager *fm = [NSFileManager new];
    NSData *data = [fm contentsAtPath:sourcePath];
    
    NSURLSessionUploadTask *task = [[TSNetworking foregroundSession] uploadInForegroundData:data
                                                                                 toPath:kMultipartUpload
                                                                   withAddtionalHeaders:nil
                                                                      withProgressBlock:nil
                                                                            withSuccess:successBlock
                                                                              withError:errorBlock];
    
    [[TSNetworking foregroundSession] addUploadProgressBlock:progressBlock toExistingUploadTask:task];
    
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}

- (void)testGetJSON
{
    __block NSCondition *completed = NSCondition.new;
    [completed lock];
    __weak typeof (self) weakSelf = self;
    
    TSNetworkSuccessBlock successBlock = ^(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(resultObject, @"nil result obj");
        XCTAssertTrue([resultObject isKindOfClass:[NSDictionary class]]);
        [weakSelf signalFinished:completed];
    };
    
    TSNetworkErrorBlock errorBlock = ^(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response) {
        XCTAssertNotNil(error, @"nil error obj");
        XCTAssertFalse(YES, @"Shouldn't be in error block");
        [weakSelf signalFinished:completed];
    };
    
    [[TSNetworking foregroundSession] setBaseURLString:kJSON];
    [[TSNetworking foregroundSession] performDataTaskWithRelativePath:nil
                                                           withMethod:HTTP_METHOD_GET
                                                       withParameters:nil
                                                 withAddtionalHeaders:nil
                                                          withSuccess:successBlock
                                                            withError:errorBlock];
    
    [completed waitUntilDate:[NSDate distantFuture]];
    [completed unlock];
}

@end
