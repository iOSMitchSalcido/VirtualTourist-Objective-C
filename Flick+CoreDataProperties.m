//
//  Flick+CoreDataProperties.m
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/17/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "Flick+CoreDataProperties.h"

@implementation Flick (CoreDataProperties)

+ (NSFetchRequest<Flick *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Flick"];
}

@dynamic imageData;
@dynamic urlString;
@dynamic title;
@dynamic pin;

@end
