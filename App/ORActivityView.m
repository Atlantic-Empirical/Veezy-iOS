//
//  ORActivityView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 29/07/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORActivityView.h"
#import "ORActivityItemCell.h"
#import "ORLoadingCell.h"
#import "ORUserProfileView.h"
#import "ORWatchView.h"

@interface ORActivityView ()

@property (nonatomic, strong) NSMutableOrderedSet *items;
@property (nonatomic, strong) UIRefreshControl *refresh;
@property (nonatomic, assign) BOOL isRefreshing;
@property (nonatomic, assign) BOOL isLoadingMore;
@property (nonatomic, assign) BOOL haveMore;
@property (nonatomic, assign) BOOL isFirstLoad;
@property (nonatomic, assign) BOOL isActivityVisible;
@property (nonatomic, strong) NSString *lastId;

@end

@implementation ORActivityView

static NSString *cellNotification = @"cellNotification";
static NSString *cellLoading = @"cellLoading";

- (void)dealloc
{
    self.tableView.delegate = nil;
    self.refresh = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.screenName = @"ActivityList";
	
//    if (self.navigationController.childViewControllers.count == 1) {
//		UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:RVC action:@selector(showCamera)];
//        self.navigationItem.leftBarButtonItem = done;
//    }
    
	self.view.backgroundColor = [UIColor whiteColor];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ORActivityItemCell" bundle:nil] forCellReuseIdentifier:cellNotification];
    [self.tableView registerNib:[UINib nibWithNibName:@"ORLoadingCell" bundle:nil] forCellReuseIdentifier:cellLoading];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORUserWillSignOut:) name:@"ORUserWillSignOut" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORUserSignedIn:) name:@"ORUserSignedIn" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORStatusBarTapped:) name:@"ORStatusBarTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle_ORActivityReload:) name:@"ORActivityReload" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle_ORVideoDeleted:) name:@"ORVideoDeleted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle_ORProfileUpdated:) name:@"ORProfileUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle_ORActivityReload:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    self.refresh = [[UIRefreshControl alloc] init];
	self.refresh.tintColor = [APP_COLOR_PRIMARY colorWithAlphaComponent:0.3f];
    [self.refresh addTarget:self action:@selector(refreshAction) forControlEvents:UIControlEventValueChanged];

    UITableViewController *t = [[UITableViewController alloc] init];
    t.tableView = self.tableView;
    t.refreshControl = self.refresh;

    self.isFirstLoad = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	self.title = @"A  C  T  I  V  I  T  Y";
    self.isActivityVisible = YES;
    
    if (self.isFirstLoad) {
        self.isFirstLoad = NO;
        [self buildInitialFeedAndRefresh:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
	self.title = @"ACTIVITY";
    self.isActivityVisible = NO;
}

#pragma mark - Notifications

- (void)handleORUserWillSignOut:(NSNotification *)n
{
    [self buildInitialFeedAndRefresh:NO];
}

- (void)handleORStatusBarTapped:(NSNotification *)n
{
    [self.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
}

- (void)handle_ORProfileUpdated:(NSNotification *)n
{
    [self.tableView reloadData];
}

- (void)handleORUserSignedIn:(NSNotification *)n
{
    [self refreshActivityForceReload:NO];
}

- (void)handle_ORActivityReload:(NSNotification *)n
{
    [self refreshActivityForceReload:NO];
}

- (void)handle_ORVideoDeleted:(NSNotification *)n
{
    [self refreshActivityForceReload:NO];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (self.haveMore) ? self.items.count + 1 : self.items.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.items.count) {
        OREpicFeedItem *item = self.items[indexPath.row];
        if (item.cachedHeight <= 0) {
            item.cachedHeight = [ORActivityItemCell heightForItem:item];
        }
        
        return item.cachedHeight;
    } else {
        return 44.0f;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.items.count) {
        OREpicFeedItem *item = self.items[indexPath.row];
        ORActivityItemCell *cell = [tableView dequeueReusableCellWithIdentifier:cellNotification forIndexPath:indexPath];
        cell.item = item;
        cell.parent = self;
        return cell;
    } else {
        [self loadMoreItems];
        
        ORLoadingCell *cell = [tableView dequeueReusableCellWithIdentifier:cellLoading forIndexPath:indexPath];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row >= self.items.count) return;
    
    OREpicFeedItem *item = self.items[indexPath.row];
    
    if (item.video) {
        ORWatchView *vc = [[ORWatchView alloc] initWithVideo:item.video];
        if (item.type == ORFeedItemTypeVideoComment) vc.shouldScrollToBottom = YES;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (item.videoId) {
        ORWatchView *vc = [[ORWatchView alloc] initWithVideoId:item.videoId];
        if (item.type == ORFeedItemTypeVideoComment) vc.shouldScrollToBottom = YES;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (item.friend) {
        ORUserProfileView *vc = [[ORUserProfileView alloc] initWithFriend:item.friend];
        if (item.type == ORFeedItemTypeFriendJoined) vc.askToFollow = YES;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (item.friendId) {
        [ApiEngine friendWithId:item.friendId completion:^(NSError *error, OREpicFriend *epicFriend) {
            item.friend = epicFriend;
            ORUserProfileView *vc = [[ORUserProfileView alloc] initWithFriend:item.friend];
            if (item.type == ORFeedItemTypeFriendJoined) vc.askToFollow = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }];
    }
}

#pragma mark - Activity Logic

- (void)refreshActivityForceReload:(BOOL)forceReload
{
    if (CurrentUser.accountType == 3) {
        [self checkForVideos];
        return;
    }

    if (self.isRefreshing) return;

    self.tableView.hidden = NO;
    self.viewNoItems.hidden = YES;
    self.isRefreshing = YES;
    self.isLoadingMore = NO;
    [self.refresh beginRefreshing];
    if (forceReload) [self.tableView setContentOffset:CGPointMake(0, -self.refresh.frame.size.height) animated:YES];
    
    __weak ORActivityView *weakSelf = self;
    self.haveMore = NO;
    self.lastId = nil;
    
    [[ORDataController sharedInstance] userNotificationsForceReload:forceReload cacheOnly:NO completion:^(NSError *error, BOOL final, NSArray *feed) {
        if (error) {
            NSLog(@"Error: %@", error);

            weakSelf.isRefreshing = NO;
            [weakSelf.refresh endRefreshing];

            return;
        }
        
        if (feed.count > 0) {
            weakSelf.items = [NSMutableOrderedSet orderedSetWithArray:feed];
            OREpicFeedItem *item = weakSelf.items.lastObject;
            if (item) weakSelf.lastId = item.itemId;
        }
        
        if (final && weakSelf.lastId) weakSelf.haveMore = YES;
        [weakSelf.tableView reloadData];
        
        if (final) {
            weakSelf.isRefreshing = NO;
            [weakSelf.refresh endRefreshing];
            [weakSelf.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
            
            if (RVC.currentState == ORUIStateMainInterface && self.isActivityVisible) {
                [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
                CurrentUser.notificationCount = 0;
                [CurrentUser saveLocalUser];

                [ApiEngine updateFeedCount:CurrentUser.feedCount notificationCount:CurrentUser.notificationCount forUser:CurrentUser.userId cb:nil];                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ORUpdateBadge" object:nil];
            }
            
            [weakSelf checkForVideos];
        }
    }];
}

- (void)loadMoreItems
{
    if (self.isRefreshing) return;
    if (self.isLoadingMore) return;
    
    if (self.items.count == 0) return [self refreshActivityForceReload:NO];
    
    self.isLoadingMore = YES;
    __weak ORActivityView *weakSelf = self;
    
    NSLog(@"Loading more activity items...");
    
    [ApiEngine userNotificationsWithLimit:FEED_LIMIT lastId:self.lastId cb:^(NSError *error, NSArray *result) {
        if (error) NSLog(@"Error: %@", error);
        if (!weakSelf.isLoadingMore || !weakSelf) return;
        
        if (result && result.count > 0) {
            [weakSelf.items addObjectsFromArray:result];
            
            OREpicFeedItem *item = result.lastObject;
            if (item) {
                weakSelf.lastId = item.itemId;
                weakSelf.haveMore = YES;
            } else {
                weakSelf.haveMore = NO;
            }
        } else {
            weakSelf.haveMore = NO;
        }
        
        weakSelf.isLoadingMore = NO;
        [weakSelf.tableView reloadData];
    }];
}

- (void)buildInitialFeedAndRefresh:(BOOL)refresh
{
    self.items = nil;
    [self.tableView reloadData];
    
    if (refresh) {
        [self refreshActivityForceReload:NO];
    }
}

- (void)refreshAction
{
    [self refreshActivityForceReload:YES];
}

- (void)checkForVideos
{
    if (self.items.count > 0) {
        self.tableView.hidden = NO;
        self.viewNoItems.hidden = YES;
    } else {
        self.tableView.hidden = YES;
        self.viewNoItems.hidden = NO;
        self.lastId = nil;
        
        if (CurrentUser.accountType == 3) {
            self.lblReason.text = @"Sign-in to Veezy to see activity in your videos here.";
            [self.btnAction setTitle:@"Sign-in" forState:UIControlStateNormal];
        } else {
            self.lblReason.text = @"Find and follow your friends to see activity in your videos here.";
            [self.btnAction setTitle:@"Find Friends" forState:UIControlStateNormal];
        }
    }
}

- (void)btnAction_TouchUpInside:(id)sender
{
    if (CurrentUser.accountType == 3) {
        [RVC presentSignInWithMessage:@"Sign-in to see activity in your videos!" completion:^(BOOL success) {
            if (success) {
                [self refreshActivityForceReload:YES];
            }
        }];
    } else {
        ORUserProfileView *vc = [[ORUserProfileView alloc] initWithFriend:CurrentUser.asFriend];
        vc.openInConnect = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
