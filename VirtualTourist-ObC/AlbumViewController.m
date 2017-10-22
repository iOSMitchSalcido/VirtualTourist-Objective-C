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

// view mode enum ..used to track/test/steer how view/UI is presented
typedef enum {
    Normal,
    Downloading,
    Predownloading,
    Editing,
    ImagePreview,
    NoFlicks,
    SearchTimeout
} ViewMode;

// used for declaring blocks in frc delegate methods
typedef void (^FrcBlockOp)(void);

@interface AlbumViewController () <UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate>

//*** Properties ***

// collectionView and flowLayout
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;

// indicates pre-download status
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

// imageView to indicate if no flicks found...hidden unless no flicks
@property (weak, nonatomic) IBOutlet UIImageView *noFlicksImageView;

// scrollView to contain flick images..used in ImagePreview
@property (weak, nonatomic) IBOutlet UIScrollView *flickScrollView;

// indicates progress of download
@property (nonatomic, strong) UIProgressView *progressView;

// ref to frc
@property (nonatomic, strong) NSFetchedResultsController *frc;

// ref to trashBbi..needed to enable/disable when in edit mode
@property (nonatomic, strong) UIBarButtonItem *trashBbi;

// track "view mode"...i.e. current state of UI
@property (nonatomic) ViewMode viewMode;

// used to store indexPaths of cells(flicks) in collectionView that will be deleted when trashBbi pressed
@property (nonatomic, strong) NSMutableArray *selectedCellsArray;

// ref to tap gr. Added/removed from view depending on UI state
@property (nonatomic, strong) UITapGestureRecognizer *tapGr;

// ref to array of blocks that are accumulated during frc changes, to be fired in
// collectionView batch updates.
@property (nonatomic, strong) NSMutableArray *frcCvBlockOpsArray;

//*** Methods ***

// return progress of Flick download: 0.0 = no flicks, 1.0 = all flicks downloaded
- (float)downloadProgress;

// configure view mode
- (void)configureViewMode;

// configure imageViews in flickScrollView
- (void)configureFlickScrollView;

// UIBarButtonItem action methods
- (void)trashBbiPressed:(id)sender;             // delete cell/flick
- (void)reloadAlbumBbiPressed:(id)sender;       // load a new album
- (void)shareFlickBbiPressed:(id)sender;        // share a flick

// tapDetected
- (void)singleTapDetected:(id)sender;
@end

@implementation AlbumViewController

- (void)dealloc {
    NSLog(@"dealloc");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"viewDidLoad");
    
    // view title is pin location title
    self.title = _pin.title;
    
    // hide noFlicksIV
    [_noFlicksImageView setHidden:YES];
    
    // show toolbar...will populate with bbi's as UI changes state
    [self.navigationController setToolbarHidden:NO];
    
    // add progressView to navigation bar
    _progressView = [[UIProgressView alloc]
                     initWithProgressViewStyle:UIProgressViewStyleBar];
    _progressView.progress = 0.0;
    [_progressView setHidden:YES];
    [self.navigationController.navigationBar addSubview:_progressView];
    
    // dim out flickScrollView...animated in when flick is selected
    _flickScrollView.alpha = 0.0;
    
    // perform fetch
    NSError *error = nil;
    if (![self.frc performFetch:&error]) {
        [self presentOKAlertForError:error];
    }
    else {
        
        // determine view state based on fetch results, configure UI
        
        if (_pin.isDownloading && (self.frc.fetchedObjects.count == 0))
            _viewMode = Predownloading; // pre downloading
        
        else if (_pin.isDownloading)
            _viewMode = Downloading;    // downloading
        
        else if (_pin.noFlicksAtLocation)
            _viewMode = NoFlicks;       // no flicks found
        
        else {
            [self configureFlickScrollView];
            _viewMode = Normal;         // normal
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
    
    // 171022, ARC cleanup..removed setting frc to nil. Although was properly deallocating, instead
    // using correct weak ref's to self in blocks
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
 
    // layout collectionView, cell spacing
    [_flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    _flowLayout.minimumLineSpacing = kCellSpacing;
    _flowLayout.minimumInteritemSpacing = kCellSpacing;
    
    // ..cells/row
    CGFloat widthForCellsInRow = _collectionView.frame.size.width - (kCellsPerRow - 1.0) * kCellSpacing;
    _flowLayout.itemSize = CGSizeMake(widthForCellsInRow / kCellsPerRow,
                                      widthForCellsInRow / kCellsPerRow);
    
    // set frame of progressView to bottom of navbar
    CGRect frame = self.navigationController.navigationBar.frame;
    frame.origin.x = 0.0;
    frame.origin.y = frame.size.height - _progressView.frame.size.height;
    _progressView.frame = frame;
}

// view editing state
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    /*
     Set editing state of view/UI. When entering editing mode, create new selectedCellsArray
     for storing indexPaths of cell that will ce selected for deletion.
     */
    
    if (editing) {
        // editing
        _viewMode = Editing;
        _selectedCellsArray = [[NSMutableArray alloc] init];
    }
    else {
        // done editing
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
    
    // dequeue cell
    FlickCVCell *cell = (FlickCVCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FlickCVCellID" forIndexPath:indexPath];
    
    // get the flick for cell
    Flick *flick = [self.frc objectAtIndexPath:indexPath];
    
    // test for valid imageData
    if (flick.imageData) {
        // good imageData..show flick
        [cell updateFlick:[UIImage imageWithData:flick.imageData]];
    }
    else {
        // no imageData...show cell as downloading
        [cell downloadingNewFlick];
    }
    
    // dim cell if editing mode
    if (self.editing)
        cell.imageView.alpha = 0.8;
    else
        cell.imageView.alpha = 1.0;
    
    // place checkmark in cell to indicate selection state
    [cell updateCellSelectedState:[_selectedCellsArray containsObject:indexPath]];
    
    return cell;
}

#pragma mark - CollectionView Delegate Methods
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    /*
     delegate method handles:
     - If vc in currently in Normal mode, place vc into imagePreview mode when a cell is tapped
     - If in Editing mode, handle selecting/deselecting a cell/flick for deletion
     */
    
    switch (_viewMode) {
        case Normal: {
            
            // Currently in Normal mode. Change to ImagePreview
            
            // add gr to detect end of ImagePreview
            [self.view addGestureRecognizer:self.tapGr];

            // animate in/out scrollView/collectionView
            [UIView animateWithDuration:0.3
                             animations:^{
                                
                                 _flickScrollView.alpha = 1.0;
                                 _collectionView.alpha = 0.0;
                             }];

            // scroll to subView that contains flick in selected cell
            CGRect scrollToFrame = _flickScrollView.frame;
            scrollToFrame.origin.x = (float)(indexPath.row) * scrollToFrame.size.width;
            [_flickScrollView scrollRectToVisible:scrollToFrame animated:NO];
            
            // update UI state
            _viewMode = ImagePreview;
            [self configureViewMode];
        }
            break;
        case Editing: {
            
            // Editing. Select or deleselect a cell depending on current selection state
            FlickCVCell *cell = (FlickCVCell *)[_collectionView cellForItemAtIndexPath:indexPath];
            
            if ([_selectedCellsArray containsObject:indexPath]) {
                
                // currently selected, deselect
                [_selectedCellsArray removeObject:indexPath];
                [cell updateCellSelectedState:NO];
            }
            else {
                
                // not currently selected, select
                [_selectedCellsArray addObject:indexPath];
                [cell updateCellSelectedState:YES];
            }
            
            // enable trash if cells are selected
            _trashBbi.enabled = [_selectedCellsArray count] > 0;
        }
            break;
        default:
            break;
    }
}

#pragma mark - NSFetchedResultsController Delegate Methods
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    
    /*
    frc about to update data. Create an array to store block ops, update UI
     */
    
    // for storing blocks to be fired in collectionView batch update
    _frcCvBlockOpsArray = [[NSMutableArray alloc] init];
    
    if (_viewMode == Predownloading) {
        _viewMode = Downloading;
        [self configureViewMode];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    /*
     Detect change type and add block to frcCvBlockOpsArray
     */
    
    // 171022, ARC cleanup
    __weak AlbumViewController *weakSelf = self;
    
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            FrcBlockOp blockOp = ^{
                // 171022, ARC cleanup
                AlbumViewController *innerSelf = weakSelf;
                [innerSelf.collectionView insertItemsAtIndexPaths:@[newIndexPath]];
            };
            [_frcCvBlockOpsArray addObject:blockOp];
        }
            break;
        case NSFetchedResultsChangeDelete: {
            FrcBlockOp blockOp = ^{
                // 171022, ARC cleanup
                AlbumViewController *innerSelf = weakSelf;
                [innerSelf.collectionView deleteItemsAtIndexPaths:@[indexPath]];
            };
            [_frcCvBlockOpsArray addObject:blockOp];
        }
            break;
        case NSFetchedResultsChangeMove: {
        }
            break;
        case NSFetchedResultsChangeUpdate: {
            FrcBlockOp blockOp = ^{
                // 171022, ARC cleanup
                AlbumViewController *innerSelf = weakSelf;
                [innerSelf.collectionView reloadItemsAtIndexPaths:@[indexPath]];
            };
            [_frcCvBlockOpsArray addObject:blockOp];
        }
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
    /*
     frc updates are concluding. Fire accumulated blocks in collectionView batch update.
     Update UI
     */
    
    // fire blocks
    // 171022, ARC cleanup
    __weak AlbumViewController *weakSelf = self;
    [_collectionView performBatchUpdates:^{
        
        // 171022, ARC cleanup
        AlbumViewController *innerSelf = weakSelf;
        for (FrcBlockOp blockOp in innerSelf.frcCvBlockOpsArray) {
            blockOp();
        }
    } completion:nil];
    
    // update UI
    switch (_viewMode) {
        case Downloading: {
            
            // update progressView
            [_progressView setProgress:[self downloadProgress]
                              animated:YES];
            
            // test if done downloading...change to Normal mode UI
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
    
    /*
     create/config frc to fetch's Flicks belonging to pin..sorted by urlString attrib
     */
    
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

    /*
     create/config tap gr
     */
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

    /*
     single tap indicates conclusion of ImagePreview. Return to Normal mode UI
     */
    
    // remove gr...not needed
    [self.view removeGestureRecognizer:self.tapGr];

    // animate in/out collectionView/scrollView
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
    
    /*
     compute fraction of flicks downloaded. 1.0 = done downloading
     */
    
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
    
    /*
     Configure view mode and UI state based on viewMode property state
     */
    
    
    // flex and placeholder used several places below
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
            
            /*
             Predownloading:
             no flicks have been detected. Present an activityIndicator in center
             of view to suggest searching for flicks
             */
            
            // animate activityIndicator
            [_activityIndicator startAnimating];
            
            // UI state...nothing on bars..except Back
            [self.navigationItem setLeftBarButtonItem:nil animated:YES];
            [self.navigationItem setRightBarButtonItem:nil animated:YES];
            [self setToolbarItems:nil animated:YES];
            
            /*
             create a timer and time-out search after 10 seconds. Timer is repeating, with a block
             that tests download state of pin.
             */
            
            // 171022, ARC cleanup
            __weak AlbumViewController *weakSelf = self;
            
            __block NSUInteger time = 0;
            void (^timerBlock)(NSTimer *);
            timerBlock = ^(NSTimer *timer) {
                
                // 171022, ARC cleanup
                AlbumViewController *innerSelf = weakSelf;
                
                time++;
                
                // test for downloading
                if (innerSelf.pin.isDownloading) {
                    [timer invalidate];
                    return;
                }
                
                // test for no flicks...show alert and "noflicksFound" image
                if (innerSelf.pin.noFlicksAtLocation) {
                    
                    innerSelf.viewMode = NoFlicks;
                    [innerSelf configureViewMode];
                    [timer invalidate];
                    
                    [innerSelf presentOKAlertWithTitle:@"No Flicks Found"
                                     andMessage:@"Search another location"];
                    return;
                }
                
                // timeout
                if (time >= 10) {
                    
                    innerSelf.viewMode = SearchTimeout;
                    [innerSelf configureViewMode];
                    [timer invalidate];
                    
                    [innerSelf presentOKAlertWithTitle:@"Flickr Search Timeout"
                                     andMessage:@"Flickr or network problem"];
                }
            };
            
            [NSTimer scheduledTimerWithTimeInterval:1.0
                                            repeats:YES
                                              block:timerBlock];
        }
            break;
        case Downloading: {
            
            /*
             Downloading. Stop activity indicator. frc will have updated collectionView cells
             with default cell indicating continued downloading for each flick detected
             */
            [_activityIndicator stopAnimating];
            
            [_progressView setHidden:NO];
            
            [self setToolbarItems:nil animated:YES];
            [self.navigationItem setRightBarButtonItem:nil animated:YES];
            [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        }
            break;
        case Normal: {
            
            /*
             Normal. Show UI for editing, reloading new album
             */
            
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
            
            /*
             Editing. Show trashBbi and Done bbi
             */
            
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

            /*
             ImagePreview. CollectionView is dimmed out and scrollView is visible. Include
             shareBbi to allow user to share flick
             */
            
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
            
            /*
             NoFlicks. Show "NoFlicks" image.
             */
            
            [self setToolbarItems:nil animated:YES];
            [self.navigationItem setRightBarButtonItem:nil animated:YES];
            [self.navigationItem setLeftBarButtonItem:nil animated:YES];
            [_noFlicksImageView setHidden:NO];
            _noFlicksImageView.image = [UIImage imageNamed:@"NoFlicksFound"];
        }
            break;
        case SearchTimeout: {
            
            /*
             SearchTimeout. Seach has continued to alloted time
             */
            
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
    
    /*
     Handle deletion of selected flicks when trashBbi pressed
     */
    
    // perform on private queue
    NSManagedObjectContext *context = [CoreDataStack.shared.container viewContext];
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc]
                                              initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = context;
    
    // 171022, ARC cleanup
    __weak AlbumViewController *weakSelf = self;
    
    [privateContext performBlock:^{
        
        AlbumViewController *innerSelf = weakSelf;
        
        // delete all selected flicks
        for (NSIndexPath *indexPath in innerSelf.selectedCellsArray) {
            
            // get flick, bring into privateContext and then delete
            Flick *flick = [innerSelf.frc objectAtIndexPath:indexPath];
            Flick *privateFlick = [privateContext objectWithID:flick.objectID];
            [privateContext deleteObject:privateFlick];
        }
        
        // remove selectedCells from array after being deleted
        [innerSelf.selectedCellsArray removeAllObjects];
        
        // save, test for error
        NSError *error = [CoreDataStack.shared savePrivateContext:privateContext];
        if (error) {
            
            // bad save...show alert
            dispatch_async(dispatch_get_main_queue(), ^{
                [innerSelf presentOKAlertForError:error];
            });
        }
        else {
            
            // good save... update UI..test for all flicks deleted, edit Editing if all deleted
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [innerSelf configureFlickScrollView];
                innerSelf.trashBbi.enabled = NO;
                
                if (innerSelf.frc.fetchedObjects.count == 0)
                    [innerSelf setEditing:NO animated:YES];
            });
        }
    }];
}
     
- (void)reloadAlbumBbiPressed:(id)sender {
    
    /*
     Handle reloading a new album. Delete all flicks currentl in collectionView and then load
     a new album
     */
    
    // return progress to 0.0
    [_progressView setProgress:0.0 animated:NO];
    
    /*
     flick deletion and album reload is perfomed in block that is passed into an AlertVC to fire if "Proceed"
     action is selected.
     
     The Alert is presented if non-zero number of flicks are in collectionView, otherwise the block is
     simply fired without an Alert warning.
     */
    
    // create completion for AlertVC "proceed" action
    void (^proceedActionCompletion)(void);
    
    // 171022, ARC cleanup
    __weak AlbumViewController *weakSelf = self;
    proceedActionCompletion = ^{
      
        // 171022, ARC cleanup
        AlbumViewController *innerSelf = weakSelf;
        
        // perform on private queue
        NSManagedObjectContext *context = [CoreDataStack.shared.container viewContext];
        NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc]
                                                  initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        privateContext.parentContext = context;
        [privateContext performBlock:^{
            
            // retrieve pin into private context..delete all flicks from pin
            Pin *privatePin = (Pin *)[privateContext objectWithID:innerSelf.pin.objectID];
            for (Flick *flick in privatePin.flicks)
                [privateContext deleteObject:flick];
            
            // save, test for error
            NSError *error = [CoreDataStack.shared savePrivateContext:privateContext];
            if (error) {
                
                // error during save
                dispatch_async(dispatch_get_main_queue(), ^{
                    [innerSelf presentOKAlertForError:error];
                });            }
            else {
                
                // good save. Update UI
                dispatch_async(dispatch_get_main_queue(), ^{
                    innerSelf.viewMode = Predownloading;
                    [innerSelf configureViewMode];
                    [innerSelf downloadAlbumForPin:_pin];
                });
            }
        }];
    };
    
    // present Alert if flicks present..otherwise fire block to download new album
    if ([self.frc.fetchedObjects count] > 0)
        [self presentCancelProceedAlertWithTitle:@"Load new album"
                                         message:@"Delete all flicks and replace with newly downloaded album"
                                      completion:proceedActionCompletion];
    else
        proceedActionCompletion();
}

- (void)shareFlickBbiPressed:(id)sender {
    
    /*
     Present an ActivityVC to share the flick that is currently visible in scrollView
     */
    
    // retrieve flick
    CGFloat offset = _flickScrollView.contentOffset.x;
    NSUInteger index = (NSUInteger)(offset / _flickScrollView.frame.size.width);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    Flick *flick = [self.frc objectAtIndexPath:indexPath];
    UIImage *image = [UIImage imageWithData:flick.imageData];
    
    // create message for share
    NSString *message = @"Hello";
    if (_pin.title)
        message = [NSString stringWithFormat:@"Hello from %@ !", _pin.title];
    
    // create and config with flick and message
    UIActivityViewController *controller = [[UIActivityViewController alloc]
                                            initWithActivityItems:@[message, image]
                                            applicationActivities:nil];
    
    [self presentViewController:controller animated:YES completion:nil];
}
@end
