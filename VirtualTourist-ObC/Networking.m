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

- (void)dataTaskForParams:(NSDictionary *)params withCompletion:(void (^)(NSDictionary *data, NSError *error))completion {
    
    /*
     // test for good url
     guard let url = urlForParameters(params) else {
     completion(nil, NetworkingError.url("Unusable or missing URL."))
     return
     }
     
     // create request
     let request = URLRequest(url: url)
     
     // create request
     let task = URLSession.shared.dataTask(with: request) {
     (data, response, error) in
     
     // check error
     guard error == nil else {
     completion(nil, NetworkingError.task)
     return
     }
     
     // check status code in response..test for non 2xx
     guard let status = (response as? HTTPURLResponse)?.statusCode,
     status >= 200, status <= 299 else {
     if let status = (response as? HTTPURLResponse)?.statusCode {
     completion(nil, NetworkingError.response(status))
     }
     else {
     completion(nil, NetworkingError.response(nil))
     }
     return
     }
     
     // check data
     guard let data = data else {
     completion(nil, NetworkingError.data("Bad or missing data returned."))
     return
     }
     
     // convert data to json
     var jsonData: [String: AnyObject]!
     do {
     jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
     } catch {
     completion(nil, NetworkingError.data("Unable to convert returned network data to usable JSON format."))
     return
     }
     
     // good data. Fire completion using good data
     completion(jsonData, nil)
     }
     
     // fire task
     task.resume()
     */
    
    NSURL *url = [self urlForParams:params];
    if (url == nil) {
        NSLog(@"bad url");
        return;
    }
    
    NSLog(@"%@", url);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];

    void (^taskCompletion)(NSData *, NSURLResponse *, NSError *);
    taskCompletion = ^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error != nil) {
            NSLog(@"error during dataTask");
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = [httpResponse statusCode];
        if ((statusCode <= 199) || (statusCode >= 299)) {
            NSLog(@"non-2xx status code returned");
            return;
        }
        
        if (data == nil) {
            NSLog(@"bad/missing data returned");
            return;
        }
        
        NSError *jsonSerialError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                             options:NSJSONReadingAllowFragments
                                                               error:&jsonSerialError];
        completion(json, nil);
    };
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:taskCompletion];
    [task resume];
}

- (NSURL *)urlForParams:(NSDictionary *)params {
    
    /*
     // create components and add subcomponents
     var components = URLComponents()
     components.host = params[Networking.Keys.host] as? String
     components.scheme = params[Networking.Keys.scheme] as? String
     components.path = params[Networking.Keys.path] as! String
     
     // add queryItems
     let items = params[Networking.Keys.items] as! [String:String]
     var queryItems = [URLQueryItem]()
     for (key, value) in  items {
     let item = URLQueryItem(name: key, value: "\(value)")
     queryItems.append(item)
     }
     components.queryItems = queryItems
     
     return components.url
     */
    
    NSURLComponents *components = [[NSURLComponents alloc] init];
    [components setHost:params[@"host"]];
    [components setScheme:params[@"scheme"]];
    [components setPath:params[@"path"]];
    
    NSDictionary *searchItems = params[@"items"];
    NSArray *keys = searchItems.allKeys;
    NSMutableArray *queryItems = [[NSMutableArray alloc] init];
    for (NSString *key in keys) {
        NSLog(@"%@", key);
        NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:key value:searchItems[key]];
        [queryItems addObject:item];
    }

    [components setQueryItems:queryItems];
    
    return [components URL];
}
@end
