//
//  ORProfileView.m
//  epic
//
//  Created by Thomas Purnell-Fisher on 10/24/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORUserProfileView.h"
#import "ORWatchView.h"
#import "ORUserCell.h"
#import "ORUserSettingsView.h"
#import "ORAvatarView.h"
#import "ORFaspPersistentEngine.h"
#import "ORPushNotificationPermissionView.h"
#import "ORUserProfileCell.h"
#import "ORVideoOrderCell.h"
#import "ORLoadingCell.h"
#import "ORVideoCell.h"
#import "ORNoVideosCell.h"
#import "ORMapView.h"
#import "ORPeopleSearchView.h"
#import "ORVideoManagerView.h"
#import "ORExpiredVideoUpsell.h"
#import "ORSubscriptionUpsell.h"

@interface ORUserProfileView () <UISearchBarDelegate, UIAlertViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIRefreshControl *refresh;

@property (nonatomic, strong) NSMutableOrderedSet *cachedVideos;
@property (nonatomic, strong) NSMutableOrderedSet *videos;
@property (nonatomic, strong) NSMutableOrderedSet *filteredVideos;

@property (nonatomic, strong) ORPeopleSearchView *inviteView;

@property (nonatomic, strong) ORUserProfileCell *userCell;
@property (nonatomic, strong) ORVideoOrderCell *orderCell;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIAlertView *alertView;
@property (strong, nonatomic) UIActionSheet *actionSheet;

@property (nonatomic, assign) NSUInteger currentTab;
@property (nonatomic, assign) BOOL shouldLoadVideos;
@property (nonatomic, assign) BOOL isLoadingVideos;
@property (nonatomic, assign) BOOL isOwnUser;
@property (nonatomic, assign) BOOL changedTabs;
@property (nonatomic, assign) BOOL firstLoad;
@property (nonatomic, assign) CGFloat maxHeight;

@property (nonatomic, assign) BOOL isCurrentlyVisible;
@property (nonatomic, strong) ORVideoCell *prototypeCell;

@end

@implementation ORUserProfileView

static NSString *profileCell = @"ProfileCell";
static NSString *videoOrderCell = @"VideoOrderCell";
static NSString *videoCell = @"VideoCell";
static NSString *noVideosCell = @"NoVideosCell";

- (void)dealloc
{
    self.searchBar.delegate = nil;
    self.alertView.delegate = nil;
    self.actionSheet.delegate = nil;
    self.tableView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFriend:(OREpicFriend*)eFriend
{
	self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    NSLog(@"User: %@", eFriend.userId);
    
    _user = eFriend;
	
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.screenName = @"ProfileView";
	
//    if (self.navigationController.childViewControllers.count == 1) {
//		UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction)];
//        self.navigationItem.leftBarButtonItem = done;
//    }

	if ([self.user.userId isEqualToString:CurrentUser.userId]) {
        self.isOwnUser = YES;
		self.title = @"Y  O  U";

        UIBarButtonItem *sprocket = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"manage-user-icon-wire-white-40x"] style:UIBarButtonItemStylePlain target:self action:@selector(presentUserSettings)];
        self.navigationItem.rightBarButtonItem = sprocket;
		self.viewSeparator0.hidden = NO;
		self.viewSeparator2.hidden = NO;
		self.btnNetwork.hidden = NO;
    } else {
        self.isOwnUser = NO;
		self.title = [self.user.name componentsSeparatedByString:@" "][0]; // show only first name
		self.title = [self.title substringToIndex: MIN(10, self.title.length)]; // truncate to first 10 characters
		self.viewSeparator0.hidden = YES;
		self.viewSeparator2.hidden = YES;
		self.btnNetwork.hidden = YES;
	}
    
    self.prototypeCell = [[[NSBundle mainBundle] loadNibNamed:@"ORVideoCell" owner:self options:nil] firstObject];
    [self.tableView registerNib:[UINib nibWithNibName:@"ORUserProfileCell" bundle:nil] forCellReuseIdentifier:profileCell];
    [self.tableView registerNib:[UINib nibWithNibName:@"ORVideoOrderCell" bundle:nil] forCellReuseIdentifier:videoOrderCell];
    [self.tableView registerNib:[UINib nibWithNibName:@"ORVideoCell" bundle:nil] forCellReuseIdentifier:videoCell];
    [self.tableView registerNib:[UINib nibWithNibName:@"ORNoVideosCell" bundle:nil] forCellReuseIdentifier:noVideosCell];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORUserSignedIn:) name:@"ORUserSignedIn" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadUserVideosIfNeeded) name:@"ORUpdateListOfMyVideos" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadUserVideosIfNeeded) name:@"ORVideoDeleted" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadLikedVideosIfNeeded) name:@"ORVideoLikedUnliked" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadUserVideosIfNeeded) name:@"ORVideoModified" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadUserVideosIfNeeded) name:@"ORPendingVideosUpdated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshProfile) name:@"ORProfileUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshProfile) name:@"ORFollowingUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshProfile) name:@"ORFollowersUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORStatusBarTapped:) name:@"ORStatusBarTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORSubscriptionEnded:) name:@"ORSubscriptionEnded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORVideoExpirationsChanged:) name:@"ORVideoExpirationsChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    
	self.refresh = [[UIRefreshControl alloc] init];
    [self.refresh addTarget:self action:@selector(refreshAction) forControlEvents:UIControlEventValueChanged];
	self.refresh.tintColor = [APP_COLOR_PRIMARY colorWithAlphaComponent:0.3f];
    tableViewController.refreshControl = self.refresh;
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 44.0f)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search";
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.backgroundColor = [UIColor clearColor];
    
    [self configureTabButtons];
    self.shouldLoadVideos = YES;
    self.firstLoad = YES;
	
	self.viewIndicator.layer.cornerRadius = 5.0f;
	self.viewIndicator.backgroundColor = APP_COLOR_PRIMARY;
	
	self.inviteView = [ORPeopleSearchView new];
    [self addChildViewController:self.inviteView];
	[self.viewPeopleHost addSubview:self.inviteView.view];
    [self.inviteView didMoveToParentViewController:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.shouldLoadVideos) {
        self.shouldLoadVideos = NO;
        [self reloadUserVideosForceReload:NO];
    }
    
    if (self.openInConnect) {
        self.openInConnect = NO;
        [self btnNetwork_TouchUpInside:self.btnNetwork];
    }
		
	if ([self.user.userId isEqualToString:CurrentUser.userId]) {
		self.title = @"Y  O  U";

        if (self.firstLoad) {
            [self btnVideos_TouchUpInside:self.btnVideos];
            self.firstLoad = NO;
        }
        
        if (CurrentUser.subscriptionExpired) {
            [self showSubscriptionEndedAlert];
            self.isCurrentlyVisible = YES;
        }
	} else {
		self.title = [self.user.name componentsSeparatedByString:@" "][0]; // show only first name
		self.title = [self.title substringToIndex: MIN(10, self.title.length)]; // truncate to first 10 characters
	}

}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.askToFollow && ![CurrentUser.userId isEqualToString:self.user.userId] && ![CurrentUser isFollowingUserId:self.user.userId]) {
        self.askToFollow = NO;
        
        self.alertView.delegate = nil;
        self.alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Follow %@?", self.user.firstName]
                                                    message:[NSString stringWithFormat:@"Would you like to know when %@ shares a video or sends one directly to you?", self.user.firstName]
                                                   delegate:self
                                          cancelButtonTitle:@"Not Now"
                                          otherButtonTitles:@"Yes", nil];
        self.alertView.tag = 1;
        [self.alertView show];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
	if ([self.user.userId isEqualToString:CurrentUser.userId]) {
        self.isCurrentlyVisible = NO;
		self.title = @"YOU";
	} else {
		self.title = [self.user.name componentsSeparatedByString:@" "][0]; // show only first name
		self.title = [self.title substringToIndex: MIN(10, self.title.length)]; // truncate to first 10 characters
	}
}

- (void)handleORStatusBarTapped:(NSNotification *)n
{
    [self.tableView setContentOffset:CGPointMake(0.0f, -self.tableView.contentInset.top) animated:YES];
}

- (void)handleORUserSignedIn:(NSNotification *)n
{
    if (self.isOwnUser) {
        self.user = CurrentUser.asFriend;
        self.cachedVideos = nil;
        [self btnProfile_TouchUpInside:self.btnProfile];
    }
}

- (void)handleORSubscriptionEnded:(NSNotification *)n
{
    if (self.isCurrentlyVisible) {
        [self showSubscriptionEndedAlert];
    }
}

- (void)handleORVideoExpirationsChanged:(NSNotification *)n
{
    if (self.isOwnUser) {
        [self reloadUserVideosForceReload:YES];
    }
}

- (void)showSubscriptionEndedAlert
{
    NSString *title = nil, *message = nil, *button = nil;
    
    if (CurrentUser.subscriptionIsTrial && CurrentUser.trialExpired) {
        title = @"Trial Expired";
        message = @"Any videos more than a week old are now in zombie state - they can’t be opened or played. You can download any of them from the Veezy website until a month from the expiration. You can also start your subscription now.";
        button = @"Start Subscription";
    } else {
        title = @"Subscription Cancelled";
        message = @"Any videos more than a week old are now in zombie state - they can’t be opened or played. You can download any of them from the Veezy website until a month from the cancelation. You can also restart your subscription now.";
        button = @"Restart Subscription";
    }
    
    self.alertView.delegate = nil;
    self.alertView = [[UIAlertView alloc] initWithTitle:title
                                                message:message
                                               delegate:self
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:button, nil];
    self.alertView.tag = 2;
    [self.alertView show];
    
    CurrentUser.subscriptionExpired = NO;
    [CurrentUser saveLocalUser];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)setUser:(OREpicFriend *)user
{
    _user = user;
    [self reloadUserVideosForceReload:NO];
}

#pragma mark - UITableViewDataSource / UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return (self.currentTab == 2) ? 0 : 1;
    } else {
        return (self.currentTab == 0) ? 0 : (self.videos.count == 0) ? 1 : self.filteredVideos.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        self.maxHeight = MAX(tableView.bounds.size.height, 356.0f);
        return (self.currentTab == 0) ? self.maxHeight : 144.0f;
    } else {
        if (self.videos.count == 0) return 140.0f;
        OREpicVideo *video = self.filteredVideos[indexPath.row];
        if (video.cachedHeight == 0) video.cachedHeight = [self.prototypeCell heightForCellWithVideo:video];
        return video.cachedHeight;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && self.currentTab == 0) {
        if (!self.userCell) {
            self.userCell = [self.tableView dequeueReusableCellWithIdentifier:profileCell forIndexPath:indexPath];
        }
        
        self.userCell.user = self.user;
        self.userCell.parent = self;
        
		if (!self.shouldLoadVideos && self.videos) [self.userCell loadMapButtonForVideos:[self.videos array]];
        
        return self.userCell;
    } else if (indexPath.section == 0 && self.currentTab == 1) {
        if (!self.orderCell) {
            self.orderCell = [self.tableView dequeueReusableCellWithIdentifier:videoOrderCell forIndexPath:indexPath];
        }
        
        self.orderCell.user = self.user;
        self.orderCell.parent = self;
        
        return self.orderCell;
    } else {
        if (self.videos.count == 0) {
            ORNoVideosCell *cell = [tableView dequeueReusableCellWithIdentifier:noVideosCell forIndexPath:indexPath];
			cell.user = self.user;
            return cell;
        }
        
        NSUInteger row = indexPath.row;
        
        ORVideoCell *cell = [tableView dequeueReusableCellWithIdentifier:videoCell forIndexPath:indexPath];
        cell.video = self.filteredVideos[row];
        cell.parent = self;
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.section > 0 && self.videos.count > 0) {
        OREpicVideo *video = self.filteredVideos[indexPath.row];
        
        if (video.state == OREpicVideoStateExpired) {
            if ([video.userId isEqualToString:CurrentUser.userId]) {
                if (CurrentUser.subscriptionLevel > 0) {
                    ORVideoManagerView *vc = [[ORVideoManagerView alloc] initWithVideo:video andPlaces:nil];
                    [self.navigationController pushViewController:vc animated:YES];
                } else {
                    ORExpiredVideoUpsell *vc = [ORExpiredVideoUpsell new];
                    [self presentViewController:vc animated:YES completion:nil];
                }
            }
        } else {
            ORWatchView *watch = [[ORWatchView alloc] initWithVideo:video];
            [self.navigationController pushViewController:watch animated:YES];
        }
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (!ORIsEmpty(searchText)) {
        self.filteredVideos = [NSMutableOrderedSet orderedSetWithCapacity:10];
        for (OREpicVideo *video in self.videos) {
            NSUInteger result = [video.autoTitle rangeOfString:searchText options:NSCaseInsensitiveSearch].location;
    
            if (result != NSNotFound) {
                [self.filteredVideos addObject:video];
            }
        }
        
        if (self.currentTab == 1) [self.orderCell updateVideoCount:self.filteredVideos.count];
    } else {
        self.filteredVideos = self.videos;
        if (self.currentTab == 1) [self.orderCell updateVideoCount:-1];
    }
    
    NSIndexSet *is = [NSIndexSet indexSetWithIndex:1];
    [self.tableView reloadSections:is withRowAnimation:UITableViewRowAnimationNone];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.filteredVideos = self.videos;
    if (self.currentTab == 1) [self.orderCell updateVideoCount:-1];

    NSIndexSet *is = [NSIndexSet indexSetWithIndex:1];
    [self.tableView reloadSections:is withRowAnimation:UITableViewRowAnimationNone];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.view endEditing:YES];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    
    if (alertView.tag == 1) { // Follow user
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            [self.userCell btnFollow_TouchUpInside:nil];
        }
    } else if (alertView.tag == 2) { // Subscription Expired
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            ORSubscriptionUpsell *vc = [ORSubscriptionUpsell new];
            [self presentViewController:vc animated:YES completion:nil];
        }
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    actionSheet.delegate = nil;
    
    if (actionSheet.tag == 1) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [self signOut];
        } else if (buttonIndex == 1) {
			[RVC presentSignInWithMessage:@"Sign-in for settings" completion:^(BOOL success) {
			}];
		}
    }
}

#pragma mark - Tab Buttons

- (void)configureTabButtons
{
//    if ([self.user.userId isEqualToString:CurrentUser.userId]) {
//        self.btnFavs.hidden = NO;
//        self.btnNetwork.hidden = NO;
//
//        CGRect f = self.btnProfile.frame;
//        f.size.width = (self.viewTab.frame.size.width - 20.0f) / 4;
//        self.btnProfile.frame = f;
//        
//        f.origin.x += f.size.width + 4.0f;
//        self.btnVideos.frame = f;
//
//        f.origin.x += f.size.width + 4.0f;
//        self.btnFavs.frame = f;
//
//        f.origin.x += f.size.width + 4.0f;
//        self.btnNetwork.frame = f;
//    } else {
//        self.btnFavs.hidden = YES;
//        self.btnNetwork.hidden = YES;
//
//        CGRect f = self.btnProfile.frame;
//        f.size.width = (self.viewTab.frame.size.width - 12.0f) / 2;
//        self.btnProfile.frame = f;
//        
//        f.origin.x += f.size.width + 4.0f;
//        self.btnVideos.frame = f;
//    }
//    
//    [self setIndicatorToButton:self.btnProfile];
}

- (void)btnProfile_TouchUpInside:(id)sender
{
	self.tableView.hidden = NO;
    self.viewPeopleHost.hidden = YES;

    self.currentTab = 0;
    self.changedTabs = YES;
    self.btnVideos.selected = NO;
    self.btnFavs.selected = NO;
    self.btnNetwork.selected = NO;
	[self setIndicatorToButton:sender];
    
    self.tableView.tableHeaderView = nil;
    [self reloadUserVideosForceReload:NO];
}

- (void)btnVideos_TouchUpInside:(id)sender
{
	self.tableView.hidden = NO;
    self.viewPeopleHost.hidden = YES;

    self.currentTab = 1;
    self.changedTabs = YES;
    self.btnProfile.selected = NO;
    self.btnFavs.selected = NO;
    self.btnNetwork.selected = NO;
	[self setIndicatorToButton:sender];
    
    self.tableView.tableHeaderView = self.searchBar;
    
    if (self.isLoadingVideos) {
        [self.refresh beginRefreshing];
        [self.tableView setContentOffset:CGPointMake(0, -self.refresh.frame.size.height) animated:YES];
    }
    
    [self reloadUserVideosForceReload:NO];
}

- (void)btnFavs_TouchUpInside:(id)sender
{
	self.tableView.hidden = NO;
    self.viewPeopleHost.hidden = YES;

    self.currentTab = 2;
    self.changedTabs = YES;
    self.btnProfile.selected = NO;
    self.btnVideos.selected = NO;
    self.btnNetwork.selected = NO;
	[self setIndicatorToButton:sender];
    
    self.tableView.tableHeaderView = self.searchBar;
    [self reloadLikedVideosForceReload:NO];
}

- (void)btnNetwork_TouchUpInside:(id)sender
{
	self.tableView.hidden = YES;
    self.viewPeopleHost.hidden = NO;
	
	self.currentTab = 2;
    self.changedTabs = YES;
    self.btnProfile.selected = NO;
    self.btnVideos.selected = NO;
    self.btnNetwork.selected = YES;
	[self setIndicatorToButton:sender];
  
//	self.tableView.tableHeaderView = nil;
//    self.tableView.tableHeaderView = self.searchBar;
//    [self reloadLikedVideosForceReload:NO];

}

- (void)setIndicatorToButton:(UIButton*)btn
{
	[UIView animateWithDuration:0.2f
						  delay:0.0f
						options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 CGRect f = self.viewIndicator.frame;
						 f.origin.x	= btn.frame.origin.x;
						 f.size.width = btn.frame.size.width;
						 self.viewIndicator.frame = f;
					 } completion:^(BOOL finished) {
						 btn.selected = YES;
					 }];
}

#pragma mark - Custom Methods

- (void)doneAction
{
	[self.view endEditing:YES];
    
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [RVC showCamera];
    }
}

- (void)refreshProfile
{
    if ([self.user.userId isEqualToString:CurrentUser.userId]) {
        self.user = CurrentUser.asFriend;
        [self.tableView reloadData];
    }
}

- (void)presentUserSettings
{
    if (CurrentUser.accountType == 3) {
        self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:@"DELETE TRIAL ACCOUNT"
                                              otherButtonTitles:@"Sign in", nil];
        self.actionSheet.tag = 1;
        [self.actionSheet showInView:self.view];
    } else {
		ORUserSettingsView *vc = [ORUserSettingsView new];
		[self.navigationController pushViewController:vc animated:YES];
	}
}

- (void)refreshAction
{
    if (self.currentTab == 2) {
        [self reloadLikedVideosForceReload:YES];
    } else {
        [self reloadUserVideosForceReload:YES];
    }
}

- (void)reloadUserVideosIfNeeded
{
    if (self.currentTab != 2) [self reloadUserVideosForceReload:NO];
}

- (void)reloadUserVideosForceReload:(BOOL)forceReload
{
    if (self.isLoadingVideos) return;
    if (ORIsEmpty(self.user.userId)) return;
    
    __weak ORUserProfileView *weakSelf = self;
    self.isLoadingVideos = YES;
    self.videos = self.cachedVideos;
    self.filteredVideos = self.videos;
    self.searchBar.text = nil;
    
    self.changedTabs = NO;
    [self.tableView reloadData];
    
    if (self.currentTab == 1) {
        [self.refresh beginRefreshing];
        if (forceReload) [self.tableView setContentOffset:CGPointMake(0, -self.refresh.frame.size.height) animated:YES];
    }
    
    if ([self.user.userId isEqualToString:CurrentUser.userId]) {
        [[ORDataController sharedInstance] userVideosForceReload:forceReload cacheOnly:NO completion:^(NSError *error, BOOL final, NSArray *feed) {
            if (error) NSLog(@"Error: %@", error);
            
            if (feed) {
                weakSelf.videos = [NSMutableOrderedSet orderedSetWithArray:feed];
                
                NSArray *pending = [[ORFaspPersistentEngine sharedInstance] allPendingVideos];
                for (OREpicVideo *video in pending) {
                    [weakSelf.videos removeObject:video];
                    [weakSelf.videos insertObject:video atIndex:0];
                }
            }

            if (final) {
                weakSelf.isLoadingVideos = NO;
                [weakSelf.refresh endRefreshing];
                
                if (!self.tableView.tableHeaderView) {
                    [weakSelf.tableView setContentOffset:CGPointMake(0, 0) animated:!self.changedTabs];
                } else {
                    [weakSelf.tableView setContentOffset:CGPointMake(0, 44.0f) animated:!self.changedTabs];
                }
            }
            
            [weakSelf refreshVideoList];
        }];
    } else {
        if (self.cachedVideos && !forceReload) {
            self.videos = self.cachedVideos;
            self.isLoadingVideos = NO;
            [self refreshVideoList];
            [self.refresh endRefreshing];
            
            if (self.currentTab == 0) {
                [self.tableView setContentOffset:CGPointMake(0, 0) animated:!self.changedTabs];
            } else {
                [self.tableView setContentOffset:CGPointMake(0, 44.0f) animated:!self.changedTabs];
            }
        } else {
            [ApiEngine videosForUser:self.user.userId completion:^(NSError *error, NSArray *result) {
                if (error) NSLog(@"Error: %@", error);
                
                if (result) {
                    weakSelf.videos = [NSMutableOrderedSet orderedSetWithArray:result];
                    weakSelf.cachedVideos = weakSelf.videos;
                }
                
                weakSelf.isLoadingVideos = NO;
                [weakSelf refreshVideoList];
                [weakSelf.refresh endRefreshing];

                if (weakSelf.currentTab == 0) {
                    [weakSelf.tableView setContentOffset:CGPointMake(0, 0) animated:!self.changedTabs];
                } else {
                    [weakSelf.tableView setContentOffset:CGPointMake(0, 44.0f) animated:!self.changedTabs];
                }
            }];
        }
    }
}

- (void)reloadLikedVideosIfNeeded
{
    if (self.currentTab == 2) [self reloadLikedVideosForceReload:NO];
}

- (void)reloadLikedVideosForceReload:(BOOL)forceReload
{
    if (self.isLoadingVideos) return;
    
    __weak ORUserProfileView *weakSelf = self;
    self.isLoadingVideos = YES;
    self.videos = self.cachedVideos;
    self.filteredVideos = self.videos;
    self.searchBar.text = nil;
    
    self.changedTabs = NO;
    [self.tableView reloadData];
    [self.refresh beginRefreshing];
    if (forceReload) [self.tableView setContentOffset:CGPointMake(0, -self.refresh.frame.size.height) animated:YES];
    
    if (self.cachedVideos && !forceReload) {
        self.videos = self.cachedVideos;
        self.isLoadingVideos = NO;
        [self refreshVideoList];
        [self.refresh endRefreshing];
        [self.tableView setContentOffset:CGPointMake(0, 44.0f) animated:!self.changedTabs];
    } else {
        [ApiEngine likedVideosForUser:self.user.userId completion:^(NSError *error, NSArray *result) {
            if (error) NSLog(@"Error: %@", error);
            
            if (result) {
                weakSelf.videos = [NSMutableOrderedSet orderedSetWithArray:result];
                weakSelf.cachedVideos = weakSelf.videos;
            }
            
            weakSelf.isLoadingVideos = NO;
            [weakSelf refreshVideoList];
            [weakSelf.refresh endRefreshing];
            [weakSelf.tableView setContentOffset:CGPointMake(0, 44.0f) animated:!self.changedTabs];
        }];
    }
}

- (void)refreshVideoList
{
    if (self.currentTab == 1) {
        if (self.orderCell.btnOrderBy_Recency.selected) {
            [self sortVideosByDate];
        } else if (self.orderCell.btnOrderBy_Views.selected) {
            [self sortVideosByViews];
        } else if (self.orderCell.btnOrderBy_Likes.selected) {
            [self sortVideosByComments];
        } else if (self.orderCell.btnOrderBy_Reposts.selected) {
            [self sortVideosByReposts];
        }
    }

	if (!self.shouldLoadVideos && self.videos) [self.userCell loadMapButtonForVideos:[self.videos array]];

    if ([self.user.userId isEqualToString:CurrentUser.userId] && self.videos.count > CurrentUser.totalVideoCount) {
        CurrentUser.totalVideoCount = self.videos.count;
        [CurrentUser saveLocalUser];
    }
    
    self.filteredVideos = self.videos;
    [self.tableView reloadData];
}

- (void)reorderVideos
{
    if (self.currentTab == 1) {
        if (self.orderCell.btnOrderBy_Recency.selected) {
            [self sortVideosByDate];
        } else if (self.orderCell.btnOrderBy_Views.selected) {
            [self sortVideosByViews];
        } else if (self.orderCell.btnOrderBy_Likes.selected) {
            [self sortVideosByComments];
        } else if (self.orderCell.btnOrderBy_Reposts.selected) {
            [self sortVideosByReposts];
        }
    }

    self.filteredVideos = self.videos;
    NSIndexSet *is = [NSIndexSet indexSetWithIndex:1];
    [self.tableView reloadSections:is withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)sortVideosByDate
{
    [self.videos sortUsingComparator:^NSComparisonResult(OREpicVideo *v1, OREpicVideo *v2) {
        return [v2.startTime compare:v1.startTime];
    }];
}

- (void)sortVideosByViews
{
    [self.videos sortUsingComparator:^NSComparisonResult(OREpicVideo *v1, OREpicVideo *v2) {
        if (v1.viewCount > v2.viewCount) {
            return NSOrderedAscending;
        } else if (v1.viewCount < v2.viewCount) {
            return NSOrderedDescending;
        } else {
            return [v2.startTime compare:v1.startTime];
        }
    }];
}

- (void)sortVideosByComments
{
    [self.videos sortUsingComparator:^NSComparisonResult(OREpicVideo *v1, OREpicVideo *v2) {
        if (v1.likeCount > v2.likeCount) {
            return NSOrderedAscending;
        } else if (v1.commentCount < v2.commentCount) {
            return NSOrderedDescending;
        } else {
            return [v2.startTime compare:v1.startTime];
        }
    }];
}

- (void)sortVideosByLikes
{
    [self.videos sortUsingComparator:^NSComparisonResult(OREpicVideo *v1, OREpicVideo *v2) {
        if (v1.likeCount > v2.likeCount) {
            return NSOrderedAscending;
        } else if (v1.likeCount < v2.likeCount) {
            return NSOrderedDescending;
        } else {
            return [v2.startTime compare:v1.startTime];
        }
    }];
}

- (void)sortVideosByReposts
{
    [self.videos sortUsingComparator:^NSComparisonResult(OREpicVideo *v1, OREpicVideo *v2) {
        if (v1.repostCount > v2.repostCount) {
            return NSOrderedAscending;
        } else if (v1.repostCount < v2.repostCount) {
            return NSOrderedDescending;
        } else {
            return [v2.startTime compare:v1.startTime];
        }
    }];
}

- (void)openUserMap
{
	ORMapView *vc = [[ORMapView alloc] initWithVideos:[self.videos array]];
	[self.navigationController pushViewController:vc animated:YES];
	vc.title = [NSString stringWithFormat:@"%@", self.user.firstName];
}

- (void)signOut
{
    if (CurrentUser.accountType == 3 && CurrentUser.totalVideoCount > 0) {
        [RVC presentSignInWithMessage:NSLocalizedStringFromTable(@"SignOutAccType3", @"UserSettings", @"Do you want to keep the videos you shot? You'll need a way to sign back in...") cancelTitle:NSLocalizedStringFromTable(@"SignOut", @"UserSettings", @"Sign out and delete videos") completion:^(BOOL success) {
            if (!success) {
                [self deleteAccount];
            }
        }];
        
        return;
    } else if (CurrentUser.accountType == 3) {
        [self deleteAccount];
    } else {
        [self performSignOut];
    }
}

- (void)performSignOut
{
    [[ORFaspPersistentEngine sharedInstance] cancelAllUploads];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORPausePlayerHARD" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORUserWillSignOut" object:nil];
    [self.navigationController popToRootViewControllerAnimated:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORUserSignedOut" object:nil];
}

- (void)deleteAccount
{
    self.view.userInteractionEnabled = NO;
    
    [[ORFaspPersistentEngine sharedInstance] cancelAllUploads];
    NSString *userId = CurrentUser.userId;
    
    [ApiEngine deleteUserById:userId cb:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
        if (PUSH_ENABLED) [ApiEngine updateDeviceId:nil forUser:userId cb:nil];
        [self performSignOut];
    }];
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
    self.tapGesture.cancelsTouchesInView = NO;
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
