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
#import "VTAnnotation.h"
#import "CoreDataStack.h"

@interface MapViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) VTAnnotation *dragAnnotation;
@property (weak, nonatomic) NSManagedObjectContext *viewContext;

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
    
    // add long press gr
    UILongPressGestureRecognizer *gr = [[UILongPressGestureRecognizer alloc] init];
    [gr addTarget:self action:@selector(longPressDetected:)];
    [gr setMinimumPressDuration:0.5];
    [gr setNumberOfTouchesRequired:1];
    [self.view addGestureRecognizer:gr];
    
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

- (void)longPressDetected:(UILongPressGestureRecognizer *)sender {
    
    CGPoint touchPoint = [sender locationInView:_mapView];
    CLLocationCoordinate2D coordinate = [_mapView convertPoint:touchPoint
                                          toCoordinateFromView:_mapView];
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            VTAnnotation *annot = [[VTAnnotation alloc] init];
            annot.coordinate = coordinate;
            [_mapView addAnnotation:annot];
            _dragAnnotation = annot;
        }
            break;
        case UIGestureRecognizerStateChanged: {
            if (_dragAnnotation) {
                _dragAnnotation.coordinate = coordinate;
            }
        }
            break;
        case UIGestureRecognizerStateEnded: {
            if (_dragAnnotation) {
                _dragAnnotation.coordinate = coordinate;
            }
            [self addPinToAnnotation:_dragAnnotation];
            _dragAnnotation = nil;
        }
            break;
        default:
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier  isEqual: @"AlbumViewControllerSegueID"]) {
        NSLog(@"prepareForSegue");
    }
}

// mapView delegate methods
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    
    MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"MapViewPinID"];
    if (pinView == nil) {
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
    
    pinView.annotation = annotation;
    return pinView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    
    VTAnnotation *annotation = (VTAnnotation *)view.annotation;
    Pin *pin = annotation.pin;
    
    if (pin == nil) {
        NSLog(@"nil Pin");
        return;
    }
    
    if (control == view.leftCalloutAccessoryView) {
        
        [mapView removeAnnotation:annotation];
        
        NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc]
                                                  initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        privateContext.parentContext = self.viewContext;
        [privateContext performBlock:^{
            
            Pin *privatePin = (Pin *)[privateContext objectWithID:pin.objectID];
            [privateContext deleteObject:privatePin];
            
            NSError *error = nil;
            if (![privateContext save:&error]) {
                NSLog(@"Error saving private context: %@\n%@", [error localizedDescription], [error userInfo]);
                abort();
            }
            
            [self.viewContext performBlock:^{
                
                NSError *error = nil;
                if (![self.viewContext save:&error]) {
                    NSLog(@"Error saving private context: %@\n%@", [error localizedDescription], [error userInfo]);
                    abort();
                }
            }];
        }];
    }
    else if (control == view.rightCalloutAccessoryView) {
        
        [self performSegueWithIdentifier:@"AlbumViewControllerSegueID" sender:pin];
    }
}

// add a new Pin to an annotation
- (void)addPinToAnnotation:(VTAnnotation *)annotation {
 
    CLLocationCoordinate2D coordinate = annotation.coordinate;
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude
                                                      longitude:coordinate.longitude];
    
    void (^reverseGeocodeBlock)(NSArray *, NSError *);
    reverseGeocodeBlock = ^(NSArray *placemarks, NSError *error) {
        
        if (error != nil) {
            NSLog(@"Error in geocoding location");
            [_mapView removeAnnotation:annotation];
            return;
        }
        
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
        
        annotation.title = locationTitle;
        
        Pin *newPin = [NSEntityDescription insertNewObjectForEntityForName:@"Pin"
                                                    inManagedObjectContext:self.viewContext];
        newPin.latitude = annotation.coordinate.latitude;
        newPin.longitude = annotation.coordinate.longitude;
        newPin.title = locationTitle;
        
        NSError *saveError = nil;
        if (![self.viewContext save:&saveError]) {
            NSLog(@"Error saving private context: %@\n%@", [error localizedDescription], [error userInfo]);
            abort();
        }
        else {
         
            annotation.pin = newPin;
        }
    };

    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:location completionHandler:reverseGeocodeBlock];
}

// create an annotation from a Pin
- (VTAnnotation *)annotationForPin:(Pin *)pin {
    
    VTAnnotation *annotation = [[VTAnnotation alloc] init];
    annotation.pin = pin;
    annotation.title = pin.title;
    annotation.coordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude);
    
    return annotation;
}

/*
 Object getters
*/
- (NSManagedObjectContext *)viewContext {
    
    if (_viewContext)
        return _viewContext;
    _viewContext = CoreDataStack.shared.container.viewContext;
    return _viewContext;
}
@end

