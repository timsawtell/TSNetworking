//
//  TSNetworking.h
//  TSNetworking
//
//  Created by Tim Sawtell on 16/12/2013.
//  Copyright (c) 2013 Sawtell Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFSecurityPolicy.h"

#define ASSIGN_NOT_NIL(property, val) ({id __val = (val); if (__val != [NSNull null] && __val != nil) { property = val;}})
typedef void(^TSNetworkSuccessBlock)(NSObject *resultObject, NSMutableURLRequest *request, NSURLResponse *response);
typedef void(^TSNetworkErrorBlock)(NSError *error, NSMutableURLRequest *request, NSURLResponse *response);
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


@interface TSNetworking : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>

/**
 The security policy used by created request operations to evaluate server trust for secure connections. `AFURLSessionManager` uses the `defaultPolicy` unless otherwise specified.
 */
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;

+ (TSNetworking*)sharedSession;

- (void)setBaseURLString:(NSString *)baseURLString;

- (void)setBasicAuthUsername:(NSString *)username
                withPassword:(NSString *)password;

- (void)URLOperationWithPath:(NSString *)path
                  withMethod:(HTTP_METHOD)method
              withParameters:(NSDictionary *)parameters
                 withSuccess:(TSNetworkSuccessBlock)successBlock
                   withError:(TSNetworkErrorBlock)errorBlock;

@end
