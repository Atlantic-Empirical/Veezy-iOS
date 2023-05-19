//
//  ORUserListView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 16/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORUserListView.h"
#import "ORUserProfileView.h"
#import "ORUserCell.h"

@interface ORUserListView ()

@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic, strong) NSMutableArray *followRequests;
@property (nonatomic, assign) BOOL hasFollowRequests;

@end

@implementation ORUserListView

static NSString *followCell = @"FollowCell";
static NSString *userCell = @"UserCell";

- (void)dealloc
{
    self.tableView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithUsers:(NSArray *)users andFollowRequests:(NSArray *)followRequests
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.users = [[users sortedArrayUsingComparator:^NSComparisonResult(OREpicFriend *f1, OREpicFriend *f2) {
        return [f1.name compare:f2.name];
    }] mutableCopy];
    
    self.followRequests = [followRequests mutableCopy];
    self.hasFollowRequests = (self.followRequests.count > 0);
    
    return self;
}

- (id)initWithUsers:(NSArray *)users
{
    return [self initWithUsers:users andFollowRequests:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORStatusBarTapped:) name:@"ORStatusBarTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORFollowingUpdated:) name:@"ORFollowingUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORFollowersUpdated:) name:@"ORFollowersUpdated" object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.users.count == 0) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - UITableViewDataSource / UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (self.hasFollowRequests) ? self.users.count + 1 : self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OREpicFriend *friend = nil;
    
    if (self.hasFollowRequests) {
        if (indexPath.row == 0) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:followCell];
            if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:followCell];
            
            cell.textLabel.text = [NSString stringWithFormat:@"%d pending follow requests", self.followRequests.count];
            cell.detailTextLabel.text = @"Tap to approve or deny";
            return cell;
        }
        
        friend = self.users[indexPath.row - 1];
    } else {
        friend = self.users[indexPath.row];
    }
    
    ORUserCell *cell = [tableView dequeueReusableCellWithIdentifier:userCell];
    if (!cell) cell = [[ORUserCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:userCell];
    cell.user = friend;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    OREpicFriend *friend = nil;
    
    if (self.hasFollowRequests) {
        if (indexPath.row == 0) {
            ORUserListView *vc = [[ORUserListView alloc] initWithUsers:self.followRequests];
            vc.isRequestsList = YES;
            vc.title = @"Requests";
            [self.navigationController pushViewController:vc animated:YES];
            return;
        }
        
        friend = self.users[indexPath.row - 1];
    } else {
        friend = self.users[indexPath.row];
    }
    
    ORUserProfileView *profile = [[ORUserProfileView alloc] initWithFriend:friend];
    [self.navigationController pushViewController:profile animated:YES];
}

#pragma mark - Custom Methods

- (void)handleORStatusBarTapped:(NSNotification *)n
{
    [self.tableView setContentOffset:CGPointMake(0.0f, -self.tableView.contentInset.top) animated:YES];
}

- (void)handleORFollowingUpdated:(NSNotification *)n
{
    if (self.isFollowingList) {
        self.users = [[CurrentUser.following sortedArrayUsingComparator:^NSComparisonResult(OREpicFriend *f1, OREpicFriend *f2) {
            return [f1.name compare:f2.name];
        }] mutableCopy];
        
        [self.tableView reloadData];
    }
}

- (void)handleORFollowersUpdated:(NSNotification *)n
{
    OREpicFriend *friend = (OREpicFriend *)n.object;
    
    if (self.isRequestsList) {
        if (friend) [self.users removeObject:friend];
        [self.tableView reloadData];
    } else if (self.isFollowersList) {
        self.users = [[CurrentUser.followers sortedArrayUsingComparator:^NSComparisonResult(OREpicFriend *f1, OREpicFriend *f2) {
            return [f1.name compare:f2.name];
        }] mutableCopy];

        if (friend) [self.followRequests removeObject:friend];
        self.hasFollowRequests = (self.followRequests.count > 0);
        [self.tableView reloadData];
    }
}

@end
