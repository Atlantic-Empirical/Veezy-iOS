//
//  ORVideoOrderCell.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 16/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORVideoOrderCell.h"
#import "ORPushNotificationPermissionView.h"
#import "ORFollowersFollowingListView.h"
#import "ORUserProfileView.h"
#import "ORUserListView.h"
#import "ORAvatarView.h"
#import "ORMapView.h"
#import "ORAVURLProcessor.h"
#import "ORCaptureView.h"

@interface ORVideoOrderCell ()

@property (nonatomic, assign) int videoCount;

@end

@implementation ORVideoOrderCell

- (void)awakeFromNib
{
    self.videoCount = -1;
	self.viewIndicatorLine.backgroundColor = APP_COLOR_PRIMARY;
	self.viewSeparator.backgroundColor = APP_COLOR_PRIMARY;
}

- (void)setUser:(OREpicFriend *)user
{
    _user = user;
    int userVideoCount = 0;
    
    if ([user.userId isEqualToString:CurrentUser.userId]) {
        userVideoCount = (self.videoCount >= 0) ? self.videoCount : MAX(CurrentUser.totalVideoCount, CurrentUser.videoCount);
    } else {
        userVideoCount = (self.videoCount >= 0) ? self.videoCount : user.videoCount;
    }
    
    self.lblVideos.text = [NSString localizedStringWithFormat:@"%d %@%@", userVideoCount, NSLocalizedStringFromTable(@"ProfileVideos", @"UserProfile", @"Videos of profile"),userVideoCount == 1 ? @"" : @"s"];
	
	self.lblViewCount.text = [NSString localizedStringWithFormat:@"%d views", user.viewCount];

	if ([user.userId isEqualToString:CurrentUser.userId]) {
		self.btnPlus.hidden = NO;
	} else {
		self.btnPlus.hidden = YES;
	}
	
}

- (IBAction)navToTab:(UIButton*)button
{
    self.btnOrderBy_Recency.selected = (button == self.btnOrderBy_Recency);
    self.btnOrderBy_Views.selected = (button == self.btnOrderBy_Views);
    self.btnOrderBy_Likes.selected = (button == self.btnOrderBy_Likes);
    self.btnOrderBy_Reposts.selected = (button == self.btnOrderBy_Reposts);
    
//	self.lblDate.textColor = [UIColor colorWithRed:51.0f/255.0f green:51.0f/255.0f blue:51.0f/255.0f alpha:1.0f];
//	self.lblViews.textColor = [UIColor colorWithRed:51.0f/255.0f green:51.0f/255.0f blue:51.0f/255.0f alpha:1.0f];
//	self.lblComments.textColor = [UIColor colorWithRed:51.0f/255.0f green:51.0f/255.0f blue:51.0f/255.0f alpha:1.0f];
	
//	if (button == self.btnOrderBy_Recency)
//		self.lblDate.textColor = APP_COLOR_PRIMARY;
//	else if (button == self.btnOrderBy_Views)
//		self.lblViews.textColor = APP_COLOR_PRIMARY;
//	else if (button == self.btnOrderBy_Likes)
//		self.lblComments.textColor = APP_COLOR_PRIMARY;
	
	[UIView animateWithDuration:0.3f delay:0.0f
						options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 CGPoint pt = self.imgIndicator.center;
						 pt.x = button.center.x;
						 self.imgIndicator.center = pt;
						 
//						 CGRect f = self.imgIndicator.frame;
//						 f.origin.x = button.frame.origin.x;
////						 f.size.width = button.frame.size.width;
//						 self.imgIndicator.frame = f;s
					 } completion:^(BOOL finished) {
						 //
					 }];
    
    [self.parent reorderVideos];
}

- (void)updateVideoCount:(int)count
{
    self.videoCount = count;
    int userVideoCount = 0;
    
    if ([self.user.userId isEqualToString:CurrentUser.userId]) {
        userVideoCount = (self.videoCount >= 0) ? self.videoCount : MAX(CurrentUser.totalVideoCount, CurrentUser.videoCount);
    } else {
        userVideoCount = (self.videoCount >= 0) ? self.videoCount : self.user.videoCount;
    }

    self.lblVideos.text = [NSString localizedStringWithFormat:@"%d %@%@", userVideoCount, NSLocalizedStringFromTable(@"ProfileVideos", @"UserProfile", @"Videos of profile"),userVideoCount == 1 ? @"" : @"s"];
}

@end
