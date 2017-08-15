//
//  MapViewController.m
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/12/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "MapViewController.h"
#import <MapKit/MapKit.h>
#import "FlickrAPI.h"

@interface MapViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"viewDidLoad");
    FlickrAPI *flickrApi = [FlickrAPI shared];
    
    void (^flickrCompletion)(NSArray *, NSError *);
    flickrCompletion = ^(NSArray *array, NSError *error) {
        NSLog(@"flickrCompletion");
        NSLog(@"%@", array);
    };
    
    [flickrApi downloadFlickrAlbumForLongitude:-122.43 andLatitude:37.77 withCompletion:flickrCompletion];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
