//
//  CoreDataStack.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/12/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@interface CoreDataStack : NSObject
@property(nonatomic, strong) NSPersistentContainer *container;
+(CoreDataStack *)shared;
- (NSError *)savePrivateContext:(NSManagedObjectContext *)privateContext;
@end
