//
//  AlbumViewController.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/17/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//
/*
 About AlbumViewController:
 Presents a collectionView to display downloaded flicks. Includes functionality for:
 - Preview a flick, single-tap a cell
 - Edit collectionView...ability to delete flick(s)
 - Load a new album of flicks..deletes existing album
 */

#import <UIKit/UIKit.h>
#import "Pin+CoreDataClass.h"

@interface AlbumViewController : UIViewController
@property (nonatomic, strong) Pin *pin;
@end
