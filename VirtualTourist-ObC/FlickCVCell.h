//
//  FlickCVCell.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/19/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//
/*
About FlickCVCell:
 Extend functionality of CV cell to include flick imageView (photo), and methods to indicate
 flick download state.
 */

#import <UIKit/UIKit.h>

@interface FlickCVCell : UICollectionViewCell

// ref to imageView. Needed to dim flick when CV is in editing mode
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

// update the imageView with a new flick
- (void)updateFlick:(UIImage *)flick;

// place cell in "downloading" state..activityIndicator with default image
- (void)downloadingNewFlick;

// set cell selected state..YES will show checkmark
- (void)updateCellSelectedState:(BOOL)selected;
@end
