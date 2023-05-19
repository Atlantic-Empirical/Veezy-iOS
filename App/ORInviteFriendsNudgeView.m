//
//  ORInviteFriendsNudgeView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 29/04/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORInviteFriendsNudgeView.h"
#import "ORInviteFriendsModalView.h"

@interface ORInviteFriendsNudgeView ()

@end

@implementation ORInviteFriendsNudgeView

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.lblTitle.text = @"Invite Friends!";
    self.lblSubtitle.text = [NSString stringWithFormat:@"%@ is better with friends.", APP_NAME];
}

- (void)cellTapped:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"displayedInviteNudge"];
    [defaults synchronize];

    ORInviteFriendsModalView *vc = [ORInviteFriendsModalView new];
    [RVC presentModalVC:vc];
    
    [RVC hideNudge:self];
}

- (void)btnClose_TouchUpInside:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"displayedInviteNudge"];
    [defaults synchronize];

    [super btnClose_TouchUpInside:self.btnClose];
}

@end
