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

/*** Flickr Download Methods ***/
// begin a new flick download for a Pin
- (void)downloadAlbumForPin:(Pin *)pin;

// resume downloading an flick album ..used when app is interupted during download.
- (void)resumeAlbumDownloadForPin:(Pin *)pin;


/*** Alert Methods ***/
// present an alert with an "OK" button
- (void)presentOKAlertWithTitle:(NSString *)title andMessage:(NSString *)message;

// present an alert with an "OK" button for an NSError
- (void)presentOKAlertForError:(NSError *)error;


/*** NSError Methods ***/
- (NSError *)errorForLocalizedDescription:(NSString *)description andReason:(NSString *)reason;
@end
