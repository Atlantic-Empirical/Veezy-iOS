//
//  ORPushNotificationPermissionView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 4/11/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORPushNotificationPermissionView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UIImageView *imgAvatar;
@property (weak, nonatomic) IBOutlet UILabel *lblUserName;
@property (weak, nonatomic) IBOutlet UILabel *lblMessage;
@property (weak, nonatomic) IBOutlet UIButton *btnNoThanks;
@property (weak, nonatomic) IBOutlet UIButton *btnNotifyMe;

- (IBAction)btnNoThanks_TouchUpInside:(id)sender;
- (IBAction)btnNotifyMe_TouchUpInside:(id)sender;

- (id)initWithFriend:(OREpicFriend *)user;

@end
