//
//  FlickrAPI.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/14/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kApiKeyValue     @"3bc85d1817c25bfd73b8a05ff26a01c3"
#define kSearchRadius    @"10.0"
#define kFlickrMaxImageReturn   4000
#define kMaxImagesDesired       50

@interface FlickrAPI : NSObject
+(FlickrAPI *)shared;

- (void)downloadFlickrAlbumForLongitude:(double)longitude
                            andLatitude:(double)latitude
                             searchPage:(NSString *)page
                         withCompletion:(void (^)(NSArray *urlStrings, NSError *error))completion;
@end
