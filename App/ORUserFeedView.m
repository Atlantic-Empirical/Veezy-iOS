//
//  ORHomeView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 28/03/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORUserFeedView.h"
#import "ORVideoCell.h"
#import "ORLoadingCell.h"
#import "ORUserProfileView.h"
#import "ORWatchView.h"

@interface ORUserFeedView () <UISearchBarDelegate>

@property (nonatomic, strong) NSMutableOrderedSet *items;
@property (nonatomic, strong) NSMutableOrderedSet *filteredItems;
@property (nonatomic, strong) UIRefreshControl *refresh;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (nonatomic, assign) BOOL isRefreshing;
@property (nonatomic, assign) BOOL isLoadingMore;
@property (nonatomic, assign) BOOL haveMore;
@property (nonatomic, assign) BOOL isFiltering;
@property (nonatomic, assign) BOOL isFirstLoad;
@property (nonatomic, assign) BOOL isFeedVisible;
@property (nonatomic, strong) NSString *lastId;
@property (nonatomic, strong) ORVideoCell *prototypeCell;

@end

@implementation ORUserFeedView

static NSString *cellVideo = @"cellVideo";
static NSString *cellLoading = @"cellLoading";

- (void)dealloc
{
    self.searchBar.delegate = nil;
    self.tableView.delegate = nil;
    self.refresh = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"";
	self.screenName	= @"Feed";
	
    self.prototypeCell = [[[NSBundle mainBundle] loadNibNamed:@"ORVideoCell" owner:self options:nil] firstObject];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ORVideoCell" bundle:nil] forCellReuseIdentifier:cellVideo];
    [self.tableView registerNib:[UINib nibWithNibName:@"ORLoadingCell" bundle:nil] forCellReuseIdentifier:cellLoading];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORUserWillSignOut:) name:@"ORUserWillSignOut" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORUserSignedIn:) name:@"ORUserSignedIn" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORStatusBarTapped:) name:@"ORStatusBarTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle_ORHomeReload:) name:@"ORHomeReload" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle_ORVideoModified:) name:@"ORVideoModified" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle_ORVideoDeleted:) name:@"ORVideoDeleted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle_ORPendingVideosUpdated:) name:@"ORPendingVideosUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle_ORProfileUpdated:) name:@"ORProfileUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle_ORVideoExpirationsChanged:) name:@"ORVideoExpirationsChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle_ORHomeReload:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 44.0f)];
    self.searchBar.delegate = self;
	self.searchBar.placeholder = @"Search";
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.backgroundColor = [UIColor clearColor];
	
    self.tableView.tableHeaderView = self.searchBar;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
	self.tableView.showsVerticalScrollIndicator = NO;
    
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
	self.title = @"F  E  E  D";
    self.isFeedVisible = YES;
    
    if (self.isFirstLoad) {
        self.isFirstLoad = NO;
        [self buildInitialFeedAndRefresh:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
	self.title = @"FEED";
    self.isFeedVisible = NO;
}

#pragma mark - Notifications

- (void)handleORUserWillSignOut:(NSNotification *)n
{
    [self buildInitialFeedAndRefresh:NO];
}

- (void)handleORStatusBarTapped:(NSNotification *)n
{
    [self.tableView setContentOffset:CGPointMake(0.0f, 44.0f - self.tableView.contentInset.top) animated:YES];
}

- (void)handle_ORProfileUpdated:(NSNotification *)n
{
    [self.tableView reloadData];
}

- (void)handleORUserSignedIn:(NSNotification *)n
{
    [self refreshFeedForceReload:NO];
}

- (void)handle_ORHomeReload:(NSNotification *)n
{
    [self refreshFeedForceReload:NO];
}

- (void)handle_ORVideoModified:(NSNotification *)n
{
    [self.tableView reloadData];
}

- (void)handle_ORVideoDeleted:(NSNotification *)n
{
    [self refreshFeedForceReload:NO];
}

- (void)handle_ORPendingVideosUpdated:(NSNotification *)n
{
    [self refreshFeedForceReload:NO];
}

- (void)handleORVideoExpirationsChanged:(NSNotification *)n
{
    [self refreshFeedForceReload:YES];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (self.haveMore && !self.isFiltering) ? self.filteredItems.count + 1 : self.filteredItems.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= self.filteredItems.count) {
        return 44.0f;
    } else {
        OREpicFeedItem *item = self.filteredItems[indexPath.row];
        if (item.video.cachedHeight == 0) item.video.cachedHeight = [self.prototypeCell heightForCellWithVideo:item.video];
        return item.video.cachedHeight;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.filteredItems.count) {
        OREpicFeedItem *item = self.filteredItems[indexPath.row];
        ORVideoCell *cell = [tableView dequeueReusableCellWithIdentifier:cellVideo forIndexPath:indexPath];
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
    if (indexPath.row >= self.filteredItems.count) return;
    
    OREpicFeedItem *item = self.filteredItems[indexPath.row];
    ORWatchView *vc = [[ORWatchView alloc] initWithVideo:item.video];
    [self.navigationController pushViewController:vc animated:YES];
	self.title = @"Feed";
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (!ORIsEmpty(searchText)) {
        self.isFiltering = YES;
        self.filteredItems = [NSMutableOrderedSet orderedSetWithCapacity:10];
        for (OREpicFeedItem *item in self.items) {
            NSUInteger result = NSNotFound;

            if (item.video) {
                result = [item.video.autoTitle rangeOfString:searchText options:NSCaseInsensitiveSearch].location;
            }
            
            if (item.video.user && result == NSNotFound) {
                result = [item.video.user.name rangeOfString:searchText options:NSCaseInsensitiveSearch].location;
            }
            
            if (item.friend && result == NSNotFound) {
                result = [item.friend.name rangeOfString:searchText options:NSCaseInsensitiveSearch].location;
            }

            if (result != NSNotFound) {
                [self.filteredItems addObject:item];
            }
        }
    } else {
        self.isFiltering = NO;
        self.filteredItems = self.items;
    }
    
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.isFiltering = NO;
    self.filteredItems = self.items;
    
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.view endEditing:YES];
}

#pragma mark - Feed Logic

- (void)refreshFeedForceReload:(BOOL)forceReload
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
    self.isFiltering = NO;
    self.searchBar.text = nil;
    [self.refresh beginRefreshing];
    if (forceReload) [self.tableView setContentOffset:CGPointMake(0, -self.refresh.frame.size.height) animated:YES];
    
    __weak ORUserFeedView *weakSelf = self;
    self.haveMore = NO;
    self.lastId = nil;

    [[ORDataController sharedInstance] userFeedForceReload:forceReload cacheOnly:NO completion:^(NSError *error, BOOL final, NSArray *feed) {
        if (error) {
            NSLog(@"Error: %@", error);
            
            weakSelf.isRefreshing = NO;
            [weakSelf.refresh endRefreshing];
            
            return;
        }
        
        if (feed.count > 0) {
            weakSelf.items = [NSMutableOrderedSet orderedSetWithArray:feed];
            weakSelf.filteredItems = weakSelf.items;
            
            OREpicFeedItem *item = weakSelf.items.lastObject;
            if (item) weakSelf.lastId = item.itemId;
        }

        if (final && weakSelf.lastId) weakSelf.haveMore = YES;
        [weakSelf.tableView reloadData];

        if (final) {
            weakSelf.isRefreshing = NO;
            [weakSelf.refresh endRefreshing];
            [weakSelf.tableView setContentOffset:CGPointMake(0, 44.0f) animated:YES];
            
            if (RVC.currentState == ORUIStateMainInterface && self.isFeedVisible) {
                [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
                CurrentUser.feedCount = 0;
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
    
    if (self.items.count == 0) return [self refreshFeedForceReload:NO];
    
    self.isLoadingMore = YES;
    __weak ORUserFeedView *weakSelf = self;
    
    NSLog(@"Loading more feed items...");
    
    [ApiEngine userFeedWithLimit:FEED_LIMIT lastId:self.lastId cb:^(NSError *error, NSArray *result) {
        if (error) NSLog(@"Error: %@", error);
        if (!weakSelf.isLoadingMore || !weakSelf) return;
        
        if (result && result.count > 0) {
            [weakSelf.items addObjectsFromArray:result];
            weakSelf.filteredItems = weakSelf.items;
            
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
    self.filteredItems = self.items;
    [self.tableView reloadData];
    
    if (refresh) {
        [self refreshFeedForceReload:NO];
    }
}

- (void)refreshAction
{
    [self refreshFeedForceReload:YES];
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
            self.lblReason.text = @"Sign-in to see your friend's videos.";
            [self.btnAction setTitle:@"Sign-in" forState:UIControlStateNormal];
        } else {
            self.lblReason.text = @"Find and follow your friends to see their videos here.";
            [self.btnAction setTitle:@"Find Friends" forState:UIControlStateNormal];
        }
    }
}

- (void)btnAction_TouchUpInside:(id)sender
{
    if (CurrentUser.accountType == 3) {
        [RVC presentSignInWithMessage:@"Sign-in to see videos from friends!" completion:^(BOOL success) {
            if (success) {
                [self refreshFeedForceReload:YES];
            }
        }];
    } else {
        ORUserProfileView *vc = [[ORUserProfileView alloc] initWithFriend:CurrentUser.asFriend];
        vc.openInConnect = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - Keyboard

- (void)tapGesture:(UITapGestureRecognizer *)sender
{
    [self.view endEditing:YES];
    
    if (self.tapGesture) {
        [self.view removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
}

-(void)keyboardWillShow:(NSNotification*)notify
{
    NSDictionary* keyboardInfo = [notify userInfo];
    NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    CGFloat keyboardHeight = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;

    if (self.tapGesture) {
        [self.view removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
    
    [UIView animateWithDuration:[animationDuration doubleValue] animations:^{
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
    }];
    
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    self.tapGesture.cancelsTouchesInView = YES;
    [self.view addGestureRecognizer:self.tapGesture];
}

-(void)keyboardWillHide:(NSNotification*)notify
{
    NSDictionary* keyboardInfo = [notify userInfo];
    NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    [UIView animateWithDuration:[animationDuration doubleValue] animations:^{
        self.tableView.contentInset = UIEdgeInsetsZero;
    }];

    if (self.tapGesture) {
        [self.view removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
}

@end
