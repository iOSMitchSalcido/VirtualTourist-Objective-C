//
//  Pin+CoreDataProperties.m
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/17/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "Pin+CoreDataProperties.h"

@implementation Pin (CoreDataProperties)

+ (NSFetchRequest<Pin *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Pin"];
}

@dynamic isDownloading;
@dynamic noFlicksAtLocation;
@dynamic title;
@dynamic longitude;
@dynamic latitude;
@dynamic flicks;

@end
