//
//  ORUserProfileCell.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 16/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORUserProfileCell.h"
#import "ORPushNotificationPermissionView.h"
#import "ORFollowersFollowingListView.h"
#import "ORUserProfileView.h"
#import "ORUserListView.h"
#import "ORAvatarView.h"
#import "ORMapView.h"
#import "ORPopDownView.h"

@interface ORUserProfileCell () <UIActionSheetDelegate>

@property (nonatomic, assign) BOOL hasMap;
@property (nonatomic, assign) BOOL isUpdating;
@property (nonatomic, assign) int videoCount;
@property (nonatomic, assign) CLLocationDegrees latitude;
@property (nonatomic, assign) CLLocationDegrees longitude;
@property (nonatomic, strong) UIActionSheet *actionSheet;

@end

@implementation ORUserProfileCell

- (void)dealloc
{
    self.actionSheet.delegate = nil;
}

- (void)awakeFromNib
{
    self.videoCount = -1;
	self.aiFollowers.color = APP_COLOR_PRIMARY;
	self.aiFollowing.color = APP_COLOR_PRIMARY;
    self.aiMap.color = APP_COLOR_PRIMARY;
    self.aiUpdating.color = APP_COLOR_PRIMARY;
    
    self.btnFollow.layer.cornerRadius = 5.0f;
    self.btnApprove.layer.cornerRadius = 5.0f;
    self.btnDeny.layer.cornerRadius = 5.0f;
    
    self.btnApprove.backgroundColor = APP_COLOR_PURPLE;
    self.btnDeny.backgroundColor = [UIColor lightGrayColor];
}

- (void)setUser:(OREpicFriend *)user
{
    BOOL userChanged = NO;
    
    if (![user isEqual:_user]) {
        userChanged = YES;
        self.hasMap = NO;
    }
    
    _user = user;
    
    self.imgMap.hidden = YES;
    self.btnMap.hidden = YES;
    self.btnFollow.hidden = YES;
    self.btnApprove.hidden = YES;
    self.btnDeny.hidden = YES;
    self.lblBlocked.hidden = YES;
    
    if ([CurrentUser.userId isEqualToString:user.userId]) {
		self.lblVideoCount.text = [NSString localizedStringWithFormat:@"%d", CurrentUser.totalVideoCount];
        [self setFollowButtonState];
	} else {
		self.lblVideoCount.text = [NSString localizedStringWithFormat:@"%d", user.videoCount];
        
        if (userChanged) {
            self.isUpdating = YES;
            [self.aiUpdating startAnimating];
            
            __weak ORUserProfileCell *weakSelf = self;
            
            [ApiEngine friendWithId:user.userId completion:^(NSError *error, OREpicFriend *epicFriend) {
                weakSelf.isUpdating = NO;
                if (error) NSLog(@"Error: %@", error);
                
                if (epicFriend) {
                    weakSelf.user.isFollowing = epicFriend.isFollowing;
                    weakSelf.user.isFollower = epicFriend.isFollower;
                    weakSelf.user.isRequested = epicFriend.isRequested;
                    weakSelf.user.isPendingFollow = epicFriend.isPendingFollow;
                    weakSelf.user.isBlocked = epicFriend.isBlocked;
                    
                    [weakSelf setFollowButtonState];
                }
            }];
        } else {
            if (!self.isUpdating) [self setFollowButtonState];
        }
    }
	
    self.lblViewCount.text = [NSString localizedStringWithFormat:@"%d", user.viewCount];
    self.lblLikeCount.text = [NSString localizedStringWithFormat:@"%d", user.likeCount];
    self.lblRepostCount.text = [NSString localizedStringWithFormat:@"%d", user.repostCount];
	if (user.bio) {
		self.txtBio.text = user.bio;
	} else {
		self.txtBio.text = @"no bio"; //NSLocalizedStringFromTable(@"ImUsingVeezy", @"UserProfile", @"Hi, I'm using Veezy");
	}
    
	self.lblName.text = user.name;
    
	self.lblFollowing.text = [NSString localizedStringWithFormat:@"%d", user.followingCount];
	self.lblFollowers.text = [NSString localizedStringWithFormat:@"%d", user.followersCount];
	
	self.imgAvatar.layer.cornerRadius = self.imgAvatar.frame.size.height / 2;
	
	// AVATAR
	if (user.profileImageUrl) {
		__weak OREpicFriend *weakUser = user;
		__weak ORUserProfileCell *weakSelf = self;
        
		[[ORCachedEngine sharedInstance] imageAtURL:[NSURL URLWithString:user.profileImageUrl] maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
			if (error) NSLog(@"Error: %@", error);
			if (image && weakSelf.user == weakUser) {
				weakSelf.imgAvatar.image = image;
			}
		}];
    }
}

- (void)setFollowButtonState
{
    [self.aiUpdating stopAnimating];
    
    if ([CurrentUser.userId isEqualToString:self.user.userId]) {
        [self.btnFollow setTitle:NSLocalizedStringFromTable(@"EditProfile", @"UserProfile", @"Profile view edit button, when viewed profile is self") forState:UIControlStateNormal];
        self.btnFollow.hidden = NO;
        self.btnFollow.selected = NO;
        self.btnFollow.backgroundColor = APP_COLOR_PURPLE;
        self.imgMap.hidden = NO;
        self.btnMap.hidden = NO;
    } else {
        UIBarButtonItem *sprocket = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"dots-icon-circle-black-40x"] style:UIBarButtonItemStylePlain target:self action:@selector(presentUserActions)];
        self.parent.navigationItem.rightBarButtonItem = sprocket;
        
        if (self.user.isBlocked) {
            self.lblBlocked.hidden = NO;
        } else if (self.user.isPendingFollow) {
            self.btnApprove.hidden = NO;
            self.btnDeny.hidden = NO;
        } else if (self.user.isFollowing) {
            [self.btnFollow setTitle:NSLocalizedStringFromTable(@"FollowingProfile", @"UserProfile", @"Profile view of already followed profile") forState:UIControlStateNormal];
            self.btnFollow.hidden = NO;
            self.btnFollow.selected = YES;
            self.btnFollow.backgroundColor = [UIColor lightGrayColor];
            self.imgMap.hidden = NO;
            self.btnMap.hidden = NO;
        } else {
            if (self.user.isPrivate) {
                if (self.user.isRequested) {
                    [self.btnFollow setTitle:NSLocalizedStringFromTable(@"FollowRequested", @"UserProfile", @"Requested to follow") forState:UIControlStateNormal];
                    self.btnFollow.hidden = NO;
                    self.btnFollow.selected = YES;
                    self.btnFollow.backgroundColor = [UIColor lightGrayColor];
                } else {
                    [self.btnFollow setTitle:NSLocalizedStringFromTable(@"FollowRequest", @"UserProfile", @"Request to follow") forState:UIControlStateNormal];
                    self.btnFollow.hidden = NO;
                    self.btnFollow.selected = NO;
                    self.btnFollow.backgroundColor = APP_COLOR_PURPLE;
                }
            } else {
                [self.btnFollow setTitle:NSLocalizedStringFromTable(@"FollowProfile", @"UserProfile", @"Profile view of not followed profile") forState:UIControlStateNormal];
                self.imgMap.hidden = NO;
                self.btnMap.hidden = NO;
                self.btnFollow.hidden = NO;
                self.btnFollow.selected = NO;
                self.btnFollow.backgroundColor = APP_COLOR_PURPLE;
            }
        }
    }
}

- (void)loadMapButtonForVideos:(NSArray *)videos
{
    if (self.hasMap) return;
    if (self.user.isPrivate && !self.user.isFollowing && ![self.user.userId isEqualToString:CurrentUser.userId]) return;
    
    self.btnMap.enabled = NO;
    [self.aiMap startAnimating];
	
	NSMutableArray *lls = [NSMutableArray new];
	for (int i = 0; i < MIN(10, videos.count); i++)
	{
		OREpicVideo *v = videos[i];
		if (v.latitude != 0 || v.longitude != 0) {
			[lls addObject:[[CLLocation alloc] initWithLatitude:v.latitude longitude:v.longitude]];
		}
	}
	
	NSString *gms = [GoogleEngine staticMapImageUrlLatlongs:lls width:self.imgMap.frame.size.width height:self.imgMap.frame.size.height adjustMapForMarkerBy:0.0015];
	
    __weak ORUserProfileCell *weakSelf = self;
    
	NSURL *url = [NSURL URLWithString:gms];
	
	[[ORCachedEngine sharedInstance] imageAtURL:url completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
		if (error) {
			NSLog(@"Error: %@", error);
		} else {
			[weakSelf.btnMap setImage:image forState:UIControlStateNormal];
			weakSelf.imgMap.image = image;
            weakSelf.hasMap = YES;
		}
        
        weakSelf.btnMap.enabled = YES;
        [weakSelf.aiMap stopAnimating];
	}];
}

- (IBAction)btnFollow_TouchUpInside:(id)sender
{
	if (![CurrentUser.userId isEqualToString:self.user.userId]) {
        if (CurrentUser.accountType == 3) {
            [RVC presentSignInWithMessage:NSLocalizedStringFromTable(@"SignInToFollowMessage", @"UserProfile", @"Sign-in message for anonymous") completion:^(BOOL success) {
            }];
            
            return;
        }
        
        self.btnFollow.hidden = YES;
        self.btnApprove.hidden = YES;
        self.btnDeny.hidden = YES;
        self.lblBlocked.hidden = YES;
        [self.aiUpdating startAnimating];

		if (self.user.isFollowing) {
            __weak ORUserProfileCell *weakSelf = self;
            [ApiEngine unfollowUser:self.user.userId completion:^(NSError *error, BOOL result) {
                if (error) NSLog(@"Error: %@", error);
                
                if (result && weakSelf.user) {
                    weakSelf.user.isFollowing = NO;
                    [CurrentUser setFollowing:NO forFriend:weakSelf.user];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORFollowingUpdated" object:nil];
                    [self setFollowButtonState];
                }
            }];
        } else if (self.user.isPrivate && self.user.isRequested) {
            // TODO: CANCEL FOLLOW REQUEST
            [self setFollowButtonState];
		} else {
            __weak ORUserProfileCell *weakSelf = self;
            [ApiEngine followUser:self.user.userId completion:^(NSError *error, BOOL result) {
                if (error) NSLog(@"Error: %@", error);
                
                if (result && weakSelf.user) {
                    weakSelf.user.isFollowing = YES;
                    [CurrentUser setFollowing:YES forFriend:weakSelf.user];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORFollowingUpdated" object:nil];
                
                    if (!AppDelegate.pushNotificationsEnabled && result && weakSelf.user) {
                        ORPushNotificationPermissionView *pnpv = [[ORPushNotificationPermissionView alloc] initWithFriend:weakSelf.user];
                        [weakSelf.parent presentViewController:pnpv animated:YES completion:nil];
                    }
                } else if (!result && !error) {
                    weakSelf.user.isRequested = YES;
                }
                
                [weakSelf setFollowButtonState];
            }];
		}
	} else {
        [self.parent presentUserSettings];
	}
}

- (IBAction)btnFollowers_TouchUpInside:(id)sender
{
    if (CurrentUser.accountType == 3 && [self.user.userId isEqualToString:CurrentUser.userId]) {
        [RVC presentSignInWithMessage:@"Sign-in to connect with friends!" completion:^(BOOL success) {
            if (success) {
                if (![self.user.userId isEqualToString:CurrentUser.userId]) {
                    self.user = CurrentUser.asFriend;
                    self.parent.user = self.user;
                }
            }
        }];
        
        return;
    }
    
    __weak ORUserProfileCell *weakSelf = self;
    self.btnFollowers.hidden = YES;
    self.lblFollowers.hidden = YES;
    [self.aiFollowers startAnimating];
    
    if ([self.user.userId isEqualToString:CurrentUser.userId]) {
        [CurrentUser reloadFollowersForceReload:YES completion:^(NSError *error) {
            if (error) NSLog(@"Error: %@", error);
            
            if (CurrentUser.isPrivate) {
                [ApiEngine followRequestsForUser:CurrentUser.userId completion:^(NSError *error, NSArray *result) {
                    if (error) NSLog(@"Error: %@", error);

                    ORUserListView *vc = [[ORUserListView alloc] initWithUsers:[CurrentUser.followers array] andFollowRequests:result];
                    vc.isFollowersList = YES;
                    vc.title = NSLocalizedStringFromTable(@"FollowersForProfile", @"UserProfile", @"List view of the followers for the current profile");
                    [weakSelf.parent.navigationController pushViewController:vc animated:YES];
                    [weakSelf.aiFollowers stopAnimating];
                    weakSelf.btnFollowers.hidden = NO;
                    weakSelf.lblFollowers.hidden = NO;
                }];
            } else {
                ORUserListView *vc = [[ORUserListView alloc] initWithUsers:[CurrentUser.followers array]];
                vc.isFollowersList = YES;
                vc.title = NSLocalizedStringFromTable(@"FollowersForProfile", @"UserProfile", @"List view of the followers for the current profile");
                [weakSelf.parent.navigationController pushViewController:vc animated:YES];
                [weakSelf.aiFollowers stopAnimating];
                weakSelf.btnFollowers.hidden = NO;
                weakSelf.lblFollowers.hidden = NO;
            }
        }];
    } else {
        [ApiEngine followersForUser:self.user.userId completion:^(NSError *error, NSArray *result) {
            if (error) NSLog(@"Error: %@", error);
            
            ORUserListView *vc = [[ORUserListView alloc] initWithUsers:result];
            vc.title = NSLocalizedStringFromTable(@"FollowersForProfile", @"UserProfile", @"List view of the followers for the current profile");
            [weakSelf.parent.navigationController pushViewController:vc animated:YES];
            [weakSelf.aiFollowers stopAnimating];
            weakSelf.btnFollowers.hidden = NO;
            weakSelf.lblFollowers.hidden = NO;
        }];
    }
}

- (IBAction)btnFollowing_TouchUpInsie:(id)sender
{
    if (CurrentUser.accountType == 3 && [self.user.userId isEqualToString:CurrentUser.userId]) {
        [RVC presentSignInWithMessage:@"Sign-in to connect with friends!" completion:^(BOOL success) {
            if (success) {
                if (![self.user.userId isEqualToString:CurrentUser.userId]) {
                    self.user = CurrentUser.asFriend;
                    self.parent.user = self.user;
                }
            }
        }];
        
        return;
    }

    __weak ORUserProfileCell *weakSelf = self;
    self.btnFollowing.hidden = YES;
    self.lblFollowing.hidden = YES;
    [self.aiFollowing startAnimating];
    
    if ([self.user.userId isEqualToString:CurrentUser.userId]) {
        [CurrentUser reloadFollowingForceReload:YES completion:^(NSError *error) {
            if (error) NSLog(@"Error: %@", error);
            
            ORUserListView *vc = [[ORUserListView alloc] initWithUsers:[CurrentUser.following array]];
            vc.isFollowingList = YES;
            vc.title = NSLocalizedStringFromTable(@"FollowingViewTitle", @"UserProfile", @"Title for the following view in Profile");
            [weakSelf.parent.navigationController pushViewController:vc animated:YES];
            [weakSelf.aiFollowing stopAnimating];
            weakSelf.btnFollowing.hidden = NO;
            weakSelf.lblFollowing.hidden = NO;
        }];
    } else {
        [ApiEngine followingUsersFor:self.user.userId completion:^(NSError *error, NSArray *result) {
            if (error) NSLog(@"Error: %@", error);
            
            ORUserListView *vc = [[ORUserListView alloc] initWithUsers:result];
            vc.title = NSLocalizedStringFromTable(@"FollowingViewTitle", @"UserProfile", @"Title for the following view in Profile");
            [weakSelf.parent.navigationController pushViewController:vc animated:YES];
            [weakSelf.aiFollowing stopAnimating];
            weakSelf.btnFollowing.hidden = NO;
            weakSelf.lblFollowing.hidden = NO;
        }];
    }
}

- (IBAction)btnMap_TouchUpInside:(id)sender
{
    [self.parent openUserMap];
}

- (IBAction)btnAvatar_TouchUpInside:(id)sender
{
	ORAvatarView *vc = [[ORAvatarView alloc] initWithImage:self.imgAvatar.image andTitle:self.parent.title];
	[self.parent.navigationController pushViewController:vc animated:YES];
}

- (void)btnVideos_TouchUpInside:(id)sender
{
    [self.parent btnVideos_TouchUpInside:self.parent.btnVideos];
}

- (void)btnApprove_TouchUpInside:(id)sender
{
    self.btnFollow.hidden = YES;
    self.btnApprove.hidden = YES;
    self.btnDeny.hidden = YES;
    self.lblBlocked.hidden = YES;
    [self.aiUpdating startAnimating];
    
    __weak ORUserProfileCell *weakSelf = self;
    
    [ApiEngine approveFollowForUser:self.user.userId completion:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
        
        if (result && weakSelf.user) {
            weakSelf.user.isPendingFollow = NO;
            weakSelf.user.isFollower = YES;
            [CurrentUser setFollower:YES forFriend:weakSelf.user];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORFollowersUpdated" object:weakSelf.user];
        [weakSelf setFollowButtonState];
    }];
}

- (void)btnDeny_TouchUpInside:(id)sender
{
    self.btnFollow.hidden = YES;
    self.btnApprove.hidden = YES;
    self.btnDeny.hidden = YES;
    self.lblBlocked.hidden = YES;
    [self.aiUpdating startAnimating];
    
    __weak ORUserProfileCell *weakSelf = self;
    
    [ApiEngine rejectFollowForUser:self.user.userId completion:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
        
        if (result && weakSelf.user) {
            weakSelf.user.isPendingFollow = NO;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORFollowersUpdated" object:weakSelf.user];
        [weakSelf setFollowButtonState];
    }];
}

- (void)presentUserActions
{
    NSString *blockTitle = (self.user.isBlocked) ? @"Unblock" : @"Block";
    
    self.actionSheet.delegate = nil;
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                     destructiveButtonTitle:blockTitle
                                          otherButtonTitles:nil];
    self.actionSheet.tag = 1;
    [self.actionSheet showInView:self.parent.view];
}

- (void)blockUnblockUser
{
    self.btnFollow.hidden = YES;
    self.btnApprove.hidden = YES;
    self.btnDeny.hidden = YES;
    self.lblBlocked.hidden = YES;
    [self.aiUpdating startAnimating];
    
    __weak ORUserProfileCell *weakSelf = self;

    if (self.user.isBlocked) {
        [ApiEngine unblockUser:self.user.userId completion:^(NSError *error, BOOL result) {
            if (error) NSLog(@"Error: %@", error);
            
            if (result && weakSelf.parent) {
                weakSelf.user.isBlocked = NO;
            }

            [weakSelf setFollowButtonState];
        }];
    } else {
        [ApiEngine blockUser:self.user.userId completion:^(NSError *error, BOOL result) {
            if (error) NSLog(@"Error: %@", error);

            if (result && weakSelf.parent) {
                weakSelf.user.isBlocked = YES;
                weakSelf.user.isFollower = NO;
                [CurrentUser setFollower:NO forFriend:weakSelf.user];
            }

            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORFollowersUpdated" object:weakSelf.user];
            [weakSelf setFollowButtonState];
        }];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    actionSheet.delegate = nil;
    
    if (actionSheet.tag == 1) { // User Actions
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [self blockUnblockUser];
        }
    }
}

@end
