//
//  Pin+CoreDataClass.m
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/17/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "Pin+CoreDataClass.h"
#import "Flick+CoreDataClass.h"

@implementation Pin
- (BOOL)downloadComplete {
    
    if (self.flicks.count == 0)
        return NO;
    
    for (Flick *flick in self.flicks) {
        if (!flick.imageData)
            return NO;
    }
    return YES;
}
@end
