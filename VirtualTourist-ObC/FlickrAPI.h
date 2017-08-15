//
//  FlickrAPI.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/14/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FlickrAPI : NSObject
+(FlickrAPI *)shared;

- (void)downloadFlickrAlbumForLongitude:(double)longitude andLatitude:(double)latitude withCompletion:(void (^)(NSArray *urlStrings, NSError *error))completion;
@end
