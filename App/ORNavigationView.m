//
//  ORNavigationView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 17/09/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORNavigationView.h"
#import "ORCaptureView.h"
#import "ORUserFeedView.h"
#import "ORUserProfileView.h"
#import "ORActivityView.h"
#import "ORMapView.h"
#import "ORGoProEngine.h"
#import "ORTwitterTrend.h"

@interface ORNavigationView ()

@end

@implementation ORNavigationView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.lblBadge.layer.cornerRadius = 7.0f;
    self.lblActivityBadge.layer.cornerRadius = 7.0f;
	self.viewGoProHost.layer.cornerRadius = 7.0f;

    self.lblBadge.alpha = 0.85f;
    self.lblActivityBadge.alpha = 0.85f;
	
	self.viewMainNav.backgroundColor = APP_COLOR_PRIMARY_ALPHA(0.9f);
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[self goProCheck];
}

#pragma mark - UI

- (IBAction)btnHome_TouchUpInside:(id)sender
{
	[self hideOverlays];
    ORUserFeedView *vc = [ORUserFeedView new];
    self.view.userInteractionEnabled = NO;
    __weak ORNavigationView *weakSelf = self;
    
    [RVC resetMainViewWith:vc completion:^{
        weakSelf.view.userInteractionEnabled = YES;
    }];
}

- (IBAction)btnMe_TouchUpInside:(id)sender
{
	[self hideOverlays];
	ORUserProfileView *vc = [[ORUserProfileView alloc] initWithFriend:CurrentUser.asFriend];
    self.view.userInteractionEnabled = NO;
    __weak ORNavigationView *weakSelf = self;
    
	[RVC resetMainViewWith:vc completion:^{
        weakSelf.view.userInteractionEnabled = YES;
    }];
}

- (IBAction)btnActivity_TouchUpInside:(id)sender
{
	[self hideOverlays];
	if (CurrentUser.accountType == 3) {
        [RVC presentSignInWithMessage:@"Sign-in to get notifications!" completion:^(BOOL success) {
        }];
    } else {
		ORActivityView *vc = [ORActivityView new];
		self.view.userInteractionEnabled = NO;
		__weak ORNavigationView *weakSelf = self;
		
		[RVC resetMainViewWith:vc completion:^{
			weakSelf.view.userInteractionEnabled = YES;
		}];
    }
}

- (IBAction)btnDiscover_TouchUpInside:(id)sender
{
	[self hideOverlays];
	ORMapView *vc = [[ORMapView alloc] initForDiscovery];
    self.view.userInteractionEnabled = NO;
    __weak ORNavigationView *weakSelf = self;
    
	[RVC resetMainViewWith:vc completion:^{
        weakSelf.view.userInteractionEnabled = YES;
    }];
}

- (IBAction)btnCamera_TouchUpInside:(id)sender
{
	[self hideOverlays];
	[self goProCheck];
	if (RVC.currentState == ORUIStateCamera) {
		[RVC.captureView showRotateAlert];
    } else {
        [RVC showCamera];
    }
}

- (IBAction)btnAdd_TouchUpInside:(id)sender
{
    [AppDelegate.mixpanel track:@"BTN - Cloudcamify Videos" properties:nil];
    [RVC showCamera];
	[RVC.captureView presentCameraRollSelectorView];
}

- (IBAction)btnGoProCaptureNow:(id)sender {
	[RVC.captureView presentGoProView];
	[self hideOverlays];
}

#pragma mark - Custom

- (void)updateBadges
{
    if (CurrentUser.feedCount > 0) {
        self.lblBadge.text = [NSString stringWithFormat:@"%d", CurrentUser.feedCount];
        self.lblBadge.hidden = NO;
    } else {
        self.lblBadge.hidden = YES;
    }
    
    if (CurrentUser.notificationCount > 0) {
        self.lblActivityBadge.text = [NSString stringWithFormat:@"%d", CurrentUser.notificationCount];
        self.lblActivityBadge.hidden = NO;
    } else {
        self.lblActivityBadge.hidden = YES;
    }
}

- (void)goProCheck
{
	self.viewGoProHost.hidden = ![ORGoProEngine isInGoProNetwork];
}

- (void)hideOverlays
{
	self.viewGoProHost.hidden = YES;
}

#pragma mark - NSNotifications

- (void)_willEnterForeground:(NSNotification*)notification {
	[self goProCheck];
}

@end
