//
//  CoreDataStack.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/12/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//
/*
 About CoreDataStack:
 Creation of Core Data Stack, used as a singleton. Functionality for:
 - creation of stack
 - saving stack
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@interface CoreDataStack : NSObject

// ref to container
@property(nonatomic, strong) NSPersistentContainer *container;

// singleton
+(CoreDataStack *)shared;

/*
 Method to save a private context. This method will first save the private context. Upon successful
 save of private context, will then save viewContext. Returns error encoutered during save process.
*/
- (NSError *)savePrivateContext:(NSManagedObjectContext *)privateContext;
@end
