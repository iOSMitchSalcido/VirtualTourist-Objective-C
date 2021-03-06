//
//  CoreDataStack.m
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/12/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "CoreDataStack.h"

@implementation CoreDataStack

// singleton creation
+(CoreDataStack *)shared {
    
    static CoreDataStack *shared = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        shared = [[CoreDataStack alloc] init];
    });
    
    return  shared;
}

// container
- (NSPersistentContainer *)container {
    
    if (_container)
        return _container;
    
    _container = [[NSPersistentContainer alloc] initWithName:@"DataModel"];
    
    [_container loadPersistentStoresWithCompletionHandler:
     ^(NSPersistentStoreDescription *desc, NSError *error) {
         
         if (error) {
             NSLog(@"error loading store: %@", error.localizedDescription);
         }
         
         self.container.viewContext.mergePolicy = [NSMergePolicy overwriteMergePolicy];
     }];
    
    return _container;
}

// save private context
- (NSError *)savePrivateContext:(NSManagedObjectContext *)privateContext {

    __block NSError *error = nil;
    if (![privateContext save:&error])
        return error;
    else {
        
        [self.container.viewContext performBlockAndWait:^{
            [self.container.viewContext save:&error];
        }];
    }
    
    return error;
}
@end
