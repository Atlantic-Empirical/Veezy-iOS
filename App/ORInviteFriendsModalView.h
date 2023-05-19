//
//  ORInviteFriendsModalView.h
//  Veezy
//
//  Created by Thomas Purnell-Fisher on 11/8/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@class ORPassthroughView;

@interface ORInviteFriendsModalView : GAITrackedViewController

@property (nonatomic, weak) IBOutlet UIView *viewContent;

@property (weak, nonatomic) IBOutlet UIButton *btnMessage;
@property (weak, nonatomic) IBOutlet UIButton *btnMail;
@property (weak, nonatomic) IBOutlet UIButton *btnTwitter;
@property (weak, nonatomic) IBOutlet UIButton *btnFacebook;
@property (weak, nonatomic) IBOutlet UIButton *btnWhatsApp;
@property (weak, nonatomic) IBOutlet UIView *viewWhatsapp;
@property (weak, nonatomic) IBOutlet ORPassthroughView *viewPassthrough;
@property (weak, nonatomic) IBOutlet UIButton *btnClose;

- (IBAction)view_TouchUpInside:(id)sender;
- (IBAction)btnMessage_TouchUpInside:(id)sender;
- (IBAction)btnMail_TouchUpInside:(id)sender;
- (IBAction)btnTwitter_TouchUpInside:(id)sender;
- (IBAction)btnFacebook_TouchUpInside:(id)sender;
- (IBAction)btnWhatsApp_TouchUpInside:(id)sender;

@end
