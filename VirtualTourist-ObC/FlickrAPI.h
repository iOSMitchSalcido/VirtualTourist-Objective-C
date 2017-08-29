//
//  FlickrAPI.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/14/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//
/*
 About FlickrAPI:
 
 Interface for downloading flicks from Flickr
 */

#import <Foundation/Foundation.h>

#define kApiKeyValue     @"3bc85d1817c25bfd73b8a05ff26a01c3"    // Flickr Key
#define kSearchRadius    @"10.0"                                // search radius
#define kFlickrMaxImageReturn   4000    // max image that Flickr will return
#define kMaxImagesDesired       10     // max images that want to return

@interface FlickrAPI : NSObject

// singleton
+(FlickrAPI *)shared;

/*
 method to download an "album" of flicks.
 longitude/latitude: geo search params, required
 searchPage: !! use nil for random page search !!
 completion: returns an array of strings which are url's to flicks.
*/
- (void)downloadFlickrAlbumForLongitude:(double)longitude
                            andLatitude:(double)latitude
                             searchPage:(NSString *)page // !! nil for random page search !!
                         withCompletion:(void (^)(NSArray *urlStrings, NSError *error))completion;
@end
