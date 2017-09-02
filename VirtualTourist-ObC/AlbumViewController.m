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

// spacing for cells in collectionView
#define kCellSpacing    2.0     // spacing between adjacent cells
#define kCellsPerRow    4.0     // number of cells in a row

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
@property (weak, nonatomic) IBOutlet UIScrollView *flickScrollView;
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

// configure imageViews in flickScrollView
- (void)configureFlickScrollView;

// UIBarButtonItem action methods
- (void)trashBbiPressed:(id)sender;
- (void)reloadAlbumBbiPressed:(id)sender;
- (void)shareFlickBbiPressed:(id)sender;

// tapDetected
- (void)singleTapDetected:(id)sender;
@end

@implementation AlbumViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = _pin.title;
    
    [_noFlicksImageView setHidden:YES];
    
    [self.navigationController setToolbarHidden:NO];
    
    _progressView = [[UIProgressView alloc]
                     initWithProgressViewStyle:UIProgressViewStyleBar];
    _progressView.progress = 0.0;
    [_progressView setHidden:YES];
    [self.navigationController.navigationBar addSubview:_progressView];
    
    _flickScrollView.alpha = 0.0;
    
    NSError *error = nil;
    if (![self.frc performFetch:&error]) {
        [self presentOKAlertForError:error];
    }
    else {
        
        if (_pin.isDownloading && (self.frc.fetchedObjects.count == 0))
            _viewMode = Predownloading;
        
        else if (_pin.isDownloading)
            _viewMode = Downloading;
        
        else if (_pin.noFlicksAtLocation)
            _viewMode = NoFlicks;
        
        else {
            [self configureFlickScrollView];
            _viewMode = Normal;
        }
        
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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (editing) {
        
        _viewMode = Editing;
        _selectedCellsArray = [[NSMutableArray alloc] init];
    }
    else {
        
        _viewMode = Normal;
        _selectedCellsArray = nil;
    }
    
    [self configureViewMode];
    
    [_collectionView reloadData];
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
    
    if (self.editing)
        cell.imageView.alpha = 0.8;
    else
        cell.imageView.alpha = 1.0;
        
    [cell updateCellSelectedState:[_selectedCellsArray containsObject:indexPath]];
    
    return cell;
}

#pragma mark - CollectionView Delegate Methods
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (_viewMode) {
        case Normal: {
            
            [self.view addGestureRecognizer:self.tapGr];

            [UIView animateWithDuration:0.3
                             animations:^{
                                
                                 _flickScrollView.alpha = 1.0;
                                 _collectionView.alpha = 0.0;
                             }];

            CGRect scrollToFrame = _flickScrollView.frame;
            scrollToFrame.origin.x = (float)(indexPath.row) * scrollToFrame.size.width;
            [_flickScrollView scrollRectToVisible:scrollToFrame animated:NO];
            
            _viewMode = ImagePreview;
            [self configureViewMode];
        }
            break;
        case Editing: {
            
            FlickCVCell *cell = (FlickCVCell *)[_collectionView cellForItemAtIndexPath:indexPath];
            
            if ([_selectedCellsArray containsObject:indexPath]) {
                [_selectedCellsArray removeObject:indexPath];
                [cell updateCellSelectedState:NO];
            }
            else {
                [_selectedCellsArray addObject:indexPath];
                [cell updateCellSelectedState:YES];
            }
            
            _trashBbi.enabled = [_selectedCellsArray count] > 0;
        }
            break;
        default:
            break;
    }
}

#pragma mark - NSFetchedResultsController Delegate Methods
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    
    _frcCvBlockOpsArray = [[NSMutableArray alloc] init];
    
    if (_viewMode == Predownloading) {
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
                [self configureFlickScrollView];
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

    [self.view removeGestureRecognizer:self.tapGr];

    [UIView animateWithDuration:0.3
                     animations:^{
                        
                         _collectionView.alpha = 1.0;
                         _flickScrollView.alpha = 0.0;
                     }];
    
    _viewMode = Normal;
    [self configureViewMode];
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
                    
                    [self presentOKAlertWithTitle:@"No Flicks Found"
                                     andMessage:@"Search another location"];
                    return;
                }
                
                if (time >= 10) {
                    
                    _viewMode = SearchTimeout;
                    [self configureViewMode];
                    [timer invalidate];
                    
                    [self presentOKAlertWithTitle:@"Flickr Search Timeout"
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
            
            [self setToolbarItems:@[flexBbi, reloadBbi] animated:YES];
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

// configure imageViews in flickScrollView
- (void)configureFlickScrollView {
    
    // remove all flicks currently in scrollView..except scroll bars
    // views have been tagged with 100 to identify
    for (UIView *view in _flickScrollView.subviews) {
        if (view.tag == 100)
            [view removeFromSuperview];
    }
    
    // create frame and size to build subViews, track size
    CGRect frame = _flickScrollView.frame;
    frame.origin = CGPointMake(0.0, 0.0);
    CGSize contentSize = CGSizeMake(0.0, frame.size.height);
    
    // create subViews..use tag to identify subviews that are NOT scroll bars
    for (Flick *flick in self.frc.fetchedObjects) {
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
        imageView.tag = 100;
        imageView.image = [UIImage imageWithData:flick.imageData];
        frame.origin.x += frame.size.width;
        contentSize.width += frame.size.width;
        [_flickScrollView addSubview:imageView];
    }
    
    // size
    [_flickScrollView setContentSize:contentSize];
}

#pragma mark - UIBarButtonItem Action Methods
- (void)trashBbiPressed:(id)sender {
    
    NSManagedObjectContext *context = [CoreDataStack.shared.container viewContext];
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc]
                                              initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = context;
    [privateContext performBlock:^{
        
        for (NSIndexPath *indexPath in _selectedCellsArray) {
            
            Flick *flick = [self.frc objectAtIndexPath:indexPath];
            Flick *privateFlick = [privateContext objectWithID:flick.objectID];
            [privateContext deleteObject:privateFlick];
        }
        
        [_selectedCellsArray removeAllObjects];
        
        NSError *error = [CoreDataStack.shared savePrivateContext:privateContext];
        if (error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentOKAlertForError:error];
            });
        }
        else {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self configureFlickScrollView];
                _trashBbi.enabled = NO;
                
                if (self.frc.fetchedObjects.count == 0)
                    [self setEditing:NO animated:YES];
            });
        }
    }];
}
     
- (void)reloadAlbumBbiPressed:(id)sender {
    
    [_progressView setProgress:0.0 animated:NO];
    
    void (^proceedActionCompletion)(void);
    proceedActionCompletion = ^{
      
        NSManagedObjectContext *context = [CoreDataStack.shared.container viewContext];
        NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc]
                                                  initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        privateContext.parentContext = context;
        [privateContext performBlock:^{
            
            Pin *privatePin = (Pin *)[privateContext objectWithID:_pin.objectID];
            for (Flick *flick in privatePin.flicks)
                [privateContext deleteObject:flick];
            
            NSError *error = [CoreDataStack.shared savePrivateContext:privateContext];
            if (error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentOKAlertForError:error];
                });            }
            else {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    _viewMode = Predownloading;
                    [self configureViewMode];
                    [self downloadAlbumForPin:_pin];
                });
            }
        }];
    };
    
    if ([self.frc.fetchedObjects count] > 0)
        [self presentCancelProceedAlertWithTitle:@"Load new album"
                                         message:@"Delete all flicks and replace with newly downloaded album" completion:proceedActionCompletion];
    else
        proceedActionCompletion();
}

- (void)shareFlickBbiPressed:(id)sender {
    
    CGFloat offset = _flickScrollView.contentOffset.x;
    NSUInteger index = (NSUInteger)(offset / _flickScrollView.frame.size.width);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    Flick *flick = [self.frc objectAtIndexPath:indexPath];
    UIImage *image = [UIImage imageWithData:flick.imageData];
    
    NSString *message = @"Hello";
    if (_pin.title)
        message = [NSString stringWithFormat:@"Hello from %@ !", _pin.title];
    
    UIActivityViewController *controller = [[UIActivityViewController alloc]
                                            initWithActivityItems:@[message, image]
                                            applicationActivities:nil];
    
    [self presentViewController:controller animated:YES completion:nil];
}
@end
