//
//  Networking.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/14/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//
/*
 About Networking:
 
 Code for networking
 - create/run dataTask
 - Networking constants
 */

#import <Foundation/Foundation.h>

// constants, keys
#define kNetworkItems   @"items"
#define kNetworkHost    @"host"
#define kNetworkScheme  @"scheme"
#define kNetworkPath    @"path"

// constants, values
@interface Networking : NSObject

// data task
- (void)dataTaskForParams:(NSDictionary *)params withCompletion:(void (^)(NSDictionary *data, NSError *error))completion;
@end
