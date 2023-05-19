//
//  ORSignInViewController.m
//  Epic
//
//  Created by Rodrigo Sieiro on 29/10/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <Accounts/Accounts.h>
#import <FacebookSDK/FacebookSDK.h>
#import "ORSignInViewController.h"
#import "ORStringHash.h"
#import "ORPermissionsEngine.h"
#import "ORPermissionsView.h"

@interface ORSignInViewController () <UIActionSheetDelegate, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UIAlertViewDelegate>

@property (nonatomic, strong) NSArray *twitterAccounts;
@property (assign, nonatomic) BOOL isValidatingEmailAddress;
@property (assign, nonatomic) BOOL didCancel;
@property (assign, nonatomic) BOOL oldUserIsAnonymous;
@property (assign, nonatomic) BOOL permissionViewShown;

@property (assign, nonatomic) CGRect fFacebook;
@property (assign, nonatomic) CGRect fTwitter;
@property (assign, nonatomic) CGRect fEmail;

@end

@implementation ORSignInViewController

- (void)dealloc
{
    AppDelegate.isLinkingFacebook = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;
    
    self.automaticAccountType = -1;
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.transitioningDelegate = self;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];

	self.title = @"Sign-In";
	self.screenName = @"SignIn";
	
	[self registerForNotifications];
    
    self.oldUserIsAnonymous = (CurrentUser.accountType == 3);
	
	[self setupViews];
    
    self.viewSignInHome.layer.cornerRadius = 2.0f;
    self.viewSignin.layer.cornerRadius = 2.0f;
    self.viewSignup.layer.cornerRadius = 2.0f;
    
    self.btnSignInWithTwitter.layer.cornerRadius = 2.0f;
    self.btnSignInWithFacebook.layer.cornerRadius = 2.0f;
    self.btnSignInWithEmail.layer.cornerRadius = 2.0f;
    self.btnNotNow.layer.cornerRadius = 2.0f;
    self.btnCreateAccount.layer.cornerRadius = 2.0f;
    self.btnCCSignIn.layer.cornerRadius = 2.0f;
    self.btnCCSignInToHome.layer.cornerRadius = 2.0f;
    self.btnCCSignUpToHome.layer.cornerRadius = 2.0f;
    self.btnSignUp.layer.cornerRadius = 2.0f;
	self.btnCreateAccount.layer.cornerRadius = 2.0f;
	
	self.aiEmailValidation.color = APP_COLOR_PRIMARY;
	self.viewHeader.backgroundColor = APP_COLOR_PRIMARY;
	self.viewHeader2.backgroundColor = APP_COLOR_PRIMARY;
	self.viewHeader3.backgroundColor = APP_COLOR_PRIMARY;

//	self.fEmail = self.btnSignInWithEmail.frame;
//	self.fTwitter = self.btnSignInWithTwitter.frame;
//	self.fFacebook = self.btnSignInWithFacebook.frame;
//	
//	self.btnSignInWithEmail.frame = self.btnSignIn.frame;
//	self.btnSignInWithTwitter.frame = self.btnSignIn.frame;
//	self.btnSignInWithFacebook.frame = self.btnSignIn.frame;
	
}

- (void)viewDidAppear:(BOOL)animated
{
    AppDelegate.isLinkingFacebook = YES;
    
    switch (self.automaticAccountType) {
        case 0: // E-mail
            [self btnSignInWithEmail_TouchUpInside:nil];
            break;
        case 1: // Twitter
            [self btnSignInWithTwitter_TouchUpInside:nil];
            break;
        case 2: // Facebook
            [self btnSignInWithFacebook_TouchUpInside:nil];
            break;
        default:
            break;
    }
    
    self.automaticAccountType = -1;
}

- (IBAction)view_TouchUpInside:(id)sender
{
	[self.view endEditing:YES];
}

- (void)setupViews
{
	// Veezy Sign-In
	[self.viewContent addSubview:self.viewSignin];
    self.viewSignin.center = CGPointMake(CGRectGetMidX(self.viewContent.bounds), CGRectGetMidY(self.viewContent.bounds));
    self.viewSignin.hidden = YES;
	self.viewSignin.alpha = 0.0f;

	// Veezy Sign-Up
	[self.viewContent addSubview:self.viewSignup];
    self.viewSignup.center = CGPointMake(CGRectGetMidX(self.viewContent.bounds), CGRectGetMidY(self.viewContent.bounds));
    self.viewSignup.hidden = YES;
	self.viewSignup.alpha = 0.0f;
	
	// Sign-In Home
	[self.viewContent addSubview:self.viewSignInHome];
    self.viewSignInHome.center = CGPointMake(CGRectGetMidX(self.viewContent.bounds), CGRectGetMidY(self.viewContent.bounds));
    self.viewSignInHome.hidden = NO;
	self.viewSignInHome.alpha = 1.0f;
}

- (void)closeWithSuccess:(BOOL)success
{
    if (!self.permissionViewShown && success && [[ORPermissionsEngine sharedInstance] needsPermissionView]) {
        self.permissionViewShown = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORPermissionsViewDismissed:) name:@"ORPermissionsViewDismissed" object:nil];
        ORPermissionsView *vc = [ORPermissionsView new];
        [self presentViewController:vc animated:YES completion:nil];
        return;
    }
    
    __weak ORSignInViewController *weakSelf = self;
    
    [self dismissViewControllerAnimated:YES completion:^{
        ORSignInViewController *strongSelf = weakSelf;
        [AppDelegate unlockOrientation];
        
        if (success) {
            if (strongSelf.oldUserIsAnonymous) ApiEngine.currentSessionID = [ORUtility newGuidString];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORUserSignedIn" object:nil userInfo:@{@"first_signin": @YES}];
        }
        
        if (strongSelf.completionBlock) strongSelf.completionBlock(success);
        strongSelf.completionBlock = nil;
    }];
}

- (void)handleORPermissionsViewDismissed:(NSNotification *)n
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ORPermissionsViewDismissed" object:nil];
    [self closeWithSuccess:YES];
}

#pragma mark - Transition and Presentation

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self;
}

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self;
}

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.25;
}

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController* vc1 = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController* vc2 = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView* con = [transitionContext containerView];
    UIView* v1 = vc1.view;
    UIView* v2 = vc2.view;
    
    if (vc2 == self) { // presenting
        [con addSubview:v2];
        v2.frame = v1.frame;
        self.viewContent.transform = CGAffineTransformMakeScale(1.6,1.6);
        v2.alpha = 0.0f;
        v1.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        
        [UIView animateWithDuration:0.25 animations:^{
            v2.alpha = 1.0f;
            self.viewContent.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else { // dismissing
        [UIView animateWithDuration:0.25 animations:^{
            self.viewContent.transform = CGAffineTransformMakeScale(0.5,0.5);
            v1.alpha = 0.0f;
        } completion:^(BOOL finished) {
            v2.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
            [transitionContext completeTransition:YES];
        }];
    }
}

#pragma mark - Orientation

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Anon Landing

- (void)btnNotNow_TouchUpInside:(id)sender
{
    if (self.aiSignIn.isAnimating) {
        self.didCancel = YES;
        [self enableInteraction:YES];
        
        [self.aiSignIn stopAnimating];
        self.imgLogo.hidden = NO;
        self.lblReason.hidden = NO;
    } else {
        [self closeWithSuccess:NO];
    }
}

- (IBAction)btnSignInWithTwitter_TouchUpInside:(id)sender
{
	[self presentTwitterAccountsForSignin];
}

- (IBAction)btnSignInWithFacebook_TouchUpInside:(id)sender
{
	[self tryFacebookSignin];
}

- (IBAction)btnSignInWithEmail_TouchUpInside:(id)sender
{
	[self configureForSignIn];

//	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Sign-in Method" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
//	sheet.tag = 1;
//	
//	[sheet addButtonWithTitle:@"Twitter"];
//	[sheet addButtonWithTitle:@"Facebook"];
//	[sheet addButtonWithTitle:@"Veezy Account"];
//	
//	//	sheet.destructiveButtonIndex = [sheet addButtonWithTitle:@"Don't Connect Twitter"];
//	sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
//	
//	UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
//	if ([window.subviews containsObject:self.view]) {
//		[sheet showInView:self.view];
//	} else {
//		[sheet showInView:window];
//	}
}

- (void)presentTwitterAccountsForSignin
{
    // Twitter accounts...
    [AppDelegate.twitterEngine existingAccountsWithCompletion:^(NSError *error, NSArray *items) {
        if (error && error.code != 403) NSLog(@"Error: %@", error);
        
        if (items.count > 0) {
            self.twitterAccounts = items;
            UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Select a Twitter Account" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            sheet.tag = 2;
			
            for (ACAccount *account in items) {
                [sheet addButtonWithTitle:account.accountDescription];
            }
            
            sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
            
            UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
            if ([window.subviews containsObject:self.view]) {
                [sheet showInView:self.view];
            } else {
                [sheet showInView:window];
            }
        } else {
            if (error && error.code == 403) {
                // Not authorized
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Access to Twitter Denied"
                                                                message:@"Please authorize Veezy to use your Twitter accounts in iOS Settings > Twitter then try again."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
                return;
            } else {
                // No accounts
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Twitter Account"
                                                                message:@"There are no Twitter accounts connected on this device - add one in iOS Settings > Twitter then try again."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }
    }];
}

- (void)tryFacebookSignin
{
    [self.view endEditing:YES];
    
    [self enableInteraction:NO];
    self.lblReason.hidden = YES;
    self.imgLogo.hidden = YES;
    [self.aiSignIn startAnimating];
    
    
    self.didCancel = NO;

	// If the session state is any of the two "open" states when the button is clicked
    if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        [FBSession.activeSession closeAndClearTokenInformation];
    }

    [AppDelegate facebookSignInAllowLoginUI:YES];
}

- (void)handleORFacebookSignedIn:(NSNotification *)n
{
    if (self.didCancel) {
        NSLog(@"Facebook signed in, but user did cancel before");
        self.didCancel = NO;

        // If the session state is any of the two "open" states
        if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
            [FBSession.activeSession closeAndClearTokenInformation];
        }

        return;
    }
    
    NSLog(@"Facebook sign in handled by ORSignInViewController");
    
    if (FBSession.activeSession.state == FBSessionStateOpen) {
        [self.view endEditing:YES];
        
        [self enableInteraction:NO];
        self.lblReason.hidden = YES;
        self.imgLogo.hidden = YES;
        [self.aiSignIn startAnimating];
        
        self.didCancel = NO;
        
        NSString *oldId = (CurrentUser.accountType == 3) ? CurrentUser.userId : nil;
        
        OREpicUser *u = [OREpicUser new];
        u.anonymousUserId = oldId;
        u.accountType = 2;
        u.facebookToken = FBSession.activeSession.accessTokenData.accessToken;
        u.appName = APP_NAME;
        if (AppDelegate.firstAppRun) u.justCreated = YES;
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:FBSession.activeSession.accessTokenData.dictionary];
        if (data) u.facebookTokenData = [data base64EncodedString];
        
        [ApiEngine signInWithUser:u cb:^(NSError *error, OREpicUser *user) {
            [self enableInteraction:YES];
            
            if (self.didCancel) {
                NSLog(@"Signed in, but user did cancel before");
                self.didCancel = NO;
                return;
            }

            [self.aiSignIn stopAnimating];
            self.lblReason.hidden = NO;
            self.imgLogo.hidden = NO;
            
            if (error || !user) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook Sign-in"
                                                                message:PAIRING_MESSAGE_FB_UNABLE_TO_USE_SELECTED_ACCOUNT
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
                CurrentUser = user;
                
                if (PUSH_ENABLED && ApiEngine.currentDeviceId && ![CurrentUser.deviceID isEqualToString:ApiEngine.currentDeviceId]) {
                    CurrentUser.deviceID = ApiEngine.currentDeviceId;
                    [ApiEngine updateDeviceId:CurrentUser.deviceID forUser:CurrentUser.userId cb:nil];
                }
                
                [CurrentUser saveLocalUser];
                
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
				[self closeWithSuccess:YES];
            }
        }];
    }
}

- (void)handleORFacebookSignedOut:(NSNotification *)n
{
    if (self.didCancel) {
        NSLog(@"Facebook signed out, but user did cancel before");
        self.didCancel = NO;
        return;
    }
    
    NSLog(@"Facebook sign out handled by ORSignInViewController");
    
    [self.aiSignIn stopAnimating];
    self.imgLogo.hidden = NO;
    self.lblReason.hidden = NO;
}

- (void)enableDismissal
{
    [self view];
    
    self.btnNotNow.hidden = NO;
}

#pragma mark - Signup

- (void)btnSignUp_TouchUpInside:(id)sender
{
    if (!self.txtEmailSignUp.text || [self.txtEmailSignUp.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME message:@"Please type your email address." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
	if (!self.lblInvalidEmailAddressX.hidden) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME message:@"Email address looks wrong. Please check it and try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
		return;
	}
	
	if (self.isValidatingEmailAddress) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME message:@"Validating email address. Please try again in a moment." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
	}
	
    if (!self.txtPasswordSignUp.text || [self.txtPasswordSignUp.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME message:@"Please type your desired password." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
	
    if (!self.txtName.text || [self.txtName.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME message:@"Please type your name." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
	if (!self.btnSignUp.enabled) {
		return;
	}

    [self.view endEditing:YES];
    [self enableInteraction:NO];
    [self.aiSignUp startAnimating];
    self.imgLogoSignUp.hidden = YES;
    self.didCancel = NO;
	
    OREpicUser *newUser = [OREpicUser new];
    newUser.anonymousUserId = (CurrentUser.accountType == 3) ? CurrentUser.userId : nil;
    newUser.emailAddress = self.txtEmailSignUp.text;
    newUser.password = [ORStringHash createSHA512:self.txtPasswordSignUp.text];
    newUser.name = self.txtName.text;
    newUser.appName = APP_NAME;
    if (AppDelegate.firstAppRun) newUser.justCreated = YES;
    
    [ApiEngine createUser:newUser cb:^(NSError *error, OREpicUser *user) {
        [self.aiSignUp stopAnimating];
        self.imgLogoSignUp.hidden = NO;
		
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME message:@"An error occurred while trying to create the account. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            
            [self enableInteraction:YES];
        } else if (!user) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME message:@"That email address is already used by another account." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            
            [self enableInteraction:YES];
        } else {
            CurrentUser = user;
            CurrentUser.justCreated = YES;
            [CurrentUser saveLocalUser];
            
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
			[self closeWithSuccess:YES];
        }
    }];
}

- (IBAction)btnCCSignUpToHome_TouchUpInside:(id)sender
{
	[self.view endEditing:YES];
	
	self.didCancel = YES;
	[self enableInteraction:YES];
	
	[self.aiSignIn stopAnimating];
	[self.aiCCSignIn stopAnimating];
	[self.aiSignUp stopAnimating];
	
    self.imgLogo.hidden = NO;
    self.imgCCLogo.hidden = NO;
    self.imgLogoSignUp.hidden = NO;
	self.lblReason.hidden = NO;
	self.lblCCReason.hidden = NO;
	
    self.viewSignInHome.hidden = NO;
    
	[UIView animateWithDuration:0.3f delay:0.0f
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 self.viewSignup.alpha = 0.0f;
						 self.viewSignInHome.alpha = 1.0f;
					 } completion:^(BOOL finished) {
						 self.viewSignup.hidden = YES;
					 }];
}

- (IBAction)btnExistingUserSignIn_TouchUpInside:(id)sender
{
	[self.view endEditing:YES];
    
    self.viewSignInHome.hidden = NO;
    
	[UIView animateWithDuration:0.3f delay:0.0f
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 self.viewSignup.alpha = 0.0f;
						 self.viewSignInHome.alpha = 1.0f;
					 } completion:^(BOOL finished) {
						 self.viewSignup.hidden = YES;
					 }];
}

#pragma mark - CC Signin

- (void)btnCCSignIn_TouchUpInside:(id)sender
{
    if (!self.txtEmailSignIn.text || [self.txtEmailSignIn.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME message:@"Please type your email address." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }

    if (!self.txtPasswordSignIn.text || [self.txtPasswordSignIn.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME message:@"Please type your password." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    [self.view endEditing:YES];
    [self enableInteraction:NO];
	self.lblCCReason.hidden = YES;
    self.imgCCLogo.hidden = YES;
    [self.aiCCSignIn startAnimating];
    
    self.didCancel = NO;
	
    NSString *hash = [ORStringHash createSHA512:self.txtPasswordSignIn.text];
    NSString *oldId = (CurrentUser.accountType == 3) ? CurrentUser.userId : nil;
    
    OREpicUser *u = [OREpicUser new];
    u.anonymousUserId = oldId;
    u.accountType = 0;
    u.emailAddress = self.txtEmailSignIn.text;
    u.password = hash;
    u.appName = APP_NAME;
    
    [ApiEngine signInWithUser:u cb:^(NSError *error, OREpicUser *userSignedIn) {
        if (self.didCancel) {
            NSLog(@"Signed in, but user did cancel before");
            self.didCancel = NO;
            return;
        }

        [self.aiCCSignIn stopAnimating];
        self.imgCCLogo.hidden = NO;
        self.lblCCReason.hidden = NO;
        
        if (error || !userSignedIn) {
			UIAlertView *alert = [[UIAlertView alloc]
								  initWithTitle:APP_NAME
								  message:@"Unable to sign-in with the provided info."
								  delegate:self
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:@"Forgotten Password", nil];
			alert.tag = 1;
			[alert show];
            self.btnForgotPassword.hidden = NO;
            [self enableInteraction:YES];
        } else {
            CurrentUser = userSignedIn;
            
            if (PUSH_ENABLED && ApiEngine.currentDeviceId && ![CurrentUser.deviceID isEqualToString:ApiEngine.currentDeviceId]) {
                CurrentUser.deviceID = ApiEngine.currentDeviceId;
                [ApiEngine updateDeviceId:CurrentUser.deviceID forUser:CurrentUser.userId cb:nil];
            }
            
            [CurrentUser saveLocalUser];
            
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
			[self closeWithSuccess:YES];
        }
    }];
}

- (void)btnCCSignInToHome_TouchUpInside:(id)sender
{
	[self.view endEditing:YES];
    
    self.viewSignInHome.hidden = NO;
    
	[UIView animateWithDuration:0.3f delay:0.0f
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 self.viewSignin.alpha = 0.0f;
						 self.viewSignInHome.alpha = 1.0f;
					 } completion:^(BOOL finished) {
						 self.viewSignin.hidden = YES;
					 }];
}

- (IBAction)btnForgotPassword_TouchUpInside:(id)sender
{
    self.imgLogo.hidden = YES;
	[self.aiSignIn startAnimating];
	if ([self.txtEmailSignIn.text isEqualToString:@""] == YES)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Lost Password"
														message:@"Please enter an email address then try again."
													   delegate:nil
											  cancelButtonTitle:@"Ok"
											  otherButtonTitles:nil];
		[alert show];
		[self.aiSignIn stopAnimating];
        self.imgLogo.hidden = NO;
	}
	else
	{
		[ApiEngine userForgotPassword:self.txtEmailSignIn.text cb:^(NSError* error, BOOL success) {
			[self.aiSignIn stopAnimating];
            self.imgLogo.hidden = NO;
			if (error) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Lost Password"
																message:[NSString stringWithFormat:@"We've encountered a problem while requesting a password reset: %@", [error localizedDescription]]
															   delegate:nil
													  cancelButtonTitle:@"Ok"
													  otherButtonTitles:nil];
				[alert show];
				
			} else {
				if (success)
				{
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Lost Password"
																	message:@"We've sent you an email that makes it simple to set a new password for your account."
																   delegate:nil
														  cancelButtonTitle:@"Ok"
														  otherButtonTitles:nil];
					[alert show];
				} else {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Lost Password"
																	message:[NSString stringWithFormat:@"Hmm, seems we couldn't find an account associated with that email address. Two options: try a different email or setup a new account (remember how easy that was?). You can also contact us with any questions at support@%@.", APP_DOMAIN]
																   delegate:nil
														  cancelButtonTitle:@"Ok"
														  otherButtonTitles:nil];
					[alert show];
				}
			}
		}];
	}
    
	[self.view endEditing:YES];
}

- (void)btnCreateAccount_TouchUpInside:(id)sender
{
    [self configureForSignUp];
}

#pragma mark - Configure View

- (void)configureForSignUp
{
    self.viewSignup.hidden = NO;
    self.txtEmailSignUp.text = self.txtEmailSignIn.text;
    
    [UIView animateWithDuration:0.3f animations:^{
		self.viewSignin.alpha = 0.0f;
		self.viewSignup.alpha = 1.0f;
    } completion:^(BOOL finished) {
        self.viewSignin.hidden = YES;
        [self focusOnFirstEmptyTextField:NO];
    }];
}

- (void)configureForSignIn
{
    self.viewSignin.hidden = NO;
    
    [UIView animateWithDuration:0.3f animations:^{
		self.viewSignin.alpha = 1.0f;
		self.viewSignInHome.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.viewSignInHome.hidden = YES;
        [self focusOnFirstEmptyTextField:YES];
    }];
}

- (void)focusOnFirstEmptyTextField:(BOOL)signIn
{
	if (signIn) {
		if (!self.txtEmailSignIn.text || [self.txtEmailSignIn.text isEqualToString:@""]) {
			[self.txtEmailSignIn becomeFirstResponder];
		} else if (!self.txtPasswordSignIn.text || [self.txtPasswordSignIn.text isEqualToString:@""]) {
			[self.txtPasswordSignIn becomeFirstResponder];
		}
	} else {
		if (!self.txtName.text || [self.txtName.text isEqualToString:@""]) {
			[self.txtName becomeFirstResponder];
//		} else if (!self.txtUsername.text || [self.txtUsername.text isEqualToString:@""]) {
//			[self.txtUsername becomeFirstResponder];
		} else if (!self.txtEmailSignUp.text || [self.txtEmailSignUp.text isEqualToString:@""]) {
			[self.txtEmailSignUp becomeFirstResponder];
		} else if (!self.txtPasswordSignUp.text || [self.txtPasswordSignUp.text isEqualToString:@""]) {
			[self.txtPasswordSignUp becomeFirstResponder];
		}
	}
}

#pragma mark - NSNotifications

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORFacebookSignedIn:) name:@"ORFacebookSignedIn" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORFacebookSignedOut:) name:@"ORFacebookSignedOut" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Keyboard

-(void)keyboardWillShow:(NSNotification*)notify
{
	NSDictionary* keyboardInfo = [notify userInfo];
	NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
	[UIView animateWithDuration:[animationDuration floatValue] delay:0.0f options:UIViewAnimationOptionAllowUserInteraction
							  animations:^{
                                  CGPoint p = self.view.center;
                                  p.y -= [self deltaForKeyboard];
                                  self.viewContent.center = p;
							  } completion:^(BOOL finished) {
								  //
							  }];
}

-(void)keyboardWillHide:(NSNotification*)notify
{
	NSDictionary* keyboardInfo = [notify userInfo];
	NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
	[UIView animateWithDuration:[animationDuration floatValue] delay:0.0f options:UIViewAnimationOptionAllowUserInteraction
							  animations:^{
								  self.viewContent.center = self.view.center;
							  } completion:^(BOOL finished) {
								  //
							  }];
}

- (float)deltaForKeyboard
{
    if (self.view.bounds.size.height < 560.0f) {
        return 140.0f;
    } else {
        return 110.0f;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	// SIGNUP
	
	if (textField == self.txtName) {
		[self.txtEmailSignUp becomeFirstResponder];
        return NO;
	}

//	else if (textField == self.txtUsername) {
//		[self.txtEmailSignUp becomeFirstResponder];
//		return NO;
//	}
	
    else if (textField == self.txtEmailSignUp) {
        [self.txtPasswordSignUp becomeFirstResponder];
        return NO;
    }

	else if (textField == self.txtPasswordSignUp) {
        [self btnSignUp_TouchUpInside:nil];
        return NO;
    }
	
	// SIGNIN
	
	else if (textField == self.txtEmailSignIn) {
		[self.txtPasswordSignIn becomeFirstResponder];
        return NO;
    }

	else if (textField == self.txtPasswordSignIn) {
		[self btnSignInWithEmail_TouchUpInside:nil];
        return NO;
    }

    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (textField == self.txtEmailSignUp && self.viewSignup.alpha == 1.0f) {
        [self validateEmailAddress];
	}
}

//- (BOOL)validatePasswordsMatch
//{
//	if (![self.txtPasswordSignUp.text isEqualToString:self.txtPasswordSignUpConfirm.text]) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME message:@"The passwords do not match." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//        [alert show];
//        return NO;
//    } else {
//		return YES;
//	}
//}

#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) return;
    
	if (actionSheet.tag == 1) {
		switch (buttonIndex) {
			case 0:
				[self presentTwitterAccountsForSignin];
				break;
			case 1:
				[self tryFacebookSignin];
				break;
			case 2:
				[self configureForSignIn];
				break;
				
			default:
				break;
		}
	}
	
	if (actionSheet.tag == 2) {
		if (buttonIndex < self.twitterAccounts.count) {
			NSLog(@"Authenticating with Twitter...");
			
			[self.view endEditing:YES];
            
			[self enableInteraction:NO];
			self.lblReason.hidden = YES;
            self.imgLogo.hidden = YES;
			[self.aiSignIn startAnimating];
            
			self.didCancel = NO;
			
			[AppDelegate.twitterEngine reverseAuthWithAccount:self.twitterAccounts[buttonIndex] completion:^(NSError *error) {
				if (self.didCancel) {
					NSLog(@"Signed in, but user did cancel before");
					self.didCancel = NO;
					return;
				}
				
				if (error) {
					[self.aiSignIn stopAnimating];
                    self.imgLogo.hidden = NO;
                    self.lblReason.hidden = NO;
					
					NSLog(@"Error: %@", error);
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
																	message:PAIRING_MESSAGE_TW_UNABLE_TO_USE_SELECTED_ACCOUNT
																   delegate:nil
														  cancelButtonTitle:@"OK"
														  otherButtonTitles:nil];
					[alert show];
					[self enableInteraction:YES];
					return;
				}
				
				if (AppDelegate.twitterEngine.isAuthenticated) {
					NSLog(@"Authenticated with Twitter as @%@", AppDelegate.twitterEngine.screenName);
					
					NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
					[prefs removeObjectForKey:@"twitterDisabled"];
					[prefs setObject:AppDelegate.twitterEngine.token forKey:@"twitterToken"];
					[prefs setObject:AppDelegate.twitterEngine.tokenSecret forKey:@"twitterTokenSecret"];
					[prefs setObject:AppDelegate.twitterEngine.userId forKey:@"twitterUserId"];
					[prefs setObject:AppDelegate.twitterEngine.screenName forKey:@"twitterScreenName"];
					[prefs setObject:AppDelegate.twitterEngine.userName forKey:@"twitterUserName"];
					[prefs synchronize];
					
                    NSString *oldId = (CurrentUser.accountType == 3) ? CurrentUser.userId : nil;
                    
					OREpicUser *u = [OREpicUser new];
                    u.anonymousUserId = oldId;
					u.accountType = 1;
					u.twitterToken = AppDelegate.twitterEngine.token;
					u.twitterSecret = AppDelegate.twitterEngine.tokenSecret;
                    u.twitterName = AppDelegate.twitterEngine.screenName;
                    u.appName = APP_NAME;
                    if (AppDelegate.firstAppRun) u.justCreated = YES;
					
					[ApiEngine signInWithUser:u cb:^(NSError *error, OREpicUser *user) {
						if (self.didCancel) {
							NSLog(@"Signed in, but user did cancel before");
							self.didCancel = NO;
							return;
						}
						
						[self.aiSignIn stopAnimating];
                        self.imgLogo.hidden = NO;
                        self.lblReason.hidden = NO;
						
						if (error || !user) {
							UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Twitter Sign-in"
																			message:@"Unable to Sign-in with that Twitter account. Please try again or use another account."
																		   delegate:nil
																  cancelButtonTitle:@"OK"
																  otherButtonTitles:nil];
							[alert show];
							[self enableInteraction:YES];
						} else {
							CurrentUser = user;
							
							if (PUSH_ENABLED && ApiEngine.currentDeviceId && ![CurrentUser.deviceID isEqualToString:ApiEngine.currentDeviceId]) {
								CurrentUser.deviceID = ApiEngine.currentDeviceId;
								[ApiEngine updateDeviceId:CurrentUser.deviceID forUser:CurrentUser.userId cb:nil];
							}
							
							[CurrentUser saveLocalUser];
							
							[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
							[self closeWithSuccess:YES];
						}
					}];
				}
			}];
		}
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (actionSheet.tag == 2) {
		self.twitterAccounts = nil;
	}
}

#pragma mark - AlertView Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	switch (alertView.tag) {
		case 1:
		{
			switch (buttonIndex) {
				case 0:
					// nada
					break;
					
				case 1:
					[self btnForgotPassword_TouchUpInside:nil];
					break;
					
				default:
					break;
			}
		}
			break;
			
		default:
			break;
	}
}

#pragma mark - Email Validation

- (void)validateEmailAddress
{
	self.isValidatingEmailAddress = YES;
	[self.aiEmailValidation startAnimating];
    [ApiEngine validateEmailAddress:self.txtEmailSignUp.text completion:^(NSError *error, BOOL result) {
		self.isValidatingEmailAddress = NO;
		[self.aiEmailValidation stopAnimating];
        if (!error) {
            self.lblInvalidEmailAddressX.hidden = result;
            self.btnSignUp.enabled = result;
            if (result) {
                // do nothing
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Email"
                                                                message:@"The email address seems to be invalid."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }
    }];
}

- (void)enableInteraction:(BOOL)enabled
{
    self.btnSignInWithTwitter.enabled = enabled;
    self.btnSignInWithFacebook.enabled = enabled;
    self.btnSignInWithEmail.enabled = enabled;
    self.btnCCSignIn.enabled = enabled;
    self.btnCCSignInToHome.enabled = enabled;
    self.btnCCSignUpToHome.enabled = enabled;
    self.btnCreateAccount.enabled = enabled;
    self.btnForgotPassword.enabled = enabled;
    self.btnSignUp.enabled = enabled;
    
    self.btnSignInWithTwitter.backgroundColor = (enabled) ? self.btnSignInWithTwitter.tintColor : [UIColor lightGrayColor];
    self.btnSignInWithFacebook.backgroundColor = (enabled) ? self.btnSignInWithFacebook.tintColor : [UIColor lightGrayColor];
    self.btnSignInWithEmail.backgroundColor = (enabled) ? self.btnSignInWithEmail.tintColor : [UIColor lightGrayColor];
}

@end
