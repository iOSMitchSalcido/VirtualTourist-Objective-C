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

// ..save a VC. Done bbi can use this to dismiss VC
- (IBAction)doneBbiPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Flickr Download Methods
// download album of flicks for a Pin
- (void)downloadAlbumForPin:(Pin *)pin {
    
    /*
     Handle downloading of Flickr photos into a Pin.
     Each flick received is assigned to a Flick MO which is attached to Pin
     */
    
    // set download state of Pin
    pin.isDownloading = YES;
    
    // task completion for FlicrAPI methods
    void (^taskCompletion)(NSArray *, NSError *);
    taskCompletion = ^(NSArray *urlStrings, NSError *error) {
        
        // perform on private queue
        NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc]
                                                  initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        privateContext.parentContext = [CoreDataStack.shared.container viewContext];
        [privateContext performBlock:^{
           
            // pull Pin into privateContext
            Pin *privatePin = (Pin *)[privateContext objectWithID:pin.objectID];
             
            // test error
            if (error) {
                privatePin.isDownloading = NO;
                privatePin.noFlicksAtLocation = NO;
                [CoreDataStack.shared savePrivateContext:privateContext];
                return;
            }
            
            // test for any flicks returned
            if (urlStrings.count == 0) {
                privatePin.isDownloading = NO;
                privatePin.noFlicksAtLocation = YES;
                [CoreDataStack.shared savePrivateContext:privateContext];
                return;
            }
            
            /*
             Flickr data and flick creation if performed in two passes. The first pass is to simply retrieve
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
            [CoreDataStack.shared savePrivateContext:privateContext];
            
            /*
             Now pull image data..
             Flicks are in same order used in FetchResultController
             in AlbumVC..for aesthetic reasons..forces images to load in AlbumVC cells
             in the order of the cells (top to bottom of collectionView)
             */
            for (Flick *flick in flicks) {
                
                // test for valid url
                NSURL *url = [NSURL URLWithString:flick.urlString];
                if (url) {
                    
                    // test for valid data
                    NSData *imageData = [NSData dataWithContentsOfURL:url];
                    if (imageData) {
                        
                        // good data..save to flick
                        flick.imageData = imageData;
                        [CoreDataStack.shared savePrivateContext:privateContext];
                    }
                }
            }
            
            // done downloading..save to trigger frc
            privatePin.isDownloading = NO;
            [CoreDataStack.shared savePrivateContext:privateContext];
        }];
    };
    
    // run API call
    [FlickrAPI.shared downloadFlickrAlbumForLongitude:pin.longitude
                                          andLatitude:pin.latitude
                                           searchPage:nil
                                       withCompletion:taskCompletion];
}

- (void)resumeAlbumDownloadForPin:(Pin *)pin {
    
    // set download state of Pin
    pin.isDownloading = YES;
    
    // perform on private queue
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc]
                                              initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = [CoreDataStack.shared.container viewContext];
    [privateContext performBlock:^{
        
        // pull Pin into privateContext
        Pin *privatePin = (Pin *)[privateContext objectWithID:pin.objectID];
        
        
        // sort urlStrings...same ordering as FRC in albumVC
        NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"urlString"
                                                                   ascending:true
                                                                    selector:@selector(caseInsensitiveCompare:)];
        NSArray *sortedFlicks = [privatePin.flicks sortedArrayUsingDescriptors:@[sortDesc]];
        
        // iterate thru flicks
        for (Flick *flick in sortedFlicks) {
            
            // test valid imageData
            if (!flick.imageData) {
                
                // test valid URL
                NSURL *url = [NSURL URLWithString:flick.urlString];
                if (url) {
                    
                    // test valid data
                    NSData *imageData = [NSData dataWithContentsOfURL:url];
                    if (imageData) {
                        
                        // done downloading..save to trigger frc
                        flick.imageData = imageData;
                        [CoreDataStack.shared savePrivateContext:privateContext];
                    }
                }
            }
        }
        
        // done with download, save
        privatePin.isDownloading = NO;
        [CoreDataStack.shared savePrivateContext:privateContext];
    }];
}

#pragma mark - Alert Creation Methods
// present an alert with an "OK" button for a title and message
- (void)presentOKAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
    
    [alertController addAction:action];
    
    [self presentViewController:alertController
                       animated:true
                     completion:nil];
}

// present an alert with an "OK" button for an NSError
- (void)presentOKAlertForError:(NSError *)error {
    
    if (error)
        [self presentOKAlertWithTitle:error.localizedDescription andMessage:error.localizedFailureReason];
}

// present an alert with a "Cancel" and "Proceed" button and completion
- (void)presentCancelProceedAlertWithTitle:(NSString *)title
                                   message:(NSString *)message
                                completion:(void (^)(void))completion {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed"
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction *action) {
                                                              completion();
                                                          }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:proceedAction];
    [self presentViewController:alertController animated:true completion:nil];
}
@end
