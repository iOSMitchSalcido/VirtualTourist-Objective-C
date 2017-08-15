//
//  FlickrAPI.m
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/14/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "FlickrAPI.h"
#import "Networking.h"

#define kApiKeyValue     @"3bc85d1817c25bfd73b8a05ff26a01c3"
#define kSearchRadius    @"10.0"

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
        
        if (data == nil) {
            NSLog(@"nil data");
            return;
        }
        
        NSDictionary *photosDictionary = data[@"photos"];
        if (photosDictionary == nil) {
            NSLog(@"bad photos dictionary");
            return;
        }
        
        NSArray *photosArray = photosDictionary[@"photo"];
        if (photosArray == nil) {
            NSLog(@"bad photo array");
            return;
        }
        
        NSMutableArray *urlStringsArray = [[NSMutableArray alloc] init];
        for (NSDictionary *photoDictionary in photosArray) {
            NSArray *keys = photoDictionary.allKeys;
            for (NSString *key in keys) {
                if ([key isEqualToString:@"url_m"])
                    [urlStringsArray addObject:photoDictionary[key]];
            }
        }
        
        completion(urlStringsArray, nil);
    };
    
    NSDictionary *params = [self createPhotoSearchParamsLongitude:longitude latitude:latitude searchPage:nil];    
    [self.networking dataTaskForParams:params withCompletion:taskCompletion];
}

- (NSDictionary *)createPhotoSearchParamsLongitude:(double)lon latitude:(double)lat searchPage:(NSString *)page {
    
    NSMutableDictionary *searchItems = [[NSMutableDictionary alloc] init];
    searchItems[@"method"] = @"flickr.photos.search";
    searchItems[@"api_key"] = kApiKeyValue;
    searchItems[@"format"] = @"json";
    searchItems[@"nojsoncallback"] = @"1";
    searchItems[@"safe_search"] = @"1";
    searchItems[@"extras"] = @"url_m";
    searchItems[@"lon"] = [NSString stringWithFormat:@"%f", lon];
    searchItems[@"lat"] = [NSString stringWithFormat:@"%f", lat];
    searchItems[@"radius"] = kSearchRadius;
    
    if (page != nil)
        searchItems[@"page"] = page;
    
    return @{kNetworkItems: searchItems,
             kNetworkHost: @"api.flickr.com",
             kNetworkScheme: @"https",
             kNetworkPath: @"/services/rest"};
}

- (Networking *)networking {
    
    if (_networking)
        return _networking;
    
    _networking = [[Networking alloc] init];
    
    return _networking;
}
@end
