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

//*** Properties ***
// ref to mapView. Primary view object in VC
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

// ref to annotation used to track dropped pin when user is dragging prior to final placement
@property (weak, nonatomic) VTAnnotation *dragAnnotation;

// ref to MO container viewContext
@property (weak, nonatomic) NSManagedObjectContext *viewContext;

// ref to locationManager...used to retrieve user location when search bbi is pressed
@property (strong, nonatomic) CLLocationManager *locationManager;


//*** Methods ***
// add a new Pin to an annotation.
- (void)addPinToAnnotation:(VTAnnotation *)annotation;

// create an annotation from a Pin.
- (VTAnnotation *)annotationForPin:(Pin *)pin;

// UIBarButtonItem action methods
- (void)searchBbiPressed:(id)sender;    // find user location
- (void)appInfoBbiPressed:(id)sender;   // invoke AppInfo VC
@end

@implementation MapViewController

#pragma mark - View Lifecycle
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
    
    // info bbi on left navbar..invoke AppInfo VC
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [infoButton addTarget:self
                   action:@selector(appInfoBbiPressed:)
         forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *infoBbi = [[UIBarButtonItem alloc]
                                initWithCustomView:infoButton];
    self.navigationItem.leftBarButtonItem = infoBbi;
    
    // fetch Pin's
    NSFetchRequest *request = [Pin fetchRequest];
    NSError *error = nil;
    NSArray *Pins = [self.viewContext executeFetchRequest:request error:&error];
    if (error) {
        [self presentOKAlertForError:error];
    }
    else {
        // good fetch. Retrieve an annotaion for each Pin..add to mapView
        for (Pin *pin in Pins) {
            VTAnnotation *annotation = [self annotationForPin:pin];
            [_mapView addAnnotation:annotation];
            
            // test if flick download was completed..resume if not
            if (!pin.downloadComplete)
                [self resumeAlbumDownloadForPin:pin];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // test segue
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
        
        // left callout.... delete Pin
        UIButton *leftCalloutAccessory = [UIButton buttonWithType:UIButtonTypeCustom];
        leftCalloutAccessory.frame = CGRectMake(0, 0, 22, 22);
        [leftCalloutAccessory setImage:[UIImage imageNamed:@"LeftCalloutAccessoryImage"]
                              forState:UIControlStateNormal];
        pinView.leftCalloutAccessoryView = leftCalloutAccessory;
        
        // right callout... navigate to AlbumVC
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
        [self presentOKAlertWithTitle:@"Bad Pin" andMessage:@"Missing data for annotation"];
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
            
            // save private context..present an alert if error
            [self presentOKAlertForError:
             [CoreDataStack.shared savePrivateContext:privateContext]];
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
     info (name/title of location, state, name of city, etc) is retrieved from the placemark. This
     is used to set the title in the newly created Pin MO.
     
     ...an album is then downloaded for the Pin
     */
    
    // block for reverse geocode completion
    void (^reverseGeocodeBlock)(NSArray *, NSError *);
    reverseGeocodeBlock = ^(NSArray *placemarks, NSError *error) {
        
        // test error..remove annotation from map if error
        if (error != nil) {
            [self presentOKAlertForError:error];
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
        
        // perform Pin creation on private queue
        NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc]
                                                  initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        privateContext.parentContext = [CoreDataStack.shared.container viewContext];
        [privateContext performBlock:^{
            
            // create new Pin, assign coordinate info
            Pin *pin = [NSEntityDescription insertNewObjectForEntityForName:@"Pin"
                                                     inManagedObjectContext:privateContext];
            pin.latitude = annotation.coordinate.latitude;
            pin.longitude = annotation.coordinate.longitude;
            pin.title = locationTitle;
            
            // save
            NSError *saveError = [CoreDataStack.shared savePrivateContext:privateContext];
            
            // test error
            if (saveError) {
                
                // bad save...remove annotation, show alert
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.mapView removeAnnotation:annotation];
                    [self presentOKAlertForError:error];
                });
            }
            else {
               
                // good save...add pin/title to annotaion, start album download
                dispatch_async(dispatch_get_main_queue(), ^{
            
                    Pin *newPin = [self.viewContext objectWithID:pin.objectID];
                    annotation.pin = newPin;
                    annotation.title = locationTitle;
                    [self downloadAlbumForPin:newPin];
                });
            }
        }];
    };

    // make a location from annotation
    CLLocation *location = [[CLLocation alloc] initWithLatitude:annotation.coordinate.latitude
                                                      longitude:annotation.coordinate.longitude];
    
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
    
    /*
     failed user location search
     */
    [self presentOKAlertForError:error];
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
// search bbi pressed. Locate user
- (void)searchBbiPressed:(id)sender {
    
    /*
     Invoke location request from locationManager
     */
    [self.locationManager requestLocation];
}

// appInfo bbi pressed, invoke App Info VC
- (void)appInfoBbiPressed:(id)sender {
    
    UINavigationController *appInfoVC = [self.storyboard instantiateViewControllerWithIdentifier:@"HelpNavControllerID"];
    
    [self presentViewController:appInfoVC animated:YES completion:nil];
}

#pragma mark - Object Getters
// main viewContext
- (NSManagedObjectContext *)viewContext {
    
    if (_viewContext)
        return _viewContext;
    
    _viewContext = CoreDataStack.shared.container.viewContext;
    
    return _viewContext;
}

// location manager
- (CLLocationManager *)locationManager {

    if (_locationManager)
        return _locationManager;
    
    _locationManager = [[CLLocationManager alloc] init];
    
    return _locationManager;
}
@end

