//
//  AppInfoViewController.m
//  VirtualTourist-ObC
//
//  Created by Online Training on 9/10/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "AppInfoViewController.h"

@interface AppInfoViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *appInfoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *appInstructionsImageView;

@end

@implementation AppInfoViewController

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (self.view.bounds.size.width < self.view.frame.size.height) {
        // portrait
        self.appInfoImageView.image = [UIImage imageNamed:@"AppInfoTitle_portrait"];
        self.appInstructionsImageView.image = [UIImage imageNamed:@"AppInfoInstructions_portrait"];
    }
    else {
        // landscape
        self.appInfoImageView.image = [UIImage imageNamed:@"AppInfoTitle_landscape"];
        self.appInstructionsImageView.image = [UIImage imageNamed:@"AppInfoInstructions_landscape"];
    }
}
@end
