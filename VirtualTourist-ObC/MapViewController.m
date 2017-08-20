//
//  MapViewController.m
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/12/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "MapViewController.h"
#import "AlbumViewController.h"
#import "UIViewController+Flickr_Alert.h"
#import <MapKit/MapKit.h>
#import "VTAnnotation.h"
#import "CoreDataStack.h"

@interface MapViewController () <MKMapViewDelegate, CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) VTAnnotation *dragAnnotation;
@property (weak, nonatomic) NSManagedObjectContext *viewContext;
@property (strong, nonatomic) CLLocationManager *locationManager;

// add a new Pin to an annotation
- (void)addPinToAnnotation:(VTAnnotation *)annotation;

// create an annotation from a Pin
- (VTAnnotation *)annotationForPin:(Pin *)pin;
@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // mapView delegate
    _mapView.delegate = self;
    
    // add long press gr.. used to drop pin after valid long press detected
    UILongPressGestureRecognizer *gr = [[UILongPressGestureRecognizer alloc] init];
    [gr addTarget:self action:@selector(longPressDetected:)];
    [gr setMinimumPressDuration:0.5];
    [gr setNumberOfTouchesRequired:1];
    [self.view addGestureRecognizer:gr];
    
    // core location setup
    CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer * kUserLocationAccuracy;
    self.locationManager.distanceFilter = kCLLocationAccuracyKilometer * kUserLocationAccuracy;
    self.locationManager.delegate = self;

    // test auth...request auth
    if (authStatus == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    // fetch Pin's
    NSFetchRequest *request = [Pin fetchRequest];
    NSError *error = nil;
    NSArray *Pins = [self.viewContext executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"error fetching pins");
    }
    else {
        for (Pin *pin in Pins) {
            VTAnnotation *annotation = [self annotationForPin:pin];
            [_mapView addAnnotation:annotation];
        }
    }
}

// prep for segueu
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // test segeu
    if ([segue.identifier  isEqual: @"AlbumViewControllerSegueID"]) {
        
        // segeu to AlbumVC. sender is Pin object to pass to Album VC
        AlbumViewController *controller = segue.destinationViewController;
        controller.pin = (Pin *)sender;
    }
}

#pragma mark - MapView Delegate Methods
// annotationView
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    /*
     AnnotView for annot.
     Handle creation of pin annot view. Includes pin location title, and accessories on left/right
     to invoke Pin deletion or navigation to AlbumVC for viewing flicks
     */
    
    // dequeue a view
    MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"MapViewPinID"];
    
    // create if no view
    if (pinView == nil) {
        
        // create and config
        pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                  reuseIdentifier:@"MapViewPinID"];
        pinView.pinTintColor = [UIColor greenColor];
        pinView.canShowCallout = YES;
        pinView.animatesDrop = YES;
        
        // left callout
        UIButton *leftCalloutAccessory = [UIButton buttonWithType:UIButtonTypeCustom];
        leftCalloutAccessory.frame = CGRectMake(0, 0, 22, 22);
        [leftCalloutAccessory setImage:[UIImage imageNamed:@"LeftCalloutAccessoryImage"]
                              forState:UIControlStateNormal];
        pinView.leftCalloutAccessoryView = leftCalloutAccessory;
        
        // right callout
        UIButton *rightCalloutAccessory = [UIButton buttonWithType:UIButtonTypeCustom];
        rightCalloutAccessory.frame = CGRectMake(0, 0, 22, 22);
        [rightCalloutAccessory setImage:[UIImage imageNamed:@"RightCalloutAccessoryImage"]
                              forState:UIControlStateNormal];
        pinView.rightCalloutAccessoryView = rightCalloutAccessory;
    }
    
    // assign annotation to view, return view
    pinView.annotation = annotation;
    return pinView;
}

// accessoryView tapped
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    
    /*
     callout accessory tapped. Handle Pin deletion or navigating into AlbumVC
     */
    
    // retreive annotation and Pin
    VTAnnotation *annotation = (VTAnnotation *)view.annotation;
    Pin *pin = annotation.pin;
    
    // test for Pin
    if (pin == nil) {
        NSLog(@"nil Pin");
        return;
    }
    
    if (control == view.leftCalloutAccessoryView) {
        
        // left callout. Delete Pin

        // remove Pin from mapView
        [mapView removeAnnotation:annotation];
        
        /*
         delete pin on a private queue. Create a private context with main viewContext as
         parent. Perform block on private context.
         */
        NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc]
                                                  initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        privateContext.parentContext = self.viewContext;
        [privateContext performBlock:^{
            
            // pull pin into private context, then delete
            Pin *privatePin = (Pin *)[privateContext objectWithID:pin.objectID];
            [privateContext deleteObject:privatePin];
            
            // save private context followed by main viewContext
            NSError *error = nil;
            if (![privateContext save:&error]) {
                NSLog(@"Error saving private context: %@\n%@", [error localizedDescription], [error userInfo]);
                abort();
            }
            else {
             
                [self.viewContext performBlock:^{
                    
                    NSError *error = nil;
                    if (![self.viewContext save:&error]) {
                        NSLog(@"Error saving private context: %@\n%@", [error localizedDescription], [error userInfo]);
                        abort();
                    }
                }];
            }
        }];
    }
    else if (control == view.rightCalloutAccessoryView) {
        
        // right callout. Segue into AlbumVC
        [self performSegueWithIdentifier:@"AlbumViewControllerSegueID" sender:pin];
    }
}

#pragma mark - PIN <-> Annotation Methods
// add a new Pin to an annotation
- (void)addPinToAnnotation:(VTAnnotation *)annotation {
 
    /*
     Handle creation of a Pin MO to attached to an annotation.
     Perform reverse geocode on annot coordinates, looking for valid placemark data. The location
     info (name/title of location, state, name of city, etc) retrieved from the placemark. This
     is used to set the title in the newly created Pin MO.
     
     ...an album is then downloaded for the Pin
     */
    
    // pull coordinate and make a location from annotation
    CLLocationCoordinate2D coordinate = annotation.coordinate;
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude
                                                      longitude:coordinate.longitude];
    
    // block for reverse geocode completion
    void (^reverseGeocodeBlock)(NSArray *, NSError *);
    reverseGeocodeBlock = ^(NSArray *placemarks, NSError *error) {
        
        // test error..remove annotation from map if error
        if (error != nil) {
            NSLog(@"Error in geocoding location");
            [_mapView removeAnnotation:annotation];
            return;
        }
        
        // declare a default locationTitle...test placemark data for valid title
        NSString *locationTitle = @"Location";
        CLPlacemark *placemark = placemarks.firstObject;
        if (placemark != nil) {
            
            if (placemark.locality != nil)
                locationTitle = placemark.locality;
            else if (placemark.administrativeArea != nil)
                locationTitle = placemark.administrativeArea;
            else if (placemark.country != nil)
                locationTitle = placemark.country;
            else if (placemark.ocean != nil)
                locationTitle = placemark.ocean;
        }
        
        // set annotaion title
        annotation.title = locationTitle;
        
        // create a new Pin MO. Assign title and geo info
        Pin *newPin = [NSEntityDescription insertNewObjectForEntityForName:@"Pin"
                                                    inManagedObjectContext:self.viewContext];
        newPin.latitude = annotation.coordinate.latitude;
        newPin.longitude = annotation.coordinate.longitude;
        newPin.title = locationTitle;
        
        // save
        NSError *saveError = nil;
        if (![self.viewContext save:&saveError]) {
            NSLog(@"Error saving private context: %@\n%@", [error localizedDescription], [error userInfo]);
            abort();
        }
        else {
            
            // good save.. assign pin to annotation and begin album download
            annotation.pin = newPin;
            [self downloadAlbumForPin:newPin];
        }
    };

    // create geoCoder, reverse geoCode the location
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:location completionHandler:reverseGeocodeBlock];
}

// create an annotation from a Pin
- (VTAnnotation *)annotationForPin:(Pin *)pin {
    
    // Create an annotation from Pin
    VTAnnotation *annotation = [[VTAnnotation alloc] init];
    annotation.pin = pin;
    annotation.title = pin.title;
    annotation.coordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude);
    
    return annotation;
}

#pragma mark - LocationManager Delegate Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    /*
     response to user pressing search bbi to locate their position on map.
     */
    
    // get location
    CLLocation *location = [locations lastObject];
    if (location) {
        
        // good location...zoom to location on mapView
        CLLocationCoordinate2D coordinate = location.coordinate;
        MKCoordinateSpan span = MKCoordinateSpanMake(kUserSpacDegrees, kUserSpacDegrees);
        MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, span);
        [_mapView setRegion:region animated:YES];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    NSLog(@"location failure");
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    /*
     location services authorization. If auth good, place search bbi on right navbar that allows
     user to zoom in on their current location.
     */
    
    // test status
    switch (status) {
        case kCLAuthorizationStatusAuthorizedWhenInUse: {

            // auth good. Place searchBbi on right navBar for user to zoom to their location
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                      initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                      target:self
                                                      action:@selector(searchBbiPressed:)];
        }
            break;
        default:
            break;
    }
}

#pragma mark - Gesture Action Methods
- (void)longPressDetected:(UILongPressGestureRecognizer *)sender {
    
    /*
     Action for long press gesture.
     Handle new pin placement and also pin dragging. Pin is placed on beginning of gesture. If user
     drags pin, then 'StateChanged updates postion of pin by using a reference to the annotation. At end
     of gesture, Pin MO is created and assigned to annot.
     */
    
    // retrieve location
    CGPoint touchPoint = [sender locationInView:_mapView];
    CLLocationCoordinate2D coordinate = [_mapView convertPoint:touchPoint
                                          toCoordinateFromView:_mapView];
    
    // test gr state
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            // begin. Add annotation to map
            VTAnnotation *annot = [[VTAnnotation alloc] init];
            annot.coordinate = coordinate;
            [_mapView addAnnotation:annot];
            _dragAnnotation = annot;
        }
            break;
        case UIGestureRecognizerStateChanged: {
            // position changed. Move annotation to new location
            if (_dragAnnotation) {
                _dragAnnotation.coordinate = coordinate;
            }
        }
            break;
        case UIGestureRecognizerStateEnded: {
            // end. Place annotation at final location
            if (_dragAnnotation) {
                _dragAnnotation.coordinate = coordinate;
            }
            
            // fire method to attach a new Pin MO to annotation
            [self addPinToAnnotation:_dragAnnotation];
            
            // nil ref..not needed
            _dragAnnotation = nil;
        }
            break;
        default:
            break;
    }
}

#pragma mark - BarButtonItem Action Methods
- (void)searchBbiPressed:(id)sender {
    
    /*
     Invoke location request from locationManager...delegate methods handle zoom
     to user location
     */
    [self.locationManager requestLocation];
}

#pragma mark - Object Getters
- (NSManagedObjectContext *)viewContext {
    // main viewContext
    if (_viewContext)
        return _viewContext;
    _viewContext = CoreDataStack.shared.container.viewContext;
    return _viewContext;
}

- (CLLocationManager *)locationManager {

    // location manager
    if (_locationManager)
        return _locationManager;
    
    _locationManager = [[CLLocationManager alloc] init];
    
    return _locationManager;
}
@end

