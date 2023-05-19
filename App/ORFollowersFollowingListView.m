//
//  ORFollowersFollowingListView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 6/15/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORFollowersFollowingListView.h"
#import "ORUserCell.h"
#import "ORUserProfileView.h"

@interface ORFollowersFollowingListView () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSMutableOrderedSet *filteredList;
@property (nonatomic, strong) NSMutableOrderedSet *fullList;
@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic, assign) BOOL forFollowers;

@end

@implementation ORFollowersFollowingListView

static NSString *contactCell = @"ContactCell";

- (void)dealloc
{
    self.searchBar.delegate = nil;
    self.tblMain.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initForFollowers:(BOOL)forFollowers
{
    self = [super initWithNibName:@"ORFollowersFollowingListView" bundle:nil];
    if (self) {
		_forFollowers = forFollowers;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
//	[self.tblMain registerNib:[UINib nibWithNibName:@"ORUserCell" bundle:nil] forCellReuseIdentifier:contactCell];

	self.refreshControl = [[UIRefreshControl alloc] init];
	[self.refreshControl addTarget:self action:@selector(refreshAction) forControlEvents:UIControlEventValueChanged];
	self.refreshControl.tintColor = [APP_COLOR_PRIMARY colorWithAlphaComponent:0.3f];
	
    UITableViewController *t1 = [[UITableViewController alloc] init];
    t1.tableView = self.tblMain;
    t1.refreshControl = self.refreshControl;
	
	self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 44.0f)];
    self.searchBar.delegate = self;
    self.tblMain.tableHeaderView = self.searchBar;
    
	if (self.forFollowers) {
		self.title = NSLocalizedStringFromTable(@"FollowersViewTitle", @"UserProfile", @"Title for the followers view in Profile");
		[self refreshFollowersList];
	} else {
		self.title = NSLocalizedStringFromTable(@"FollowingViewTitle", @"UserProfile", @"Title for the following view in Profile");
		[self refreshFollowingList];
	}

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0f;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.filteredList.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ORUserCell *cell = [tableView dequeueReusableCellWithIdentifier:contactCell];
	if (!cell) cell = [[ORUserCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:contactCell];
	OREpicFriend *user = self.filteredList[indexPath.row];
	cell.user = user;
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
	[self openProfileViewForUser:self.filteredList[indexPath.row]];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	UILabel *l = [[UILabel alloc] init];
	l.text = [NSString localizedStringWithFormat:@"%@: %d ", self.forFollowers ? NSLocalizedStringFromTable(@"FollowersFooterViewLabel", @"UserProfile", @"viewForFooterInSection label Followers: !?") : NSLocalizedStringFromTable(@"FollowingFooterViewLabel", @"UserProfile", @"viewForFooterInSection label Following: !?"), self.filteredList.count];
	l.textAlignment = NSTextAlignmentCenter;
	l.backgroundColor = [UIColor whiteColor];
	l.textColor = [UIColor darkGrayColor];
	return l;
}

- (float)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	return 30.0f;
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	if (!ORIsEmpty(searchText)) {
		self.filteredList = [NSMutableOrderedSet orderedSetWithCapacity:10];
		for (OREpicFriend *f in self.fullList) {
			NSUInteger result = [f.name rangeOfString:searchText options:NSCaseInsensitiveSearch].location;
			if (result != NSNotFound) [self.filteredList addObject:f];
		}
	} else {
		self.filteredList = self.fullList;
	}
	
	[self.tblMain reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	self.filteredList = self.fullList;
	[self.tblMain reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.view endEditing:YES];
}

#pragma mark - Refresh Control

- (void)refreshAction
{
	if (self.forFollowers) {
		[self refreshFollowersList];
	} else {
		[self refreshFollowingList];
	}
}

#pragma mark - Custom

- (void)openProfileViewForUser:(OREpicFriend*)friend
{
	ORUserProfileView *profile = [[ORUserProfileView alloc] initWithFriend:friend];
	[self.navigationController pushViewController:profile animated:YES];
}

- (void)refreshFollowingList
{
    [self.refreshControl beginRefreshing];
    __weak ORFollowersFollowingListView *weakSelf = self;
    
    [CurrentUser reloadFollowingForceReload:NO completion:^(NSError *error) {
        if (error) NSLog(@"Error: %@", error);
		
		weakSelf.fullList = CurrentUser.following;
        weakSelf.filteredList = CurrentUser.following;
        [weakSelf.tblMain reloadData];
        [weakSelf.refreshControl endRefreshing];
    }];
}

- (void)refreshFollowersList
{
    [self.refreshControl beginRefreshing];
    __weak ORFollowersFollowingListView *weakSelf = self;
    
    [CurrentUser reloadFollowersForceReload:NO completion:^(NSError *error) {
        if (error) NSLog(@"Error: %@", error);
        
        weakSelf.fullList = CurrentUser.followers;
        weakSelf.filteredList = CurrentUser.followers;
        [weakSelf.tblMain reloadData];
        [weakSelf.refreshControl endRefreshing];
    }];
}

@end
