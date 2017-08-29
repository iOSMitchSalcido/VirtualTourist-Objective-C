//
//  FlickCVCell.m
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/19/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "FlickCVCell.h"

@interface FlickCVCell()
@property (weak, nonatomic) IBOutlet UIImageView *checkmarkImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation FlickCVCell
- (void)updateFlick:(UIImage *)flick {

    _imageView.image = flick;
    [_activityIndicator stopAnimating];
}

- (void)downloadingNewFlick {
    
    _imageView.image = [UIImage imageNamed:@"DefaultCVCellImage"];
    [_activityIndicator startAnimating];
}

- (void)updateCellSelectedState:(BOOL)selected {
    
    [_checkmarkImageView setHidden:!selected];
}
@end
