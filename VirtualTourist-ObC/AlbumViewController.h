//
//  AlbumViewController.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/17/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Pin+CoreDataClass.h"

#define kCellSpacing    2.0
#define kCellsPerRow    4.0

@interface AlbumViewController : UIViewController
@property (nonatomic, strong) Pin *pin;
@end
