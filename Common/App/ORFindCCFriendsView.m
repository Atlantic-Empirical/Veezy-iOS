//
//  ORFindCCFriendsView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 01/05/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORFindCCFriendsView.h"
#import "ORPushNotificationPermissionView.h"
#import "ORInviteUserCell.h"
#import "ORUserCell.h"
#import "ORContact.h"

@interface ORFindCCFriendsView () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UISearchBarDelegate>

@property (nonatomic, strong) NSArray *notFollowing;
@property (nonatomic, strong) NSArray *alreadyFollowing;
@property (nonatomic, strong) NSMutableArray *contacts;
@property (nonatomic, strong) NSMutableArray *filteredContacts;
@property (nonatomic, assign) BOOL shouldUpdateView;
@property (nonatomic, strong) OREpicFriend *followed;
@property (nonatomic, strong) UISearchBar *searchBar;

@end

@implementation ORFindCCFriendsView

static NSString *userCell = @"UserCell";

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithNotFollowing:(NSArray *)notFollowing andFollowing:(NSArray *)following andContacts:(NSArray *)contacts
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.notFollowing = notFollowing;
    self.alreadyFollowing = following;
    self.contacts = [contacts mutableCopy];
    self.filteredContacts = self.contacts;
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.transitioningDelegate = self;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.screenName = @"FindFriends";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self.tblFriends registerNib:[UINib nibWithNibName:@"ORInviteUserCell" bundle:nil] forCellReuseIdentifier:userCell];

    self.viewContent.layer.cornerRadius = 2.0f;
    self.btnFollowAll.layer.cornerRadius = 5.0f;
    
    if (self.notFollowing.count > 0) {
        [self.btnFollowAll setTitle:[NSString stringWithFormat:@"Follow all %d friends", self.notFollowing.count] forState:UIControlStateNormal];
    }

	self.aiLoading.color = APP_COLOR_PRIMARY;
    
    UISearchBar *search = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 44.0f)];
    search.delegate = self;
	search.placeholder = @"Pick a Friend to Invite";
    search.searchBarStyle = UISearchBarStyleMinimal;
    self.tblFriends.tableHeaderView = search;
    self.searchBar = search;
    
    ORContact *c = [self.contacts firstObject];
    
    if (c) {
        self.lblDescription.text = [NSString stringWithFormat:@"%@ friends on %@", c.typeName, APP_NAME];
    } else {
        self.lblDescription.text = [NSString stringWithFormat:@"Your friends on %@", APP_NAME];
    }
    
    [self showAvatars];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.contacts.count == 0) {
        CGRect f = self.viewContent.frame;
        f.size.height = CGRectGetMaxY(self.btnFollowAll.frame) + 10.0f;
        f.origin.y = floorf(CGRectGetMaxY(self.view.bounds) / 2 - f.size.height / 2);
        self.viewContent.frame = f;
        
        f = self.btnClose.frame;
        f.origin.y = CGRectGetMinY(self.viewContent.frame);
        self.btnClose.frame = f;
    }

    self.shouldUpdateView = YES;
}

- (void)viewDidLayoutSubviews
{
    if (self.shouldUpdateView) {
        self.shouldUpdateView = NO;
        [self updateContentView];
    }
}

- (void)updateContentView
{
    CGRect f = self.viewContent.bounds;
    
    if (self.notFollowing.count > 0) {
        f.origin.y = CGRectGetMaxY(self.btnFollowAll.frame) + 10.0f;
        f.size.height -= f.origin.y;
    } else {
        f.origin.y = CGRectGetMinY(self.btnFollowAll.frame);
        f.size.height -= f.origin.y;
    }
    
    self.tblFriends.frame = f;
    
    f.origin.y += 44.0f;
    f.size.height -= 44.0f;
    self.viewOverlay.frame = f;
    
    self.tblFriends.contentInset = UIEdgeInsetsZero;
}

#pragma mark - Transition and Presentation

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self;
}

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self;
}

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.25;
}

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController* vc1 = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController* vc2 = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView* con = [transitionContext containerView];
    UIView* v1 = vc1.view;
    UIView* v2 = vc2.view;
    
    if (vc2 == self) { // presenting
        [con addSubview:v2];
        v2.frame = v1.frame;
        self.viewContent.transform = CGAffineTransformMakeScale(1.6,1.6);
        self.btnClose.hidden = YES;
        v2.alpha = 0.0f;
        v1.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        
        [UIView animateWithDuration:0.25 animations:^{
            v2.alpha = 1.0f;
            self.viewContent.transform = CGAffineTransformIdentity;
            self.btnClose.hidden = NO;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else { // dismissing
        [UIView animateWithDuration:0.25 animations:^{
            self.viewContent.transform = CGAffineTransformMakeScale(0.5,0.5);
            self.btnClose.hidden = YES;
            v1.alpha = 0.0f;
        } completion:^(BOOL finished) {
            v2.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
            [transitionContext completeTransition:YES];
        }];
    }
}

#pragma mark - Orientation

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UITableViewDataSource / UITableViewDelegate

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filteredContacts.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ORInviteUserCell *cell = [tableView dequeueReusableCellWithIdentifier:userCell forIndexPath:indexPath];
    ORContact *contact = self.filteredContacts[indexPath.row];
    
    cell.backgroundColor = (indexPath.row % 2 == 0) ? APP_COLOR_LIGHT_GREY : APP_COLOR_LIGHTER_GREY;
    cell.contact = contact;
    cell.parent = self;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.view endEditing:YES];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (!ORIsEmpty(searchText)) {
        self.filteredContacts = [NSMutableArray arrayWithCapacity:1];
        for (ORContact *c in self.contacts) {
            NSUInteger result = [c.name rangeOfString:searchText options:NSCaseInsensitiveSearch].location;
            
            if (result != NSNotFound) {
                [self.filteredContacts addObject:c];
            }
        }
        
        self.viewOverlay.alpha = (self.filteredContacts.count > 0) ? 0 : 1.0f;
    } else {
        self.filteredContacts = self.contacts;
        self.viewOverlay.alpha = 1.0f;
    }
    
    [self.tblFriends reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.filteredContacts = self.contacts;
    [self.tblFriends reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.view endEditing:YES];
}

#pragma mark - Custom Methods

- (void)close
{
    if (self.completionBlock) self.completionBlock(self.followed != nil);
}

- (void)segType_ValueChanged:(id)sender
{
    [self.tblFriends reloadData];
}

- (void)btnClose_TouchUpInside:(id)sender
{
    [self close];
}

- (void)btnFollowAll_TouchUpInside:(id)sender
{
    self.view.userInteractionEnabled = NO;
    self.btnFollowAll.hidden = YES;
    [self.aiLoading startAnimating];
    
    NSMutableArray *userIds = [NSMutableArray arrayWithCapacity:self.notFollowing.count];
    
    for (OREpicFriend *friend in self.notFollowing) {
        [userIds addObject:friend.userId];
    }
    
    NSUInteger followed = userIds.count;
    __weak ORFindCCFriendsView *weakSelf = self;
    
    [ApiEngine followUsers:userIds completion:^(NSError *error, BOOL result) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else if (result) {
            for (OREpicFriend *friend in weakSelf.notFollowing) {
                [CurrentUser setFollowing:YES forFriend:friend];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORFollowingUpdated" object:nil];
            CurrentUser.friendsToFollow = MAX(0, (CurrentUser.friendsToFollow - followed));
            [CurrentUser saveLocalUser];

            weakSelf.followed = [weakSelf.notFollowing firstObject];
            
            if (!AppDelegate.pushNotificationsEnabled) {
                ORPushNotificationPermissionView *pnpv = [[ORPushNotificationPermissionView alloc] initWithFriend:weakSelf.followed];
                [weakSelf presentViewController:pnpv animated:YES completion:nil];
            }
            
            weakSelf.notFollowing = nil;
        } else {
            weakSelf.btnFollowAll.hidden = NO;
        }

        [weakSelf.aiLoading stopAnimating];
        weakSelf.view.userInteractionEnabled = YES;

        [UIView animateWithDuration:0.2f animations:^{
            [weakSelf updateContentView];
        }];
    }];
}

- (void)showAvatars
{
    [self.viewAvatars.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSUInteger added = 0;
    CGRect f = CGRectMake(6.0f, 2.0f, 34.0f, 34.0f);

    for (OREpicFriend *c in self.notFollowing) {
        if (c.profileImageUrl) {
            UIImageView *img = [[UIImageView alloc] initWithFrame:f];
            img.clipsToBounds = YES;
            img.contentMode = UIViewContentModeScaleAspectFill;
            img.layer.borderWidth = 1.0f;
            img.layer.borderColor = APP_COLOR_PRIMARY.CGColor;
            [self.viewAvatars addSubview:img];
            added++;
            
            NSURL *url = [NSURL URLWithString:c.profileImageUrl];
            [[ORCachedEngine sharedInstance] imageAtURL:url size:f.size fill:YES completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
                if (error) NSLog(@"Error: %@", error);
                if (image) {
                    img.image = image;
                } else {
                    img.image = [UIImage imageNamed:@"profile"];
                }
            }];
            
            if (added == 14) {
                break;
            } else if (added == 7) {
                f.origin.x = 6.0f;
                f.origin.y += 39.0f;
            } else {
                f.origin.x += 39.0f;
            }
        }
    }
    
    if (added < 14) {
        for (OREpicFriend *c in self.alreadyFollowing) {
            if (c.profileImageUrl) {
                UIImageView *img = [[UIImageView alloc] initWithFrame:f];
                img.clipsToBounds = YES;
                img.contentMode = UIViewContentModeScaleAspectFill;
                img.layer.borderWidth = 1.0f;
                img.layer.borderColor = APP_COLOR_LIGHT_PURPLE.CGColor;
                [self.viewAvatars addSubview:img];
                added++;
                
                NSURL *url = [NSURL URLWithString:c.profileImageUrl];
                [[ORCachedEngine sharedInstance] imageAtURL:url size:f.size fill:YES completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
                    if (error) NSLog(@"Error: %@", error);
                    if (image) {
                        img.image = image;
                    } else {
                        img.image = [UIImage imageNamed:@"profile"];
                    }
                }];
                
                if (added == 14) {
                    break;
                } else if (added == 7) {
                    f.origin.x = 6.0f;
                    f.origin.y += 39.0f;
                } else {
                    f.origin.x += 39.0f;
                }
            }
        }
    }
    
    if (added < 14) {
        for (ORContact *c in self.contacts) {
            if (c.imageURL && !c.user) {
                UIImageView *img = [[UIImageView alloc] initWithFrame:f];
                img.clipsToBounds = YES;
                img.contentMode = UIViewContentModeScaleAspectFill;
                [self.viewAvatars addSubview:img];
                added++;
                
                NSURL *url = [NSURL URLWithString:c.imageURL];
                [[ORCachedEngine sharedInstance] imageAtURL:url size:f.size fill:YES completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
                    if (error) NSLog(@"Error: %@", error);
                    if (image) {
                        img.image = image;
                    } else {
                        img.image = [UIImage imageNamed:@"profile"];
                    }
                }];
                
                if (added == 14) {
                    break;
                } else if (added == 7) {
                    f.origin.x = 6.0f;
                    f.origin.y += 39.0f;
                } else {
                    f.origin.x += 39.0f;
                }
            }
        }
    }
}

#pragma mark - KEYBOARD

- (void)viewOverlay_TouchUpInside:(id)sender
{
    [self.view endEditing:YES];
}

-(void)keyboardWillShow:(NSNotification*)notify
{
    NSDictionary* keyboardInfo = [notify userInfo];
    NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    CGFloat keyboardHeight = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    
    self.viewOverlay.hidden = NO;
    self.viewOverlay.alpha = 0;
    self.searchBar.text = nil;
    
    [UIView animateWithDuration:[animationDuration doubleValue] animations:^{
        CGRect f = self.viewContent.bounds;
        f.origin.y = 40.0f;
        f.size.height -= 40.0f;
        self.tblFriends.frame = f;
        
        f.origin.y += 44.0f;
        f.size.height -= 44.0f;
        self.viewOverlay.frame = f;
        self.viewOverlay.alpha = 1.0f;

        self.tblFriends.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight - 30.0f, 0);
    }];
}

-(void)keyboardWillHide:(NSNotification*)notify
{
    NSDictionary* keyboardInfo = [notify userInfo];
    NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    self.viewOverlay.hidden = YES;
    
    [UIView animateWithDuration:[animationDuration doubleValue] animations:^{
        [self updateContentView];
    }];
}

@end
