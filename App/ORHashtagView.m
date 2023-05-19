//
//  ORHomeView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 28/03/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORHashtagView.h"
#import "ORVideoCell.h"
#import "ORLoadingCell.h"
#import "ORUserProfileView.h"
#import "ORWatchView.h"

@interface ORHashtagView () <UISearchBarDelegate>

@property (nonatomic, strong) NSMutableOrderedSet *items;
@property (nonatomic, strong) NSMutableOrderedSet *filteredItems;
@property (nonatomic, strong) UIRefreshControl *refresh;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (nonatomic, assign) BOOL isRefreshing;
@property (nonatomic, assign) BOOL isFiltering;
@property (nonatomic, assign) BOOL isFirstLoad;
@property (nonatomic, assign) BOOL isFeedVisible;
@property (nonatomic, strong) ORVideoCell *prototypeCell;
@property (nonatomic, strong) NSString *hashtag;

@end

@implementation ORHashtagView

static NSString *cellVideo = @"cellVideo";
static NSString *cellLoading = @"cellLoading";

- (void)dealloc
{
    self.searchBar.delegate = nil;
    self.tableView.delegate = nil;
    self.refresh = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithHashtag:(NSString *)hashtag
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.hashtag = hashtag;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"#%@", self.hashtag];
	self.screenName	= @"Hashtag";
	
    self.prototypeCell = [[[NSBundle mainBundle] loadNibNamed:@"ORVideoCell" owner:self options:nil] firstObject];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ORVideoCell" bundle:nil] forCellReuseIdentifier:cellVideo];
    [self.tableView registerNib:[UINib nibWithNibName:@"ORLoadingCell" bundle:nil] forCellReuseIdentifier:cellLoading];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORStatusBarTapped:) name:@"ORStatusBarTapped" object:nil];
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
    self.isFeedVisible = YES;
    
    if (self.isFirstLoad) {
        self.isFirstLoad = NO;
        [self refreshFeedForceReload:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.isFeedVisible = NO;
}

#pragma mark - Notifications

- (void)handleORStatusBarTapped:(NSNotification *)n
{
    [self.tableView setContentOffset:CGPointMake(0.0f, 44.0f - self.tableView.contentInset.top) animated:YES];
}

- (void)handle_ORVideoModified:(NSNotification *)n
{
    [self.tableView reloadData];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filteredItems.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= self.filteredItems.count) {
        return 44.0f;
    } else {
        OREpicVideo *video = self.filteredItems[indexPath.row];
        if (video.cachedHeight == 0) video.cachedHeight = [self.prototypeCell heightForCellWithVideo:video];
        return video.cachedHeight;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OREpicVideo *video = self.filteredItems[indexPath.row];
    ORVideoCell *cell = [tableView dequeueReusableCellWithIdentifier:cellVideo forIndexPath:indexPath];
    cell.video = video;
    cell.parent = self;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row >= self.filteredItems.count) return;
    
    OREpicVideo *video = self.filteredItems[indexPath.row];
    ORWatchView *vc = [[ORWatchView alloc] initWithVideo:video];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (!ORIsEmpty(searchText)) {
        self.isFiltering = YES;
        self.filteredItems = [NSMutableOrderedSet orderedSetWithCapacity:10];
        for (OREpicVideo *video in self.items) {
            NSUInteger result = NSNotFound;

            result = [video.autoTitle rangeOfString:searchText options:NSCaseInsensitiveSearch].location;
            
            if (video.user && result == NSNotFound) {
                result = [video.user.name rangeOfString:searchText options:NSCaseInsensitiveSearch].location;
            }
            
            if (result != NSNotFound) {
                [self.filteredItems addObject:video];
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
    if (self.isRefreshing) return;
    
    self.isRefreshing = YES;
    self.isFiltering = NO;
    self.searchBar.text = nil;
    [self.refresh beginRefreshing];
    [self.tableView setContentOffset:CGPointMake(0, -self.refresh.frame.size.height) animated:YES];
    
    __weak ORHashtagView *weakSelf = self;

    [ApiEngine videosWithHashtag:self.hashtag completion:^(NSError *error, NSArray *result) {
        if (error) {
            NSLog(@"Error: %@", error);
            
            weakSelf.isRefreshing = NO;
            [weakSelf.refresh endRefreshing];
            
            return;
        }
        
        if (result.count > 0) {
            weakSelf.items = [NSMutableOrderedSet orderedSetWithArray:result];
            weakSelf.filteredItems = weakSelf.items;
        }

        [weakSelf.tableView reloadData];
        weakSelf.isRefreshing = NO;
        [weakSelf.refresh endRefreshing];
        [weakSelf.tableView setContentOffset:CGPointMake(0, 44.0f) animated:YES];
    }];
}

- (void)refreshAction
{
    [self refreshFeedForceReload:YES];
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
