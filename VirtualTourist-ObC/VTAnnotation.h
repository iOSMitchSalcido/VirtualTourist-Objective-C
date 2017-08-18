//
//  VTAnnotation.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/16/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "Pin+CoreDataClass.h"

@interface VTAnnotation : MKPointAnnotation
@property (strong, nonatomic) Pin *pin;
@end
