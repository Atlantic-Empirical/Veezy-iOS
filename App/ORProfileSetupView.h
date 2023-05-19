//
//  ORProfileSetupView.h
//  Veezy
//
//  Created by Thomas Purnell-Fisher on 11/5/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORProfileSetupView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UIImageView *imgAvatar;
@property (weak, nonatomic) IBOutlet UITextField *txtUsername;
@property (weak, nonatomic) IBOutlet UITextField *txtBio;
@property (weak, nonatomic) IBOutlet UITextField *txtEmail;
@property (weak, nonatomic) IBOutlet UILabel *lblInvalidEmailX;
@property (weak, nonatomic) IBOutlet UIView *viewWait;
@property (weak, nonatomic) IBOutlet UIButton *btnCancelSave;
@property (weak, nonatomic) IBOutlet UIButton *btnAnonTapCatcher;
@property (weak, nonatomic) IBOutlet UIButton *btnAvatar;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiUploading;

- (IBAction)btnAvatar_TouchUpInside:(id)sender;
- (IBAction)btnCancelSave_TouchUpInside:(id)sender;
- (IBAction)btnAnonTapCatcher_TouchUpInside:(id)sender;

@end
