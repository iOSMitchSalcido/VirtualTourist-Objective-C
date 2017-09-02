//
//  VTAnnotation.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/16/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//
/*
 About VTAnnotation:
 Subclass of MKPointAnnotation. Used to extend functionality by adding a Pin property.
 */

#import <MapKit/MapKit.h>
#import "Pin+CoreDataClass.h"

@interface VTAnnotation : MKPointAnnotation
@property (strong, nonatomic) Pin *pin;
@end
