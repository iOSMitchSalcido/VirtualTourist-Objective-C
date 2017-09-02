//
//  Pin+CoreDataClass.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/17/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Flick;

NS_ASSUME_NONNULL_BEGIN

@interface Pin : NSManagedObject
// test download state for Pin. YES mean there are zero flicks with nil imageData
@property (nonatomic, readonly) BOOL downloadComplete;
@end

NS_ASSUME_NONNULL_END

#import "Pin+CoreDataProperties.h"
