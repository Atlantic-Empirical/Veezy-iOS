//
//  ORSignInViewController.h
//  Epic
//
//  Created by Rodrigo Sieiro on 29/10/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORSignInViewController : GAITrackedViewController <UITextFieldDelegate>

@property (nonatomic, copy) void (^completionBlock)(BOOL success);
@property (nonatomic, assign) NSUInteger automaticAccountType;

// HOME
@property (nonatomic, weak) IBOutlet UIImageView *imgLogo;
@property (nonatomic, weak) IBOutlet UIImageView *imgCCLogo;
@property (nonatomic, weak) IBOutlet UIImageView *imgLogoSignUp;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *aiSignIn;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *aiCCSignIn;
@property (weak, nonatomic) IBOutlet UILabel *lblCCReason;
@property (weak, nonatomic) IBOutlet UIView *viewContent;
@property (weak, nonatomic) IBOutlet UIView *viewHeader;
@property (weak, nonatomic) IBOutlet UIView *viewHeader2;
@property (weak, nonatomic) IBOutlet UIView *viewHeader3;

- (IBAction)view_TouchUpInside:(id)sender;

// ANON LANDING
@property (strong, nonatomic) IBOutlet UIView *viewSignInHome;
@property (weak, nonatomic) IBOutlet UILabel *lblReason;
@property (weak, nonatomic) IBOutlet UIButton *btnSignInWithEmail;
@property (weak, nonatomic) IBOutlet UIButton *btnSignInWithTwitter;
@property (weak, nonatomic) IBOutlet UIButton *btnSignInWithFacebook;
@property (weak, nonatomic) IBOutlet UIButton *btnNotNow;

- (IBAction)btnSignInWithEmail_TouchUpInside:(id)sender;
- (IBAction)btnSignInWithTwitter_TouchUpInside:(id)sender;
- (IBAction)btnSignInWithFacebook_TouchUpInside:(id)sender;
- (IBAction)btnNotNow_TouchUpInside:(id)sender;

// SIGN-UP
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *aiSignUp;
@property (weak, nonatomic) IBOutlet UIView *viewSignup;
@property (nonatomic, weak) IBOutlet UITextField *txtName;
@property (nonatomic, weak) IBOutlet UITextField *txtEmailSignUp;
@property (nonatomic, weak) IBOutlet UITextField *txtPasswordSignUp;
@property (nonatomic, weak) IBOutlet UIButton *btnSignUp;
@property (weak, nonatomic) IBOutlet UIButton *btnCCSignUpToHome;
@property (weak, nonatomic) IBOutlet UILabel *lblInvalidEmailAddressX;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiEmailValidation;

- (IBAction)btnSignUp_TouchUpInside:(id)sender;
- (IBAction)btnCCSignUpToHome_TouchUpInside:(id)sender;

// CC SIGN-IN
@property (weak, nonatomic) IBOutlet UIView *viewSignin;
@property (weak, nonatomic) IBOutlet UITextField *txtEmailSignIn;
@property (weak, nonatomic) IBOutlet UITextField *txtPasswordSignIn;
@property (nonatomic, weak) IBOutlet UIButton *btnCCSignIn;
@property (weak, nonatomic) IBOutlet UIButton *btnForgotPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnCCSignInToHome;
@property (nonatomic, weak) IBOutlet UIButton *btnCreateAccount;

- (IBAction)btnCCSignIn_TouchUpInside:(id)sender;
- (IBAction)btnCCSignInToHome_TouchUpInside:(id)sender;
- (IBAction)btnForgotPassword_TouchUpInside:(id)sender;
- (IBAction)btnCreateAccount_TouchUpInside:(id)sender;

- (void)enableDismissal;

@end
