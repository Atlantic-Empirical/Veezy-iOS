//
//  ORNotificationManagementView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 12/4/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORNotificationManagementView.h"

@interface ORNotificationManagementView () <UIActionSheetDelegate>

@property (nonatomic, assign) BOOL modified;
@property (nonatomic, strong) UIActionSheet *actionSheet;

@end

@implementation ORNotificationManagementView

- (void)dealloc
{
    self.actionSheet.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
    self.title = NSLocalizedStringFromTable(@"Notifications", @"UserSettingsSub", @"Notifications");
	self.screenName = @"NotificationsMgr";
    
	[self loadSettings];
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (self.modified) {
        [CurrentUser saveLocalUser];
        
        [ApiEngine saveUserSettings:CurrentUser.settings cb:^(NSError *error, BOOL result) {
            if (error) {
                NSLog(@"Error: %@", error);
            } else {
                DLog(@"User settings saved.");
            }
        }];
    }
}

- (NSString *)nameForDigestType:(NSUInteger)type
{
    switch (type) {
        case 0:
            return @"Daily";
        case 1:
            return @"Weekly";
        case 2:
            return @"Monthly";
        default:
            return @"None";
    }
}

- (void)loadSettings
{
    self.btnFriendIsLive_email.selected = CurrentUser.settings.notifyOnFriendIsShootingLive_email;
    self.btnFriendIsLive_push.selected = CurrentUser.settings.notifyOnFriendIsShootingLive_push;
    self.btnFriendSharedAVideo_email.selected = CurrentUser.settings.notifyOnFriendSharedAVideo_email;
    self.btnFriendSharedAVideo_push.selected = CurrentUser.settings.notifyOnFriendSharedAVideo_push;
    self.btnNewFollower_email.selected = CurrentUser.settings.notifyOnNewFollower_email;
    self.btnNewFollower_push.selected = CurrentUser.settings.notifyOnNewFollower_push;
    self.btnYourVideoLiked_email.selected = CurrentUser.settings.notifyOnNewLike_email;
    self.btnYourVideoLiked_push.selected = CurrentUser.settings.notifyOnNewLike_push;
    self.btnYourVideoReposted_email.selected = CurrentUser.settings.notifyOnVideoReposted_email;
    self.btnYourVideoReposted_push.selected = CurrentUser.settings.notifyOnVideoReposted_push;
    self.btnVideoComment_email.selected = CurrentUser.settings.notifyOnVideoComment_email;
    self.btnVideoComment_push.selected = CurrentUser.settings.notifyOnVideoComment_push;
    self.btnDirectVideo_email.selected = CurrentUser.settings.notifyOnDirectVideo_email;
    self.btnDirectVideo_push.selected = CurrentUser.settings.notifyOnDirectVideo_push;
    self.btnFriendJoined_email.selected = CurrentUser.settings.notifyOnFriendJoined_email;
    self.btnFriendJoined_push.selected = CurrentUser.settings.notifyOnFriendJoined_push;
    
    [self.btnDigestInterval setTitle:[self nameForDigestType:CurrentUser.settings.digestType] forState:UIControlStateNormal];
}

- (void)buttonTouchUpInside:(UIButton *)sender
{
    self.modified = YES;
    sender.selected = !sender.selected;
    
    CurrentUser.settings.notifyOnFriendIsShootingLive_email = self.btnFriendIsLive_email.selected;
    CurrentUser.settings.notifyOnFriendIsShootingLive_push = self.btnFriendIsLive_push.selected;
    CurrentUser.settings.notifyOnFriendSharedAVideo_email = self.btnFriendSharedAVideo_email.selected;
    CurrentUser.settings.notifyOnFriendSharedAVideo_push = self.btnFriendSharedAVideo_push.selected;
    CurrentUser.settings.notifyOnNewFollower_email = self.btnNewFollower_email.selected;
    CurrentUser.settings.notifyOnNewFollower_push = self.btnNewFollower_push.selected;
    CurrentUser.settings.notifyOnNewLike_email = self.btnYourVideoLiked_email.selected;
    CurrentUser.settings.notifyOnNewLike_push = self.btnYourVideoLiked_push.selected;
    CurrentUser.settings.notifyOnVideoReposted_email = self.btnYourVideoReposted_email.selected;
    CurrentUser.settings.notifyOnVideoReposted_push = self.btnYourVideoReposted_push.selected;
    CurrentUser.settings.notifyOnVideoComment_email = self.btnVideoComment_email.selected;
    CurrentUser.settings.notifyOnVideoComment_push = self.btnVideoComment_push.selected;
    CurrentUser.settings.notifyOnDirectVideo_email = self.btnDirectVideo_email.selected;
    CurrentUser.settings.notifyOnDirectVideo_push = self.btnDirectVideo_push.selected;
    CurrentUser.settings.notifyOnFriendJoined_email = self.btnFriendJoined_email.selected;
    CurrentUser.settings.notifyOnFriendJoined_push = self.btnFriendJoined_push.selected;
}

- (void)btnDigestIntervalTouchUpInside:(UIButton *)sender
{
    self.actionSheet.delegate = nil;
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:@"Digest Interval"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                     destructiveButtonTitle:@"None"
                                          otherButtonTitles:@"Daily", @"Weekly", @"Monthly", nil];
    self.actionSheet.tag = 1;
    [self.actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    actionSheet.delegate = nil;
    
    if (actionSheet.tag == 1) {
        if (buttonIndex == actionSheet.cancelButtonIndex) return;
        
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            CurrentUser.settings.digestType = 9;
        } else if (buttonIndex == actionSheet.firstOtherButtonIndex) {
            CurrentUser.settings.digestType = 0;
        } else if (buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
            CurrentUser.settings.digestType = 1;
        } else if (buttonIndex == actionSheet.firstOtherButtonIndex + 2) {
            CurrentUser.settings.digestType = 2;
        }
        
        self.modified = YES;
        [self.btnDigestInterval setTitle:[self nameForDigestType:CurrentUser.settings.digestType] forState:UIControlStateNormal];
    }
}

@end
