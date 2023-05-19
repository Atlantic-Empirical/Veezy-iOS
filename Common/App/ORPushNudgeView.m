//
//  ORPushNudgeView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 06/08/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORPushNudgeView.h"

@interface ORPushNudgeView ()

@end

@implementation ORPushNudgeView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.lblTitle.text = @"Message with Friends";
    self.lblSubtitle.text = @"Enable notifications to stay in touch";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORPushEnabled:) name:@"ORPushEnabled" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORPushRegistrationFailed:) name:@"ORPushRegistrationFailed" object:nil];
}

- (void)cellTapped:(id)sender
{
    [self requestPushPermission];
}

- (void)requestPushPermission
{
    [AppDelegate registerForPushNotifications];
}

- (void)handleORPushEnabled:(NSNotification *)n
{
    [RVC hideNudge:self];
}

- (void)handleORPushRegistrationFailed:(NSNotification *)n
{
    [RVC hideNudge:self];
}

@end
