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

#import <Foundation/Foundation.h>
#import "AFSecurityPolicy.h"

#define ASSIGN_NOT_NIL(property, val) ({id __val = (val); if (__val != [NSNull null] && __val != nil) { property = val;}})
typedef void(^TSNetworkSuccessBlock)(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response);
typedef void(^TSNetworkErrorBlock)(NSObject *resultObject, NSError *error, NSMutableURLRequest *request, NSURLResponse *response);
typedef void(^TSNetworkDownloadTaskProgressBlock)(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);
typedef void(^TSNetworkUploadTaskProgressBlock)(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend);

typedef enum {
    HTTP_METHOD_POST = 0,
    HTTP_METHOD_GET,
    HTTP_METHOD_PUT,
    HTTP_METHOD_HEAD,
    HTTP_METHOD_DELETE,
    HTTP_METHOD_TRACE,
    HTTP_METHOD_CONNECT,
    HTTP_METHOD_PATCH,
} HTTP_METHOD;


@interface TSNetworking : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

/**
 The security policy used by created request operations to evaluate server trust for secure connections.
 */
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;

+ (TSNetworking*)sharedSession;

+ (TSNetworking *)backgroundSession; // for uploads and downloads

- (void)setBaseURLString:(NSString *)baseURLString;

- (void)setBasicAuthUsername:(NSString *)username
                withPassword:(NSString *)password;

- (void)performURLOperationWithRelativePath:(NSString *)path
                          withMethod:(HTTP_METHOD)method
                      withParameters:(NSDictionary *)parameters
                         withSuccess:(TSNetworkSuccessBlock)successBlock
                           withError:(TSNetworkErrorBlock)errorBlock;

- (void)downloadFromFullPath:(NSString *)sourcePath
                      toPath:(NSString *)destinationPath
           withProgressBlock:(TSNetworkDownloadTaskProgressBlock)progressBlock
                 withSuccess:(TSNetworkSuccessBlock)successBlock
                   withError:(TSNetworkErrorBlock)errorBlock;

- (void)uploadFromFullPath:(NSString *)sourcePath
                    toPath:(NSString *)destinationPath
         withProgressBlock:(id)progressBlock
               withSuccess:(TSNetworkSuccessBlock)successBlock
                 withError:(TSNetworkErrorBlock)errorBlock;

@end

