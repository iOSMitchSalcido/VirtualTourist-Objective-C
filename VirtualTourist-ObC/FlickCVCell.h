//
//  FlickCVCell.h
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/19/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlickCVCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (void)updateFlick:(UIImage *)flick;
- (void)downloadingNewFlick;
- (void)updateCellSelectedState:(BOOL)selected;
@end
