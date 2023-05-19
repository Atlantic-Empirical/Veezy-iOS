//
//  ORVideosView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 20/03/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORVideosView.h"
#import "ORVideoCell.h"
#import "ORWatchView.h"
#import "ORVideoManagerView.h"
#import "ORFaspPersistentEngine.h"

@interface ORVideosView () <UIGestureRecognizerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) UIRefreshControl *refresh;
@property (strong, nonatomic) NSMutableOrderedSet *videos;
@property (strong, nonatomic) NSDate *lastRefresh;
@property (nonatomic, strong) NSString *cacheFile;
@property (assign, nonatomic) BOOL shouldReload;
@property (strong, nonatomic) UILongPressGestureRecognizer *lpgr;
@property (strong, nonatomic) ORVideoCell *selectedCell;
@property (nonatomic, strong) UIAlertView *alertView;

@end

@implementation ORVideosView

static NSString *cellIdentifier = @"cellIdentifier";

- (void)dealloc
{
    self.alertView.delegate = nil;
    self.tableView.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Videos";
    
    if (self.navigationController.childViewControllers.count == 1) {
        // Camera as left bar button
        UIBarButtonItem *camera = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"camera-icon-black-40x"] style:UIBarButtonItemStylePlain target:RVC action:@selector(showCamera)];
        self.navigationItem.leftBarButtonItem = camera;
        
        // Right swipe to open camera
        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:RVC action:@selector(showCamera)];
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:rightSwipe];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORStatusBarTapped:) name:@"ORStatusBarTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORVideoModifiedOrDeleted:) name:@"ORVideoModified" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORVideoDeleted:) name:@"ORVideoDeleted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORVideoUploaded:) name:@"ORVideoUploaded" object:nil];
    
	[self.tableView registerNib:[UINib nibWithNibName:@"ORVideoItemCell" bundle:nil] forCellReuseIdentifier:cellIdentifier];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 188.0f;
    
    self.refresh = [[UIRefreshControl alloc] init];
	self.refresh.tintColor = [APP_COLOR_FOREGROUND colorWithAlphaComponent:0.3f];
    [self.refresh addTarget:self action:@selector(refreshAction) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = self.refresh;
    
    // Load the cached results if available
    self.cacheFile = [[ORUtility cachesDirectory] stringByAppendingPathComponent:@"user_cache/my_videos.cache"];
    self.videos = [NSKeyedUnarchiver unarchiveObjectWithFile:self.cacheFile];
    [self.tableView reloadData];
    
    if (self.lastRefresh && [[NSDate date] timeIntervalSinceDate:self.lastRefresh] < 300) return;
	self.shouldReload = YES;
	
	self.view.backgroundColor = [UIColor whiteColor];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	[self setupLPGR];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.shouldReload) {
        self.shouldReload = NO;
        self.tableView.contentOffset = CGPointMake(self.tableView.contentOffset.x, self.tableView.contentOffset.y - self.refresh.frame.size.height);
        [self refreshAction];
    }
}

- (void)handleORStatusBarTapped:(NSNotification *)n
{
    [self.tableView setContentOffset:CGPointMake(0.0f, -self.tableView.contentInset.top) animated:YES];
}

- (void)handleORVideoModifiedOrDeleted:(NSNotification *)n
{
    OREpicVideo *video = n.object;
    if (!video) return;

    if ([self.videos containsObject:video]) {
        [NSKeyedArchiver archiveRootObject:self.videos toFile:self.cacheFile];
        [self.tableView reloadData];
    }
}

- (void)handleORVideoDeleted:(NSNotification *)n
{
    OREpicVideo *video = n.object;
    if (!video) return;
    
    if ([self.videos containsObject:video]) {
        [self.videos removeObject:video];
        [NSKeyedArchiver archiveRootObject:self.videos toFile:self.cacheFile];
        [self.tableView reloadData];
    }
}

- (void)handleORVideoUploaded:(NSNotification *)n
{
    OREpicVideo *video = n.object;
    if (!video) return;

    [self.videos insertObject:video atIndex:0];
    [NSKeyedArchiver archiveRootObject:self.videos toFile:self.cacheFile];
    [self.tableView reloadData];
}

#pragma mark - Refresh

- (void)refreshAction
{
    self.lastRefresh = [NSDate date];
    [self.refresh beginRefreshing];
    
    [ApiEngine videosForUser:CurrentUser.userId completion:^(NSError *error, NSArray *result) {
        if (result) {
			self.videos = [NSMutableOrderedSet orderedSetWithArray:result];
            [self addLocalPendingVideos];
            [self.tableView reloadData];
        }
        
        [self.refresh endRefreshing];
    }];
}

- (void)addLocalPendingVideos
{
    NSArray *pending = [[ORFaspPersistentEngine sharedInstance] allPendingVideos];
    if (!self.videos) self.videos = [NSMutableOrderedSet orderedSetWithCapacity:pending.count];
    for (OREpicVideo *video in pending) {
        [self.videos insertObject:video atIndex:0];
    }
    
    // Store the current video list
    [NSKeyedArchiver archiveRootObject:self.videos toFile:self.cacheFile];
}

#pragma mark - UITableView

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 298;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.videos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ORVideoCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
	cell.video = self.videos[indexPath.row];
    cell.parent = self;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
	ORWatchView *vc = [[ORWatchView alloc] initWithVideo:self.videos[indexPath.row]];
	[self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Long Press -> Action Sheet

- (void)setupLPGR
{
	self.lpgr = [[UILongPressGestureRecognizer alloc]
				 initWithTarget:self action:@selector(handleLongPress:)];
	self.lpgr.minimumPressDuration = 0.7;
	self.lpgr.delegate = self;
	[self.tableView addGestureRecognizer:self.lpgr];
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
	CGPoint p = [gestureRecognizer locationInView:self.tableView];
	
	if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
		
	} else if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
		if (indexPath == nil)
			NSLog(@"long press on table view but not on a row");
		else {
			NSLog(@"long press on table view at row %d", indexPath.row);
			
			self.selectedCell = (ORVideoCell*)[self.tableView cellForRowAtIndexPath:indexPath];
			DLog(@"open action sheet");
			[self showActionSheet];
		}
	}
}

- (void)showActionSheet
{
	UIActionSheet *actionSheet;
	
	actionSheet = [[UIActionSheet alloc] initWithTitle:@""
											  delegate:self
									 cancelButtonTitle:@"Cancel"
								destructiveButtonTitle:nil
									 otherButtonTitles:@"Edit", @"Share", @"Delete", nil];
    
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    actionSheet.destructiveButtonIndex = 2;
    [actionSheet showInView:AppDelegate.viewController.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
		
		// EDIT
		ORVideoManagerView *vc = [[ORVideoManagerView alloc] initWithVideo:self.selectedCell.video andPlaces:nil];
		[RVC pushToMainViewController:vc completion:nil];
		
	} else if (buttonIndex == 1) {
		
		// SHARE
		OREpicVideo *v = self.selectedCell.video;
		if ([v.userId isEqualToString:CurrentUser.userId]) {
            if (CurrentUser.accountType == 3) {
                [RVC presentSignInWithMessage:@"Sign-in to share your videos!" completion:^(BOOL success) {
                    if (success) {
                        if (![v.userId isEqualToString:CurrentUser.userId]) v.userId = CurrentUser.userId;
                    }
                }];
                
                return;
            }
			v.creator = [[OREpicFriend alloc] initWithUser:CurrentUser];
			[AppDelegate presentShareActionSheetVideo:v
											 andImage:self.selectedCell.imgThumbnail.image
											  justNow:NO];

		} else {
			[ApiEngine friendWithId:v.userId completion:^(NSError *error, OREpicFriend *epicFriend) {
				if (error) {
					DLog(@"failed to get user for video");
				} else {
					v.creator = epicFriend;
					[AppDelegate presentShareActionSheetVideo:v
													 andImage:self.selectedCell.imgThumbnail.image
													  justNow:NO];
				}
			}];
		}
		
		//	} else if (buttonIndex == 3) {
		//
		//		// UNLIMITED
		//		[[NSNotificationCenter defaultCenter] postNotificationName:@"OROpenCCUnlimited" object:nil];
		//
	} else if (buttonIndex == actionSheet.destructiveButtonIndex) {
		
		// DELETE
		self.alertView = [[UIAlertView alloc] initWithTitle:AppName
														message:[NSString stringWithFormat:@"Are you sure you want to delete this video (%@)? This action cannot be undone.", self.selectedCell.video.name ? self.selectedCell.video.name : @"Untitled"]
													   delegate:self
											  cancelButtonTitle:@"Cancel"
											  otherButtonTitles:@"Delete", nil];
        self.alertView.tag = 0;
		[self.alertView show];
	}
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    if (alertView.cancelButtonIndex == buttonIndex) return;
	
    switch (alertView.tag) {
        case 0: { // Delete Video
            [self deleteVideo];
            break;
        }
    }
}

- (void)deleteVideo
{
    // Cancel the video upload, if pending
    [[ORFaspPersistentEngine sharedInstance] cancelVideoUpload:self.selectedCell.video];

    [ApiEngine deleteVideoWithId:self.selectedCell.video.videoId cb:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
        
        if (result) {
            CurrentUser.videoCount--;
            
            // Delete local files
            NSString *localPath = [[ORUtility documentsDirectory] stringByAppendingPathComponent:self.selectedCell.video.videoId];
			
            BOOL isDir = NO;
            BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:localPath isDirectory:&isDir];
            
            if (result && isDir) {
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:localPath error:&error];
                if (error) NSLog(@"Can't delete local video files: %@", error);
            }
        }
    }];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORVideoDeleted" object:self.selectedCell.video];
}

@end
