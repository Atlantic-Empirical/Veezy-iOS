//
//  ORAccountView.m
//  Session
//
//  Created by Thomas Purnell-Fisher on 11/14/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORUserSettingsView.h"
#import "ORLegalStuffParentView.h"
#import "ORNotificationManagementView.h"
#import "ORPrivacySettingsView.h"
#import "ORPairingManagerView.h"
#import "ORTransferSettingsView.h"
#import "ORFeedbackView.h"
#import "ORFaspPersistentEngine.h"
#import "ORProfileSetupView.h"
#import "ORGoProInstructionsView.h"
#import "ORSubscriptionController.h"
#import "ORSubscriptionUpsell.h"
#import "ORAccountManagerView.h"
#import "ORSecretSettingsView.h"

@interface ORUserSettingsView () <UIGestureRecognizerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;

@end

@implementation ORUserSettingsView

- (void)dealloc
{
    self.alertView.delegate = nil;
    self.contentView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addSubview:self.contentView];
    ((UIScrollView *)self.view).contentSize = self.contentView.frame.size;
    
    self.screenName = NSLocalizedStringFromTable(@"Config", @"UserSettings", @"Config");
	
	// NAV BAR
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
	
	// NOTIFICATIONS
	[self registerForNotifications];

	// VERSION
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"]; // example: 1.0.0
	NSNumber *buildNumber = [infoDict objectForKey:@"CFBundleVersion"]; // example: 42
	self.lblVersion.text = [NSString stringWithFormat:@"v%@.%@", appVersion, buildNumber];

    self.aiDeleting.color = APP_COLOR_PRIMARY;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.title = @"S  E  T  T  I  N  G  S";
    self.tabBarController.navigationItem.title = self.title;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.title = @"SETTINGS";
    self.tabBarController.navigationItem.title = self.title;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UI

- (IBAction)btnSignOut_TouchUpInside:(id)sender
{
    if (CurrentUser.accountType == 3 && CurrentUser.totalVideoCount > 0) {
        [RVC presentSignInWithMessage:NSLocalizedStringFromTable(@"SignOutAccType3", @"UserSettings", @"Do you want to keep the videos you shot? You'll need a way to sign back in...") cancelTitle:NSLocalizedStringFromTable(@"SignOut", @"UserSettings", @"Sign out and delete videos") completion:^(BOOL success) {
            if (!success) {
                [self deleteAccount];
            }
        }];
        
        return;
    }
	
	NSString *msg = @"";
    NSString *videoCounterString = @"";
    NSString *thereAreString = @"";
	
	NSArray *pendingVideos = [[ORFaspPersistentEngine sharedInstance] allPendingVideos];
	if (pendingVideos.count > 0) {
        if (pendingVideos.count == 1) {
            videoCounterString = NSLocalizedStringFromTable(@"videoSingular", @"UserSettings", "String 'video' to be used when videos count is = 1");
            thereAreString = NSLocalizedStringFromTable(@"thereIs", @"UserSettings", "String 'there is' to be used when videos count is = 1");
        }
        else {
            videoCounterString = NSLocalizedStringFromTable(@"videoPlural", @"UserSettings", "String 'videos' to be used when videos count is > 1");
             thereAreString = NSLocalizedStringFromTable(@"thereAre", @"UserSettings", "String 'there are' to be used when videos count is > 1");
        }
		msg = [NSString localizedStringWithFormat:@"%@ %d %@ %@. %@", thereAreString, pendingVideos.count, videoCounterString, NSLocalizedStringFromTable(@"uploading", @"UserSettings", @"String: uploading"), NSLocalizedStringFromTable(@"IfYouSignOut", @"UserSettings", @"If you sign-out now the uploads will be cancelled and the videos will be removed from the phone (for your privacy).")];
	}
    
    self.alertView = [[UIAlertView alloc] initWithTitle:@""
													message:[NSString localizedStringWithFormat:@"%@ %@", msg, NSLocalizedStringFromTable(@"WantToSignOut", @"UserSettings", @"Do you want to sign out?")]
												   delegate:self
										  cancelButtonTitle:NSLocalizedStringFromTable(@"No", @"UserSettings", @"No")
										  otherButtonTitles:NSLocalizedStringFromTable(@"Yes", @"UserSettings", @"Yes"), nil];
	self.alertView.tag = 1;
	[self.alertView show];
}

- (IBAction)btnChangePassword_TouchUpInside:(id)sender
{
    if (CurrentUser.accountType == 3) {
        [RVC presentSignInWithMessage:@"Sign-In" completion:nil];
        return;
    }
    
    NSString *lostPassword = NSLocalizedStringFromTable(@"LostPassword", @"UserSettings", @"Lost Password");
    
	self.btnChangePassword.enabled = NO;
	[ApiEngine userForgotPassword:CurrentUser.emailAddress cb:^(NSError* error, BOOL success) {
		self.btnChangePassword.enabled = YES;
		if (error) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:lostPassword
															message:[NSString localizedStringWithFormat:@"%@ %@", NSLocalizedStringFromTable(@"errorPasswordReset", @"UserSettings", @"We've encountered a problem while requesting a password reset: "), [error localizedDescription]]
														   delegate:nil
												  cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"UserSettings", @"OK")
												  otherButtonTitles:nil];
			[alert show];
		} else {
			if (success)
			{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:lostPassword
																message:NSLocalizedStringFromTable(@"newPasswordEmail", @"UserSettings", @"We've sent you an email that makes it simple to set a new password for your account.")
															   delegate:nil
													  cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"UserSettings", @"OK")
													  otherButtonTitles:nil];
				[alert show];
			} else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:lostPassword
																message:[NSString localizedStringWithFormat:@"%@%@.", NSLocalizedStringFromTable(@"couldntFindYourAccount", @"UserSettings", @"Hmm, seems we couldn't find an account associated with that email address. Two options: try a different email or setup a new account (remember how easy that was?). You can also contact us with any questions at support@"), APP_DOMAIN]
															   delegate:nil
													  cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"UserSettings", @"OK")
													  otherButtonTitles:nil];
				[alert show];
			}
		}
	}];
}

- (IBAction)btnLegal_TouchUpInside:(id)sender
{
	ORLegalStuffParentView *vc = [ORLegalStuffParentView new];
	[self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)btnSocialAccounts_TouchUpInside:(id)sender {
	ORPairingManagerView *nm = [ORPairingManagerView new];
	[self.navigationController pushViewController:nm animated:YES];
}

- (IBAction)btnManageNotifications_TouchUpInside:(id)sender {
	ORNotificationManagementView *nm = [ORNotificationManagementView new];
	[self.navigationController pushViewController:nm animated:YES];
}

- (IBAction)btnManagePrivacy_TouchUpInside:(id)sender {
	ORPrivacySettingsView *nm = [ORPrivacySettingsView new];
	[self.navigationController pushViewController:nm animated:YES];
}

- (IBAction)btnNetworkTouchUpInside:(id)sender {
	ORTransferSettingsView *nm = [ORTransferSettingsView new];
	[self.navigationController pushViewController:nm animated:YES];
}

- (IBAction)btnDefaults_TouchUpInside:(id)sender
{
    self.alertView = [[UIAlertView alloc] initWithTitle:@""
                                                    message:NSLocalizedStringFromTable(@"resetSettings", @"UserSettings", @"Reset all settings to their defaults?")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"UserSettings", @"Cancel")
                                          otherButtonTitles:NSLocalizedStringFromTable(@"Reset", @"UserSettings", @"Reset"), nil];
    self.alertView.tag = 0;
    [self.alertView show];
}

- (IBAction)btnFeedback_TouchUpInside:(id)sender {
	ORFeedbackView *vc = [ORFeedbackView new];
	[self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)btnUnlimited_TouchUpInside:(id)sender {
	
	if (CurrentUser.subscriptionLevel == 0) {
		ORSubscriptionUpsell *vc = [ORSubscriptionUpsell new];
        [self presentViewController:vc animated:YES completion:nil];
	} else {
		ORAccountManagerView *vc = [ORAccountManagerView new];
		[self.navigationController pushViewController:vc animated:YES];
	}
}

- (IBAction)btnColdStart_TouchUpInside:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"OROpenWhatMakesVeezyAmazing" object:@(NO)];
}

- (IBAction)btnDeleteAccount_TouchUpInside:(id)sender {
    NSString *videoString = @"";
    if (CurrentUser.totalVideoCount == 1) {
        videoString = NSLocalizedStringFromTable(@"videoSingular", @"UserSettings", "String 'video' to be used when videos count is = 1");
    } else {
        videoString = NSLocalizedStringFromTable(@"videoPlural", @"UserSettings", "String 'videos' to be used when videos count is > 1");
    }
    
	self.alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"deleteAccountTitle", @"UserSettings", @"Delete Account")
                                                message:[NSString localizedStringWithFormat:@"%@ %d %@ %@", NSLocalizedStringFromTable(@"immediatelyDelete", @"UserSettings", @"This will immediately delete your account, including your"), CurrentUser.totalVideoCount, videoString, NSLocalizedStringFromTable(@"cantBeUndone", @"UserSettings", @"and cannot be undone.")]
												   delegate:self
										  cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"UserSettings", @"Cancel")
										  otherButtonTitles:NSLocalizedStringFromTable(@"deleteAccount", @"UserSettings", @"DELETE ACCOUNT"), nil];
	self.alertView.tag = 2;
	[self.alertView show];
}

- (IBAction)btnProfile_TouchUpInside:(id)sender {
	ORProfileSetupView *vc = [[ORProfileSetupView alloc] initWithNibName:nil bundle:nil];
	[self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)btnGoPro_TouchUpInside:(id)sender {
	ORGoProInstructionsView *vc = [[ORGoProInstructionsView alloc] initWithNibName:nil bundle:nil];
	[self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)btnDownloadVideos_TouchUpInside:(id)sender {
	UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Video Download"
												 message:[NSString stringWithFormat:@"Visit the %@ website at\n\n%@\n\nand sign into your account to download your videos to your computer.", APP_NAME, SERVICE_URL]
											   delegate:nil
									  cancelButtonTitle:@"Ok"
									  otherButtonTitles:nil];
	[av show];
}

- (void)secretGestureAction:(id)sender
{
    ORSecretSettingsView *vc = [ORSecretSettingsView new];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Custom

- (void)sendPwChangeEmail
{
    NSString *changePassword = NSLocalizedStringFromTable(@"changePassword", @"UserSettings", @"Change Password");
    
	[ApiEngine userForgotPassword:CurrentUser.emailAddress cb:^(NSError* error, BOOL success) {
		if (error) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:changePassword
															message:[NSString localizedStringWithFormat:@"%@ %@", NSLocalizedStringFromTable(@"errorPasswordReset", @"UserSettings", @"We've encountered a problem while requesting a password reset: "), [error localizedDescription]]
														   delegate:nil
												  cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"UserSettings", @"OK")
												  otherButtonTitles:nil];
			[alert show];
			
		} else {
			if (success)
			{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:changePassword
																message:NSLocalizedStringFromTable(@"newPasswordEmail", @"UserSettings", @"We've sent you an email that makes it simple to set a new password for your account.")
															   delegate:nil
													  cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"UserSettings", @"OK")
													  otherButtonTitles:nil];
				[alert show];
			} else {
				// should never happen
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:changePassword
																message:[NSString localizedStringWithFormat:@"%@%@.", NSLocalizedStringFromTable(@"couldntFindYourAccount", @"UserSettings", @"Hmm, seems we couldn't find an account associated with that email address. Two options: try a different email or setup a new account (remember how easy that was?). You can also contact us with any questions at support@"), APP_DOMAIN]
															   delegate:nil
													  cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"UserSettings", @"OK")
													  otherButtonTitles:nil];
				[alert show];
			}
		}
	}];
}

- (void)performSignOut
{
    [[ORFaspPersistentEngine sharedInstance] cancelAllUploads];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORPausePlayerHARD" object:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORCloseProfileViewThenSignout" object:nil];
}

- (void)deleteAccount
{
    [self.aiDeleting startAnimating];
    [self.btnDeleteAccount setTitle:@"" forState:UIControlStateNormal];
    self.view.userInteractionEnabled = NO;
    
    [[ORFaspPersistentEngine sharedInstance] cancelAllUploads];
    NSString *userId = CurrentUser.userId;
    
    [ApiEngine deleteUserById:userId cb:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
        if (PUSH_ENABLED) [ApiEngine updateDeviceId:nil forUser:userId cb:nil];
        [self performSignOut];
    }];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    if (alertView.cancelButtonIndex == buttonIndex) return;

	switch (alertView.tag) {
			
		case 0: { // Reset All Settings
            [CurrentUser.settings resetToDefaults];
            [ApiEngine saveUserSettings:CurrentUser.settings cb:^(NSError *error, BOOL result) {
                if (error) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME
                                                                    message:NSLocalizedStringFromTable(@"failedToReset", @"UserSettings", @"Failed to reset to defaults. Could be due to lack of internet connection.")
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"UserSettings", @"OK")
                                                          otherButtonTitles:nil];
                    [alert show];
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME
                                                                    message:NSLocalizedStringFromTable(@"resetToDefaults", @"UserSettings", @"Settings reset to defaults.")
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"UserSettings", @"OK")
                                                          otherButtonTitles:nil];
                    [alert show];
                }
            }];

			break;
		}
            
		case 1: { // Sign Out
            if (CurrentUser.accountType == 3) {
                [self deleteAccount];
            } else {
                [self performSignOut];
            }
            
			break;
        }
			
		case 2: {
            self.alertView.delegate = nil;
			self.alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"confirm", @"UserSettings", @"CONFIRM")
															message:NSLocalizedStringFromTable(@"areYouSure", @"UserSettings", @"Are you sure you want to delete everything? There's no going back from here.")
														   delegate:self
                                              cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"UserSettings", @"Cancel")
                                              otherButtonTitles:NSLocalizedStringFromTable(@"deleteAccount", @"UserSettings", @"DELETE ACCOUNT"), nil];
			self.alertView.tag = 3;
			[self.alertView show];
			break;
		}
			
		case 3: {
			[self deleteAccount];
		}
	}
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - NSNotifications

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORCloseProfileViewThenSignout:) name:@"ORCloseProfileViewThenSignout" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)handleORCloseProfileViewThenSignout:(NSNotification*)n
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORUserWillSignOut" object:nil];
    [self.navigationController popToRootViewControllerAnimated:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORUserSignedOut" object:nil];
}

#pragma mark - Keyboard

- (void)tapGesture:(UITapGestureRecognizer *)sender
{
    [self.view endEditing:YES];
    
    if (self.tapGesture) {
        [self.view removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
}

-(void)keyboardWillShow:(NSNotification*)notify
{
	NSDictionary* keyboardInfo = [notify userInfo];
    self.keyboardHeight = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    
    if (self.tapGesture) {
        [self.view removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
    
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    self.tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:self.tapGesture];
}

-(void)keyboardWillHide:(NSNotification*)notify
{
    self.keyboardHeight = 0;
    
    if (self.tapGesture) {
        [self.view removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
}

@end
