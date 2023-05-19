//
//  ORNotificationManagementView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 12/4/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORNotificationManagementView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UIButton *btnNewFollower_email;
@property (weak, nonatomic) IBOutlet UIButton *btnNewFollower_push;
@property (weak, nonatomic) IBOutlet UIButton *btnYourVideoLiked_email;
@property (weak, nonatomic) IBOutlet UIButton *btnYourVideoLiked_push;
@property (weak, nonatomic) IBOutlet UIButton *btnYourVideoReposted_email;
@property (weak, nonatomic) IBOutlet UIButton *btnYourVideoReposted_push;
@property (weak, nonatomic) IBOutlet UIButton *btnFriendSharedAVideo_email;
@property (weak, nonatomic) IBOutlet UIButton *btnFriendSharedAVideo_push;
@property (weak, nonatomic) IBOutlet UIButton *btnFriendIsLive_email;
@property (weak, nonatomic) IBOutlet UIButton *btnFriendIsLive_push;
@property (weak, nonatomic) IBOutlet UIButton *btnVideoComment_email;
@property (weak, nonatomic) IBOutlet UIButton *btnVideoComment_push;
@property (weak, nonatomic) IBOutlet UIButton *btnDirectVideo_email;
@property (weak, nonatomic) IBOutlet UIButton *btnDirectVideo_push;
@property (weak, nonatomic) IBOutlet UIButton *btnFriendJoined_email;
@property (weak, nonatomic) IBOutlet UIButton *btnFriendJoined_push;
@property (weak, nonatomic) IBOutlet UIButton *btnDigestInterval;

- (IBAction)buttonTouchUpInside:(UIButton *)sender;
- (IBAction)btnDigestIntervalTouchUpInside:(UIButton *)sender;


@end
