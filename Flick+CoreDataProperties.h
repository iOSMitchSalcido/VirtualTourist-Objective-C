//
//  Flick+CoreDataProperties.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/17/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "Flick+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Flick (CoreDataProperties)

+ (NSFetchRequest<Flick *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSData *imageData;
@property (nullable, nonatomic, copy) NSString *urlString;
@property (nullable, nonatomic, copy) NSString *title;
@property (nullable, nonatomic, retain) Pin *pin;

@end

NS_ASSUME_NONNULL_END
