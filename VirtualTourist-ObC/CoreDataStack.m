//
//  CoreDataStack.m
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/12/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "CoreDataStack.h"

@implementation CoreDataStack
- (id)init {
    
    self = [super init];
    return self;
}

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

- (void)save {

    NSError *error = nil;
    if (![self.container.viewContext save:&error]) {
        NSLog(@"bad viewContext save");
    }
}

+(CoreDataStack *)shared {
    
    static CoreDataStack *shared = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        shared = [[CoreDataStack alloc] init];
    });
    
    return  shared;
}
@end
