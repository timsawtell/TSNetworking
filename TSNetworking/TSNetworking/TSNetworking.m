//
//  TSNetworking.m
//  TSNetworking
//
//  Created by Tim Sawtell on 16/12/2013.
//  Copyright (c) 2013 Sawtell Software. All rights reserved.
//

#import "TSNetworking.h"
#import "Base64.h"

typedef void(^URLSessionCompletion)(NSData *data, NSURLResponse *response, NSError *error);

@interface TSNetworking()

@property (nonatomic, strong) NSURLSessionConfiguration *defaultConfiguration;
@property (nonatomic, strong) NSURLSession *sharedSession;
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, strong) NSIndexSet *acceptableStatusCodes;
@end

@implementation TSNetworking

- (id)init
{
    self = [super init];
    if (self) {
        _defaultConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _defaultConfiguration.allowsCellularAccess = YES;
        _defaultConfiguration.timeoutIntervalForRequest = 30.0;
        _defaultConfiguration.timeoutIntervalForResource = 30.0;
        _defaultConfiguration.HTTPMaximumConnectionsPerHost = 1;
        [_defaultConfiguration setHTTPAdditionalHeaders:@{@"Accept": @"application/json"}];
        [_defaultConfiguration setHTTPAdditionalHeaders:@{@"Content-Type": @"application/json"}];
        
        _sharedSession = [NSURLSession sessionWithConfiguration:_defaultConfiguration
                                                      delegate:self
                                                 delegateQueue:nil];
        
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
        _acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    }
    return self;
}

+ (TSNetworking*)sharedSession
{
    static TSNetworking* sharedSession = nil;
    @synchronized(self) {
        if (sharedSession == nil) {
            sharedSession = [[TSNetworking alloc] init];
        }
    }
    return sharedSession;
}

- (void)setBaseURLString:(NSString *)baseURLString
{
    self.baseURL = [NSURL URLWithString:baseURLString];
}

- (void)setBasicAuthUsername:(NSString *)username
                withPassword:(NSString *)password
{
    self.username = username;
    self.password = password;
}

/*
 * Public Interface 
 * The programmer calls this method 
 */
- (void)URLOperationWithPath:(NSString *)path
                  withMethod:(HTTP_METHOD)method
              withParameters:(NSDictionary *)parameters
                 withSuccess:(TSNetworkSuccessBlock)successBlock
                   withError:(TSNetworkErrorBlock)errorBlock
{
    NSAssert(nil != self.baseURL, @"Base URL is nil");
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.baseURL
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:self.defaultConfiguration.timeoutIntervalForRequest];
    NSString *setMethod;
    switch (method) {
        case HTTP_METHOD_POST:
            setMethod = @"POST";break;
        case HTTP_METHOD_GET:
            setMethod = @"GET";break;
        case HTTP_METHOD_PUT:
            setMethod = @"PUT";break;
        case HTTP_METHOD_HEAD:
            setMethod = @"HEAD";break;
        case HTTP_METHOD_DELETE:
            setMethod = @"DELETE";break;
        case HTTP_METHOD_TRACE:
            setMethod = @"TRACE";break;
        case HTTP_METHOD_CONNECT:
            setMethod = @"CONNECT";break;
        case HTTP_METHOD_PATCH:
            setMethod = @"PATCH";break;
        default:
            setMethod = @"GET";break;
    }
    [request setHTTPMethod:setMethod];
    
    // parameters (for adding to the query string if GET, or adding to the body if POST
    if (nil != parameters) {
        switch (method) {
            case HTTP_METHOD_POST:
            case HTTP_METHOD_PUT:
            case HTTP_METHOD_PATCH:
            {
                NSError *error;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                                   options:NSJSONWritingPrettyPrinted
                                                                     error:&error];
                if (jsonData) {
                    [request setHTTPBody:jsonData];
                }
            }
            break;
                
            default:
            {
                NSString *urlString = [request.URL absoluteString];
                NSRange range = [urlString rangeOfString:@"?"];
                BOOL addQMark = (range.location == NSNotFound);
                for (NSString *key in parameters) {
                    if (addQMark) {
                        urlString = [urlString stringByAppendingFormat:@"?%@=%@", key, [parameters valueForKey:key]];
                        addQMark = NO;
                    } else {
                        urlString = [urlString stringByAppendingFormat:@"&%@=%@", key, [parameters valueForKey:key]];
                    }
                }
                [request setURL:[NSURL URLWithString:urlString]];
            }
            break;
        }
    }
    
    [[self URLOperationWithRequest:request
                      withSuccess:successBlock
                        withError:errorBlock] resume];
}

/**
 * Generate a SessionDataTask based on the request and completion handlers
 */
- (NSURLSessionDataTask *)URLOperationWithRequest:(NSMutableURLRequest *)request
                                      withSuccess:(TSNetworkSuccessBlock)successBlock
                                        withError:(TSNetworkErrorBlock)errorBlock
{
    if (nil != self.username && nil != self.password) {
        NSString *base64EncodedString = [[NSString stringWithFormat:@"%@:%@", self.username, self.password] base64EncodedString];
        NSString *valueString = [NSString stringWithFormat:@"Basic %@", base64EncodedString];
        [request setValue:valueString forHTTPHeaderField:@"Authorization"];
    }
    __weak typeof(request) weakRequest = request;
    URLSessionCompletion completion = ^(NSData *data, NSURLResponse *response, NSError *error) {
        [self validateResponse:(NSHTTPURLResponse *)response error:&error];
        if (nil != error) {
            errorBlock(error, weakRequest, response);
            return;
        }
        NSString *contentType;
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSDictionary *responseHeaders = [httpResponse allHeaderFields];
            ASSIGN_NOT_NIL(contentType, [responseHeaders valueForKey:@"Content-Type"]);
            if (nil != contentType) {
                contentType = [contentType lowercaseString];
                NSRange indexOfSemi = [contentType rangeOfString:@";"];
                if (indexOfSemi.location != NSNotFound) {
                    contentType = [contentType substringToIndex:indexOfSemi.location];
                }
            }
        }
        
        NSObject *parsedObject = [self resultBasedOnContentType:contentType
                                                       fromData:data];
        successBlock(parsedObject, weakRequest, response);
    };
    
    NSURLSessionDataTask *task = [self.sharedSession dataTaskWithRequest:request
                                                       completionHandler:completion];
    return task;
}

/**
 * Build an NSObject from the response data based on an optional content-type
 * return an NSDictionary for application/json
 * return an NSSting for text/
 */
- (NSObject *)resultBasedOnContentType:(NSString *)contentType
                              fromData:(NSData *)data
{
    if (nil == contentType) {
        contentType = @"text"; // just parse it as a string
    }
    
    NSRange indexOfSlash = [contentType rangeOfString:@"/"];
    NSString *firstComponent, *secondComponent;
    if (indexOfSlash.location != NSNotFound) {
        firstComponent = [contentType substringToIndex:indexOfSlash.location];
        secondComponent = [contentType substringFromIndex:indexOfSlash.location + 1];
    } else {
        firstComponent = contentType;
    }
    
    NSError *parseError = nil;
    if ([firstComponent isEqualToString:@"application"]) {
        if ([secondComponent isEqualToString:@"json"]) {
            id parsedJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
            return parsedJson;
        }
    } else if ([firstComponent isEqualToString:@"text"]) {
        NSString *parsedString = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];
        return parsedString;
    }
    
    return data;
}

- (BOOL)validateResponse:(NSHTTPURLResponse *)response
                   error:(NSError *__autoreleasing *)error
{
    if (response && [response isKindOfClass:[NSHTTPURLResponse class]]) {
        if (self.acceptableStatusCodes && ![self.acceptableStatusCodes containsIndex:(NSUInteger)response.statusCode]) {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTable(@"Request failed: %@ (%d)", @"TSNetworking", nil), [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode], response.statusCode],
                                       NSURLErrorFailingURLErrorKey:[response URL]
                                       };
            if (error) {
                *error = [[NSError alloc] initWithDomain:@"TSNetworkingErrorDomain" code:NSURLErrorBadServerResponse userInfo:userInfo];
            }
            
            return NO;
        }
    }
    
    return YES;
}


#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;

    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([self.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
            disposition = NSURLSessionAuthChallengeUseCredential;
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        } else {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}


@end
