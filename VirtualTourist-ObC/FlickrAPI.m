//
//  FlickrAPI.m
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/14/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "FlickrAPI.h"
#import "Networking.h"

#define apiKeyValue     @"3bc85d1817c25bfd73b8a05ff26a01c3"
#define searchRadius    @"10.0"

@interface FlickrAPI()
@property (nonatomic, strong) Networking *networking;

- (NSDictionary *)createPhotoSearchParamsLongitude:(double)lon latitude:(double)lat searchPage:(NSString *)page;
@end

@implementation FlickrAPI

+(FlickrAPI *)shared {
    
    static FlickrAPI *shared = nil;
    
    dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        shared = [[FlickrAPI alloc] init];
    });
    
    return  shared;
}

- (void)downloadFlickrAlbumForLongitude:(double)longitude
                            andLatitude:(double)latitude
                         withCompletion:(void (^)(NSArray *urlStrings, NSError *error))completion {
    
    void (^taskCompletion)(NSDictionary *, NSError *);
    taskCompletion = ^(NSDictionary *data, NSError *error) {
        
        if (error != nil) {
            NSLog(@"error in downloadFlickr..");
            return;
        }
        
        NSLog(@"%@", data);
        completion(nil, nil);
    };
    
    NSDictionary *params = [self createPhotoSearchParamsLongitude:longitude latitude:latitude searchPage:nil];    
    [self.networking dataTaskForParams:params withCompletion:taskCompletion];
}

- (NSDictionary *)createPhotoSearchParamsLongitude:(double)lon latitude:(double)lat searchPage:(NSString *)page {
    /*
     var items = ["method": FlickrAPI.Methods.photosSearch,
     FlickrAPI.Keys.apiKey: FlickrAPI.Values.apiKey,
     FlickrAPI.Keys.format: FlickrAPI.Values.json,
     FlickrAPI.Keys.extras: FlickrAPI.Values.mediumURL,
     FlickrAPI.Keys.nojsoncallback: FlickrAPI.Values.nojsoncallback,
     FlickrAPI.Keys.safeSearch: FlickrAPI.Values.safeSearch,
     FlickrAPI.Keys.longitude: "\(coordinate.longitude)",
     FlickrAPI.Keys.latitude: "\(coordinate.latitude)",
     FlickrAPI.Keys.radius: "\(self.searchRadius)"]
     
     // include page search if non-nil
     if let page = page {
     items["page"] = "\(page)"
     }
     
     // return params for task
     return [Networking.Keys.items: items as AnyObject,
     Networking.Keys.host: FlickrAPI.Subcomponents.host as AnyObject,
     Networking.Keys.scheme: FlickrAPI.Subcomponents.scheme as AnyObject,
     Networking.Keys.path: FlickrAPI.Subcomponents.path as AnyObject]
     */
    
    NSMutableDictionary *searchItems = [[NSMutableDictionary alloc] init];
    searchItems[@"method"] = @"flickr.photos.search";
    searchItems[@"api_key"] = apiKeyValue;
    searchItems[@"format"] = @"json";
    searchItems[@"nojsoncallback"] = @"1";
    searchItems[@"safe_search"] = @"1";
    searchItems[@"extras"] = @"url_m";
    searchItems[@"lon"] = [NSString stringWithFormat:@"%f", lon];
    searchItems[@"lat"] = [NSString stringWithFormat:@"%f", lat];
    searchItems[@"radius"] = searchRadius;
    
    if (page != nil)
        searchItems[@"page"] = page;
    
    return @{@"items": searchItems,
             @"host": @"api.flickr.com",
             @"scheme": @"https",
             @"path": @"/services/rest"};
}

- (Networking *)networking {
    
    if (_networking)
        return _networking;
    
    _networking = [[Networking alloc] init];
    
    return _networking;
}
@end
