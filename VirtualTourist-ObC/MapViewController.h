//
//  MapViewController.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/12/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//
/*
 About MapViewController:
 Handle Pins on a mapView
 - dropping pins initiated by longPress gr
 - config pins with accessory views for deleting pin, navigating into AlbumVC
 - invoke Flickr album download when valid pin is dropped
 */

#import <UIKit/UIKit.h>

// constants for geo accuracy when searching for user location...Search bbi pressed
#define kUserLocationAccuracy 5.0
#define kUserSpacDegrees 0.3

@interface MapViewController : UIViewController
@end

