//
//  UIViewController+Flickr_Alert.m
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/18/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "UIViewController+Flickr_Alert.h"
#import "FlickrAPI.h"
#import "CoreDataStack.h"
#import "Pin+CoreDataClass.h"
#import "Flick+CoreDataClass.h"

@implementation UIViewController (Flickr_Alert)

// download album of flicks for a Pin
- (void)downloadAlbumForPin:(Pin *)pin {
    
    /*
     Handle downloading of Flickr photos into a Pin.
     Each flick received is assigned to a Flick MO which is attached to Pin
     */
    
    // task completion for FlicrAPI methods
    void (^taskCompletion)(NSArray *, NSError *);
    taskCompletion = ^(NSArray *urlStrings, NSError *error) {
        
        // perform on private queue
        NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc]
                                                  initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        privateContext.parentContext = [CoreDataStack.shared.container viewContext];
        [privateContext performBlock:^{
           
            // declare a save block...will be used often below to save
            // context(s) as download progresses
            void (^save)(void);
            save = ^{
                NSError *saveError = nil;
                if (![privateContext save:&saveError]) {
                    NSLog(@"error saving privateContext");
                }
                else {
                    [CoreDataStack.shared save];
                }
            };
            
            // pull Pin into privateContext, set download state and save
            Pin *privatePin = (Pin *)[privateContext objectWithID:pin.objectID];
            privatePin.isDownloading = YES;
            save();
            
            // test for any flicks returned
            if (urlStrings.count == 0) {
                privatePin.isDownloading = NO;
                privatePin.noFlicksAtLocation = YES;
                save();
                return;
            }
            
            /*
             FLickr data and flick creation if performed in two passes. The first pass is to simply retrieve
             the urlString array returned from API call (data) and then create Flick MO's using urlString.
             Upon saving, this will trigger an FRC attached to Pin to reload a collectionView with empty
             placehold default images.
             
             Second pass is to perform actual download of images from Flickr and assign to Flick.
             
             This is done for aesthetic purposes, to give the user immediate feedback on the flicks that
             are to populate a collectionView.
             */
            
            // sort urlStrings...same ordering as FRC in albumVC
            NSArray *sortedUrlStrings = [urlStrings sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

            // array to store flicks as they are created
            // ..used to maintain same ordering as sorted urlStrings
            NSMutableArray *flicks = [[NSMutableArray alloc] init];
            
            // iterate, create new Flick for each url string
            for (NSString *urlString in sortedUrlStrings) {
                
                Flick *flick = [NSEntityDescription insertNewObjectForEntityForName:@"Flick" inManagedObjectContext:privateContext];
                flick.urlString = urlString;
                [privatePin addFlicksObject:flick];
                [flicks addObject:flick];
            }
            
            // save to trigger an frc that might be attached to Pin
            save();
            
            /*
             Now pull image data..
             Flicks are in same order used in FetchResultController
             in AlbumVC..for aesthetic reasons..forces images to load in AlbumVC cells
             in the order of the cells (top to bottom of collectionView)
             */
            for (Flick *flick in flicks) {
                
                NSURL *url = [NSURL URLWithString:flick.urlString];
                if (url) {
                    
                    NSData *imageData = [NSData dataWithContentsOfURL:url];
                    if (imageData) {
                        
                        flick.imageData = imageData;
                        save();
                    }
                }
            }
            
            // done downloading..save to trigger frc
            privatePin.isDownloading = NO;
            save();
        }];
    };
    
    // run API call
    [FlickrAPI.shared downloadFlickrAlbumForLongitude:pin.longitude
                                          andLatitude:pin.latitude
                                           searchPage:nil
                                       withCompletion:taskCompletion];
}

- (void)resumeAlbumDownloadForPin:(Pin *)pin {
    
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc]
                                              initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = [CoreDataStack.shared.container viewContext];
    [privateContext performBlock:^{
        
        void (^save)(void);
        save = ^{
            NSError *saveError = nil;
            if ([privateContext save:&saveError]) {
                NSLog(@"error saving new flick");
            }
            else {
                [CoreDataStack.shared save];
            }
        };
        
        Pin *privatePin = (Pin *)[privateContext objectWithID:pin.objectID];
        privatePin.isDownloading = YES;
        save();
        
        for (Flick *flick in privatePin.flicks) {
            
            if (!flick.imageData) {
                
                NSURL *url = [NSURL URLWithString:flick.urlString];
                if (url) {
                    
                    NSData *imageData = [NSData dataWithContentsOfURL:url];
                    if (imageData) {
                        
                        flick.imageData = imageData;
                        save();
                    }
                }
            }
        }
        
        privatePin.isDownloading = NO;
        save();
    }];
}
@end
