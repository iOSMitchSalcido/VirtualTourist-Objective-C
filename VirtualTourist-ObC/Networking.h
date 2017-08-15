//
//  Networking.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/14/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import <Foundation/Foundation.h>

// constants, keys
#define items   @"items"
#define host    @"host"
#define scheme  @"scheme"
#define path    @"path"

// constants, values
@interface Networking : NSObject
- (void)dataTaskForParams:(NSDictionary *)params withCompletion:(void (^)(NSDictionary *data, NSError *error))completion;
@end
