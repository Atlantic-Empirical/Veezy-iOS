//
//  ORPushNotificationPermissionView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 4/11/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORPushNotificationPermissionView.h"
#import <QuartzCore/QuartzCore.h>

@interface ORPushNotificationPermissionView ()

@property (strong, nonatomic) OREpicFriend *friend;

@end

@implementation ORPushNotificationPermissionView

- (id)initWithFriend:(OREpicFriend *)user
{
    self = [super initWithNibName:@"ORPushNotificationPermissionView" bundle:nil];
    if (self) {
		_friend = user;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.screenName = @"PushNotificationPermissionRequestAfterFollow";
	
	self.btnNoThanks.layer.cornerRadius = 2.0f;
	self.btnNotifyMe.layer.cornerRadius = 2.0f;
	self.lblUserName.text = self.friend.name;
	self.lblMessage.text = [NSString localizedStringWithFormat:@"%@ %@%@", NSLocalizedStringFromTable(@"WouldYouLike", @"UserProfile", @"Would you like to be alerted when"), self.friend.firstName, NSLocalizedStringFromTable(@"sharesVideoWithYou", @"UserProfile", @"shares a video with you?")];
    self.imgAvatar.image = [UIImage imageNamed:@"profile"];
    
    if (self.friend.profileImageUrl) {
		__weak OREpicFriend *weakFriend = self.friend;
		__weak ORPushNotificationPermissionView *weakSelf = self;
        
		[[ORCachedEngine sharedInstance] imageAtURL:[NSURL URLWithString:self.friend.profileImageUrl] maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
			if (error) NSLog(@"Error: %@", error);
			if (image && weakSelf.friend == weakFriend) {
				weakSelf.imgAvatar.image = image;
			}
		}];
	}
}

- (void)close
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btnNoThanks_TouchUpInside:(id)sender
{
	[self close];
}

- (IBAction)btnNotifyMe_TouchUpInside:(id)sender
{
    [AppDelegate registerForPushNotifications];
	[self close];
}

@end
