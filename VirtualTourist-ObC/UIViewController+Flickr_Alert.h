//
//  UIViewController+Flickr_Alert.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/18/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Pin+CoreDataClass.h"

@interface UIViewController (Flickr_Alert)

// begin a new flick download for a Pin
- (void)downloadAlbumForPin:(Pin *)pin;

/*
 resume downloading an flick album ..used when app is interupted during download,
 so not all Flicks have valid imageData
*/
- (void)resumeAlbumDownloadForPin:(Pin *)pin;
@end
