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
#import "UIViewController+Flickr_Alert.h"

typedef enum {
    Normal,
    Downloading,
    Predownloading,
    Editing,
    ImagePreview,
    NoFlicks,
    SearchTimeout
} ViewMode;

typedef void (^FrcBlockOp)(void);

@interface AlbumViewController () <UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *noFlicksImageView;
@property (nonatomic, strong) NSFetchedResultsController *frc;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIBarButtonItem *trashBbi;
@property (nonatomic) ViewMode viewMode;

@property (nonatomic, strong) NSMutableArray *selectedCellsArray;

@property (nonatomic, strong) UITapGestureRecognizer *tapGr;

@property (nonatomic, strong) NSMutableArray *frcCvBlockOpsArray;

// return progress of Flick download: 0.0 = no flicks, 1.0 = all flicks downloaded
- (float)downloadProgress;

// configure view mode
- (void)configureViewMode;

// return state of ViewMode
- (ViewMode)viewModeState;

// UIBarButtonItem action methods
- (void)trashBbiPressed:(id)sender;
- (void)reloadAlbumBbiPressed:(id)sender;
- (void)shareFlickBbiPressed:(id)sender;

// tapDetected
- (void)singleTapDetected:(id)sender;

- (void)debugBbiPressed:(id)sender;
@end

@implementation AlbumViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _selectedCellsArray = [[NSMutableArray alloc] init];
    
    self.title = _pin.title;
    
    [_noFlicksImageView setHidden:YES];
    
    [self.navigationController setToolbarHidden:NO];
    
    _progressView = [[UIProgressView alloc]
                     initWithProgressViewStyle:UIProgressViewStyleBar];
    _progressView.progress = 0.0;
    [_progressView setHidden:YES];
    [self.navigationController.navigationBar addSubview:_progressView];
    
    NSError *error = nil;
    if (![self.frc performFetch:&error]) {
        NSLog(@"bad frc fetch");
    }
    else {

        _viewMode = Predownloading;
        if (_pin.noFlicksAtLocation)
            _viewMode = NoFlicks;
        else if ([_pin downloadComplete])
            _viewMode = Normal;
        
        [self configureViewMode];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    
    // remove progressView..otherwise will still be on navbar when VC popped
    [_progressView removeFromSuperview];
    
    // nil frc delegate and array..blocks in array preventing VC to dealloc..holding ref
    // to CV/VC
    _frc.delegate = nil;
    _frcCvBlockOpsArray = nil;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
 
    [_flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    _flowLayout.minimumLineSpacing = kCellSpacing;
    _flowLayout.minimumInteritemSpacing = kCellSpacing;
    
    CGFloat widthForCellsInRow = _collectionView.frame.size.width - (kCellsPerRow - 1.0) * kCellSpacing;
    _flowLayout.itemSize = CGSizeMake(widthForCellsInRow / kCellsPerRow,
                                      widthForCellsInRow / kCellsPerRow);
    
    CGRect frame = self.navigationController.navigationBar.frame;
    frame.origin.x = 0.0;
    frame.origin.y = frame.size.height - _progressView.frame.size.height;
    _progressView.frame = frame;
}

#pragma mark - CollectionView DataSource Methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.frc.fetchedObjects.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FlickCVCell *cell = (FlickCVCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FlickCVCellID" forIndexPath:indexPath];
    
    Flick *flick = [self.frc objectAtIndexPath:indexPath];
    if (flick.imageData) {
        [cell updateFlick:[UIImage imageWithData:flick.imageData]];
    }
    else {
        [cell downloadingNewFlick];
    }
    
    [cell updateCellSelectedState:[_selectedCellsArray containsObject:indexPath]];
    
    return cell;
}

#pragma mark - CollectionView Delegate Methods
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (_viewMode) {
        case Normal: {
            
            [self.view addGestureRecognizer:self.tapGr];
            [_collectionView setHidden:YES];
            
            _viewMode = ImagePreview;
            [self configureViewMode];
        }
            break;
        case Editing: {
            
            
        }
            break;
        default:
            break;
    }
}

#pragma mark - NSFetchedResultsController Delegate Methods
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    
    _frcCvBlockOpsArray = [[NSMutableArray alloc] init];
    if ((_viewMode == Predownloading) && (_pin.flicks.count > 0)) {
        
        _viewMode = Downloading;
        [self configureViewMode];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            
            FrcBlockOp blockOp = ^{
                [_collectionView insertItemsAtIndexPaths:@[newIndexPath]];
            };
            [_frcCvBlockOpsArray addObject:blockOp];
        }
            break;
        case NSFetchedResultsChangeDelete: {
            
            FrcBlockOp blockOp = ^{
                [_collectionView deleteItemsAtIndexPaths:@[indexPath]];
            };
            [_frcCvBlockOpsArray addObject:blockOp];
        }
            break;
        case NSFetchedResultsChangeMove: {
        }
            break;
        case NSFetchedResultsChangeUpdate: {
            
            FrcBlockOp blockOp = ^{
                [_collectionView reloadItemsAtIndexPaths:@[indexPath]];
            };
            [_frcCvBlockOpsArray addObject:blockOp];
        }
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
    [_collectionView performBatchUpdates:^{
        
        for (FrcBlockOp blockOp in _frcCvBlockOpsArray) {
            blockOp();
        }
    } completion:nil];
    
    switch (_viewMode) {
        case Downloading: {
            
            [_progressView setProgress:[self downloadProgress]
                              animated:YES];
            
            if ([self downloadProgress] >= 1.0) {
                _viewMode = Normal;
                [self configureViewMode];
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - Object Getters
- (NSFetchedResultsController *)frc {
    
    if (_frc)
        return _frc;
    
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
    
    _frc.delegate = self;
    
    return _frc;
}

- (UITapGestureRecognizer *)tapGr {

    if (_tapGr)
        return _tapGr;
    
    _tapGr = [[UITapGestureRecognizer alloc]
              initWithTarget:self
              action:@selector(singleTapDetected:)];
    
    _tapGr.numberOfTapsRequired = 1;
    
    return _tapGr;
}

#pragma mark - Helper Methods
// singleTap
- (void)singleTapDetected:(id)sender {

    [_collectionView setHidden:NO];
    [self.view removeGestureRecognizer:self.tapGr];
    
    _viewMode = Normal;
    [self configureViewMode];
}

// return state of ViewMode
- (ViewMode)viewModeState {
 
    if (_pin.isDownloading && (self.frc.fetchedObjects.count == 0)) {
        return Predownloading;
    }
    else if (_pin.isDownloading && (self.frc.fetchedObjects.count > 0)) {
        return Downloading;
    }
    else if (_pin.noFlicksAtLocation) {
        return NoFlicks;
    }
    
    return Normal;
}

// return progress of Flick download
- (float)downloadProgress {
    
    float totalFlicks = (float)_frc.fetchedObjects.count;
    if (totalFlicks == 0.0)
        return 0.0;
    
    float downloadedFlickCount = 0.0;
    for (Flick *flick in _frc.fetchedObjects) {
        if (flick.imageData)
            downloadedFlickCount += 1.0;
    }
    
    return  downloadedFlickCount / totalFlicks;
}

// configure view mode
- (void)configureViewMode {
    
    UIBarButtonItem *flexBbi = [[UIBarButtonItem alloc]
                                initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                target:nil
                                action:nil];
    
    UIBarButtonItem *placeholderBbi = [[UIBarButtonItem alloc]
                                       initWithTitle:@""
                                       style:UIBarButtonItemStylePlain
                                       target:nil
                                       action:nil];
    
    switch (_viewMode) {
        case Predownloading: {
            
            [_activityIndicator startAnimating];
            
            [self.navigationItem setLeftBarButtonItem:nil animated:YES];
            [self.navigationItem setRightBarButtonItem:nil animated:YES];
            [self setToolbarItems:nil animated:YES];
            
            __block NSUInteger time = 0;
            void (^timerBlock)(NSTimer *);
            timerBlock = ^(NSTimer *timer) {
                
                time++;
                    
                if (_pin.isDownloading) {
                    [timer invalidate];
                    return;
                }
                
                if (_pin.noFlicksAtLocation) {
                    
                    _viewMode = NoFlicks;
                    [self configureViewMode];
                    [timer invalidate];
                    
                    [self presentAlertWithTitle:@"No Flicks Found"
                                     andMessage:@"Search another location"];
                    return;
                }
                
                if (time >= 10) {
                    
                    _viewMode = SearchTimeout;
                    [self configureViewMode];
                    [timer invalidate];
                    
                    [self presentAlertWithTitle:@"Flickr Search Timeout"
                                     andMessage:@"Flickr or network problem"];
                }
            };
            
            [NSTimer scheduledTimerWithTimeInterval:1.0
                                            repeats:YES
                                              block:timerBlock];
        }
            break;
        case Downloading: {
            
            [_activityIndicator stopAnimating];
            
            [_progressView setHidden:NO];
            
            [self setToolbarItems:nil animated:YES];
            [self.navigationItem setRightBarButtonItem:nil animated:YES];
            [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        }
            break;
        case Normal: {
            
            [_progressView setHidden:YES];

            if (self.frc.fetchedObjects.count > 0)
                [self.navigationItem setRightBarButtonItem:self.editButtonItem animated:YES];
            else
                [self.navigationItem setRightBarButtonItem:nil animated:YES];
            
            UIBarButtonItem *reloadBbi = [[UIBarButtonItem alloc]
                                          initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                          target:self
                                          action:@selector(reloadAlbumBbiPressed:)];
            
            UIBarButtonItem *debugBbi = [[UIBarButtonItem alloc]
                                         initWithTitle:@"debug"
                                         style:UIBarButtonItemStylePlain
                                         target:self
                                         action:@selector(debugBbiPressed:)];
            
            [self setToolbarItems:@[debugBbi, flexBbi, reloadBbi] animated:YES];
            [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        }
            break;
        case Editing: {
            
            _trashBbi = [[UIBarButtonItem alloc]
                         initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                         target:self
                         action:@selector(trashBbiPressed:)];
            _trashBbi.enabled = NO;
            [self setToolbarItems:@[flexBbi, _trashBbi] animated:YES];
            
            [self.navigationItem setLeftBarButtonItem:placeholderBbi animated:YES];
        }
            break;
        case ImagePreview: {

            UIBarButtonItem *shareBbi = [[UIBarButtonItem alloc]
                                         initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                         target:self
                                         action:@selector(shareFlickBbiPressed:)];
            [self.navigationItem setRightBarButtonItem:shareBbi animated:YES];
            [self.navigationItem setLeftBarButtonItem:placeholderBbi animated:YES];
            [self setToolbarItems:nil animated:YES];
        }
            break;
        case NoFlicks: {
            
            [self setToolbarItems:nil animated:YES];
            [self.navigationItem setRightBarButtonItem:nil animated:YES];
            [self.navigationItem setLeftBarButtonItem:nil animated:YES];
            [_noFlicksImageView setHidden:NO];
            _noFlicksImageView.image = [UIImage imageNamed:@"NoFlicksFound"];
        }
            break;
        case SearchTimeout: {
            
            [self setToolbarItems:nil animated:YES];
            [self.navigationItem setRightBarButtonItem:nil animated:YES];
            [self.navigationItem setLeftBarButtonItem:nil animated:YES];
            [_noFlicksImageView setHidden:NO];            
            _noFlicksImageView.image = [UIImage imageNamed:@"SearchTimeout"];
        }
            break;
    }
}

#pragma mark - UIBarButtonItem Action Methods
- (void)trashBbiPressed:(id)sender {
    NSLog(@"trashBbiPressed");
}
- (void)reloadAlbumBbiPressed:(id)sender {
    
    NSManagedObjectContext *context = [CoreDataStack.shared.container viewContext];
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc]
                                              initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = context;
    [privateContext performBlock:^{
       
        Pin *privatePin = (Pin *)[privateContext objectWithID:_pin.objectID];
        for (Flick *flick in privatePin.flicks)
            [privateContext deleteObject:flick];
        
        NSError *error = nil;
        if (![privateContext save:&error]) {
            NSLog(@"error saving after deleting flicks");
        }
        else {
            [context performBlockAndWait:^{
               
                NSError *error = nil;
                if (![context save:&error]) {
                    NSLog(@"error saving after deleting flicks");
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _viewMode = Predownloading;
                        [self configureViewMode];
                        [self downloadAlbumForPin:_pin];
                    });
                }
            }];
        }
    }];
}
- (void)shareFlickBbiPressed:(id)sender {
    NSLog(@"shareFlickBbiPressed");
}

- (void)debugBbiPressed:(id)sender {
    
    NSLog(@"debugBbiPressed");
    
    _pin.noFlicksAtLocation = !_pin.noFlicksAtLocation;
    
    NSManagedObjectContext *context = [CoreDataStack.shared.container viewContext];
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"bad save");
    }
}
@end
