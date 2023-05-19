//
//  ORAccountView.h
//  Session
//
//  Created by Thomas Purnell-Fisher on 11/14/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORUserSettingsView : GAITrackedViewController

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIButton *btnSignOut;
@property (weak, nonatomic) IBOutlet UILabel *lblVersion;
@property (weak, nonatomic) IBOutlet UIButton *btnChangePassword;
@property (weak, nonatomic) IBOutlet UIButton *btnLegal;
@property (weak, nonatomic) IBOutlet UIButton *btnManageNotifications;
@property (weak, nonatomic) IBOutlet UIButton *btnManagePrivacy;
@property (weak, nonatomic) IBOutlet UIButton *btnSocialAccounts;
@property (weak, nonatomic) IBOutlet UIButton *btnNetwork;
@property (weak, nonatomic) IBOutlet UIButton *btnDefaults;
@property (weak, nonatomic) IBOutlet UIButton *btnFeedback;
@property (weak, nonatomic) IBOutlet UIButton *btnUnlimited;
@property (weak, nonatomic) IBOutlet UIButton *btnDeleteAccount;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiDeleting;
@property (weak, nonatomic) IBOutlet UIButton *btnProfile;
@property (weak, nonatomic) IBOutlet UIButton *btnGoPro;
@property (weak, nonatomic) IBOutlet UISwipeGestureRecognizer *secretGesture;

- (IBAction)secretGestureAction:(id)sender;
- (IBAction)btnSignOut_TouchUpInside:(id)sender;
- (IBAction)btnChangePassword_TouchUpInside:(id)sender;
- (IBAction)btnLegal_TouchUpInside:(id)sender;
- (IBAction)btnSocialAccounts_TouchUpInside:(id)sender;
- (IBAction)btnManageNotifications_TouchUpInside:(id)sender;
- (IBAction)btnManagePrivacy_TouchUpInside:(id)sender;
- (IBAction)btnNetworkTouchUpInside:(id)sender;
- (IBAction)btnDefaults_TouchUpInside:(id)sender;
- (IBAction)btnFeedback_TouchUpInside:(id)sender;
- (IBAction)btnUnlimited_TouchUpInside:(id)sender;
- (IBAction)btnDeleteAccount_TouchUpInside:(id)sender;
- (IBAction)btnProfile_TouchUpInside:(id)sender;
- (IBAction)btnGoPro_TouchUpInside:(id)sender;
- (IBAction)btnDownloadVideos_TouchUpInside:(id)sender;

@end
