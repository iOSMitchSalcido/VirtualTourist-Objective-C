//
//  FlickrAPI.m
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/14/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "FlickrAPI.h"
#import "Networking.h"

@interface FlickrAPI()
@property (nonatomic, strong) Networking *networking;

- (NSDictionary *)createPhotoSearchParamsLongitude:(double)lon latitude:(double)lat searchPage:(NSString *)page;
@end

@implementation FlickrAPI

+(FlickrAPI *)shared {
    
    // singleton
    static FlickrAPI *shared = nil;
    dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        shared = [[FlickrAPI alloc] init];
    });
    
    return  shared;
}

// download an album from flickr
- (void)downloadFlickrAlbumForLongitude:(double)longitude
                            andLatitude:(double)latitude
                             searchPage:(NSString *)page
                         withCompletion:(void (^)(NSArray *urlStrings, NSError *error))completion {
    
    /*
     Handle downloading an "album" of flicks from flickr.
     
     Method is intended to be called with searchPage nil. This method is called recursively, first pass
     determines the number of pages returned from flickr. A random page is selected based on number of
     pages returned, and then this function is called with searchPage set to NSString representation of
     the random page.
     */
    
    // params
    NSDictionary *params = [self createPhotoSearchParamsLongitude:longitude latitude:latitude searchPage:page];

    // completion
    void (^taskCompletion)(NSDictionary *, NSError *);
    taskCompletion = ^(NSDictionary *data, NSError *error) {
        
        // test error
        if (error) {
            completion(nil, error);
            return;
        }
        
        // test photos
        NSDictionary *photosDictionary = data[@"photos"];
        if (photosDictionary == nil) {
        
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Bad Flickr Data",
                                       NSLocalizedFailureReasonErrorKey: @"Missing photo dictionary"};
            completion(nil, [NSError errorWithDomain:@"VT-Error"
                                                code:0
                                            userInfo:userInfo]);
            return;
        }
        
        // test for nil search page
        NSDictionary *searchItems = params[kNetworkItems];
        if (searchItems[@"page"] == nil) {
            
            /*
             searchPage was NOT a search param...proceed to compute a random
             search page and call method again.
             */
            NSString *pagesString = photosDictionary[@"pages"];
            NSString *perPageString = photosDictionary[@"perpage"];
            NSInteger pages = [pagesString integerValue];
            NSInteger perPage = [perPageString integerValue];
            NSInteger maxPages = kFlickrMaxImageReturn / perPage;
            
            // test within bounds of available flicks
            if (pages <= maxPages)
                maxPages = pages;
            
            // random page
            NSInteger randomPage = arc4random_uniform((int)maxPages) + 1;
            
            // new search
            [self downloadFlickrAlbumForLongitude:longitude
                                      andLatitude:latitude
                                       searchPage:[NSString stringWithFormat:@"%ld", (long)randomPage]
                                   withCompletion:completion];
        }
        else {
            
            /*
             searchPage was a search param. Proceed to retrieve url strings for flicks. Place
             url strings into an array and fire completion.
             */
            
            // test photo array
            NSArray *photoArray = photosDictionary[@"photo"];
            if (photoArray == nil) {
                
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Bad Flickr Data",
                                           NSLocalizedFailureReasonErrorKey: @"Missing photos array"};
                completion(nil, [NSError errorWithDomain:@"VT-Error"
                                                    code:0
                                                userInfo:userInfo]);
                return;
            }
            
            // place url strings into array
            NSMutableArray *urlStringsArray = [[NSMutableArray alloc] init];
            for (NSDictionary *photoDictionary in photoArray) {
                
                NSString *urlString = photoDictionary[@"url_m"];
                if ((urlString != nil) && (urlStringsArray.count <= kMaxImagesDesired - 1))
                    [urlStringsArray addObject:urlString];
            }
            
            // fire completion
            completion(urlStringsArray, nil);
        }
    };
    
    [self.networking dataTaskForParams:params withCompletion:taskCompletion];
}

// helper function to create params used by data task for flick search
- (NSDictionary *)createPhotoSearchParamsLongitude:(double)lon latitude:(double)lat searchPage:(NSString *)page {
    
    /*
     Build params for network task using location, page, and constants defined below...
     */
    
    // build base params
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
    
    // include page search if non-nil
    if (page != nil)
        searchItems[@"page"] = page;
    
    // return params for task
    return @{kNetworkItems: searchItems,
             kNetworkHost: @"api.flickr.com",
             kNetworkScheme: @"https",
             kNetworkPath: @"/services/rest"};
}

// getter for Networking
- (Networking *)networking {
    
    if (_networking)
        return _networking;
    
    _networking = [[Networking alloc] init];
    
    return _networking;
}
@end
