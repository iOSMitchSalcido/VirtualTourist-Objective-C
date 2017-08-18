//
//  Pin+CoreDataProperties.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/17/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "Pin+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Pin (CoreDataProperties)

+ (NSFetchRequest<Pin *> *)fetchRequest;

@property (nonatomic) BOOL isDownloading;
@property (nonatomic) BOOL noFlicksAtLocation;
@property (nullable, nonatomic, copy) NSString *title;
@property (nonatomic) double longitude;
@property (nonatomic) double latitude;
@property (nullable, nonatomic, retain) NSSet<Flick *> *flicks;

@end

@interface Pin (CoreDataGeneratedAccessors)

- (void)addFlicksObject:(Flick *)value;
- (void)removeFlicksObject:(Flick *)value;
- (void)addFlicks:(NSSet<Flick *> *)values;
- (void)removeFlicks:(NSSet<Flick *> *)values;

@end

NS_ASSUME_NONNULL_END
