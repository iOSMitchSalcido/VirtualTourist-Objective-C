//
//  FlickCVCell.m
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/19/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "FlickCVCell.h"

@interface FlickCVCell()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation FlickCVCell
- (void)updateFlick:(UIImage *)flick {

    _imageView.image = flick;
    [_activityIndicator stopAnimating];
}

- (void)downloadingNewFlick {
    
    _imageView.image = nil;
    [_activityIndicator startAnimating];
}
@end
