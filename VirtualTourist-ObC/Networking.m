//
//  Networking.m
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/14/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "Networking.h"

@interface Networking()
- (NSURL *)urlForParams:(NSDictionary *)params;
@end

@implementation Networking

// run a data task using parameters and completion
- (void)dataTaskForParams:(NSDictionary *)params withCompletion:(void (^)(NSDictionary *data, NSError *error))completion {

    /*
     handle creation and running of a data task
     */
     
    // task completion block for NSURLSessionDataTask, below
    void (^taskCompletion)(NSData *, NSURLResponse *, NSError *);
    taskCompletion = ^(NSData *data, NSURLResponse *response, NSError *error) {
        
        // test error
        if (error != nil) {
            NSLog(@"error during dataTask");
            return;
        }
        
        // test response
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = [httpResponse statusCode];
        if ((statusCode <= 199) || (statusCode >= 299)) {
            NSLog(@"non-2xx status code returned");
            return;
        }
        
        // test data
        if (data == nil) {
            NSLog(@"bad/missing data returned");
            return;
        }
        
        // convert data to dictionary
        if ([NSJSONSerialization isValidJSONObject:data]) {
            
            NSError *jsonSerialError = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:NSJSONReadingAllowFragments
                                                                   error:&jsonSerialError];
            
            completion(json, nil);
        }
        else {
            completion(nil, nil);
        }
    };
    
    // test for good URL
    NSURL *url = [self urlForParams:params];
    if (url == nil) {
        NSLog(@"bad url");
        return;
    }
    
    // create request, get session, create task, run
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:taskCompletion];
    [task resume];
}

// create URL from parameters
- (NSURL *)urlForParams:(NSDictionary *)params {
    
    /*
     parse params and create/return url
     */
    
    // create components and add subcomponents
    NSURLComponents *components = [[NSURLComponents alloc] init];
    [components setHost:params[kNetworkHost]];
    [components setScheme:params[kNetworkScheme]];
    [components setPath:params[kNetworkPath]];
    
    // add queryItems
    NSDictionary *searchItems = params[kNetworkItems];
    NSArray *keys = searchItems.allKeys;
    NSMutableArray *queryItems = [[NSMutableArray alloc] init];
    for (NSString *key in keys) {
        NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:key value:searchItems[key]];
        [queryItems addObject:item];
    }
    
    [components setQueryItems:queryItems];
    
    return [components URL];
}
@end
