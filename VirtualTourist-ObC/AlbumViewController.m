//
//  AlbumViewController.m
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/17/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

#import "AlbumViewController.h"
#import "FlickCVCell.h"
#import "Flick+CoreDataClass.h"
#import "CoreDataStack.h"

@interface AlbumViewController () <UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) NSFetchedResultsController *frc;
@end

@implementation AlbumViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSFetchRequest *request = [Flick fetchRequest];
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"urlString" ascending:true];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pin == %@", _pin];
    request.predicate = predicate;
    request.sortDescriptors = @[sd];
    _frc = [[NSFetchedResultsController alloc]
            initWithFetchRequest:request
            managedObjectContext:[CoreDataStack.shared.container viewContext]
            sectionNameKeyPath:nil
            cacheName:nil];
    
    NSError *error = nil;
    if (![_frc performFetch:&error]) {
        NSLog(@"bad frc fetch");
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
 
    [_flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    _flowLayout.minimumLineSpacing = kCellSpacing;
    _flowLayout.minimumInteritemSpacing = kCellSpacing;
    
    CGFloat widthForCellsInRow = _collectionView.frame.size.width - (kCellsPerRow - 1.0) * kCellSpacing;
    _flowLayout.itemSize = CGSizeMake(widthForCellsInRow / kCellsPerRow,
                                      widthForCellsInRow / kCellsPerRow);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 100;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FlickCVCell *cell = (FlickCVCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FlickCVCellID" forIndexPath:indexPath];
    
    [cell downloadingNewFlick];
    
    return cell;
}
@end
