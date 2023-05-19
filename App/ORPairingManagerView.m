//
//  ORSocialConfigView.m
//  OneCent
//
//  Created by Thomas Purnell-Fisher on 12/18/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORPairingManagerView.h"
#import "ORContactsListView.h"
#import "ORDataController.h"
#import "ORNavigationController.h"
#import "ORContact.h"
#import "ORWebView.h"
#import "ORFacebookConnectView.h"

@interface ORPairingManagerView () <UIActionSheetDelegate, ORGoogleEngineDelegate, ORWebViewDelegate>

@property (nonatomic, strong) NSString *facebookName;
@property (nonatomic, strong) NSArray *twitterAccounts;
@property (nonatomic, assign) BOOL didCancel;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) BOOL isSigningIn;

@end

@implementation ORPairingManagerView

NSString *okString = @"ok";
NSString *connectedString = @"Connected";
NSString *disconnectString = @"Disconnect";
NSString *cancelString = @"Cancel";
NSString *connectString = @"Connect";

- (void)dealloc
{
    AppDelegate.isLinkingFacebook = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
    self.title = @"Pairing";
	self.screenName = @"PairingMgr";
    
//    if (self.navigationController.childViewControllers.count == 1) {
//        // Camera as left bar button
//        UIBarButtonItem *camera = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"camera-icon-black-40x"] style:UIBarButtonItemStylePlain target:RVC action:@selector(showCamera)];
//        self.navigationItem.leftBarButtonItem = camera;
//    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORFacebookSignedOut:) name:@"ORFacebookSignedOut" object:nil];

	[self loadSettings];
	self.aiLoading.color = APP_COLOR_PRIMARY;
}

- (void)viewDidAppear:(BOOL)animated
{
    self.isVisible = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.isVisible = NO;
}

- (void)loadSettings
{
    self.btnTwitter.hidden = YES;
    self.btnFacebook.hidden = YES;
    self.btnGoogle.hidden = YES;
    [self.aiLoading startAnimating];
    self.btnCancel.hidden = YES;
    
    connectString = NSLocalizedStringFromTable(@"Connect", @"UserSettingsSub", @"Connect");

    if (CurrentUser.isTwitterAuthenticated) {
        [self.btnTwitter setTitle:[NSString stringWithFormat:@"@%@", AppDelegate.twitterEngine.screenName] forState:UIControlStateNormal];
    } else {
        [self.btnTwitter setTitle:[NSString localizedStringWithFormat:@"%@ Twitter", connectString] forState:UIControlStateNormal];
    }

    if (AppDelegate.ge.isAuthenticated) {
        [self.btnGoogle setTitle:AppDelegate.ge.userEmail forState:UIControlStateNormal];
    } else {
        [self.btnGoogle setTitle:[NSString localizedStringWithFormat:@"%@ Google", connectString] forState:UIControlStateNormal];
    }

    if (CurrentUser.isFacebookAuthenticated) {
        if (!self.facebookName) {
            [FBRequestConnection startWithGraphPath:@"me?fields=id,name" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    self.facebookName = result[@"name"];
                    [self.btnFacebook setTitle:self.facebookName forState:UIControlStateNormal];
                } else {
                    [FBSession.activeSession closeAndClearTokenInformation];
                    [self.btnFacebook setTitle:[NSString localizedStringWithFormat:@"%@ Facebook", connectString] forState:UIControlStateNormal];
                }
                
                self.btnTwitter.hidden = NO;
                self.btnFacebook.hidden = NO;
                self.btnGoogle.hidden = NO;
                self.btnTwitter.enabled = YES;
                self.btnFacebook.enabled = YES;
                self.btnGoogle.enabled = YES;
                [self.aiLoading stopAnimating];
                self.btnCancel.hidden = YES;
            }];
            
            return;
        }
        
        [self.btnFacebook setTitle:self.facebookName forState:UIControlStateNormal];
    } else {
        [self.btnFacebook setTitle:[NSString localizedStringWithFormat:@"%@ Facebook", connectString] forState:UIControlStateNormal];
    }

    self.btnTwitter.hidden = NO;
    self.btnFacebook.hidden = NO;
    self.btnGoogle.hidden = NO;
    self.btnTwitter.enabled = YES;
    self.btnFacebook.enabled = YES;
    self.btnGoogle.enabled = YES;
    [self.aiLoading stopAnimating];
    self.btnCancel.hidden = YES;
}

- (void)btnTwitter_TouchUpInside:(id)sender
{
    if (CurrentUser.isTwitterAuthenticated) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[NSString localizedStringWithFormat:@"@%@ %@", AppDelegate.twitterEngine.screenName, NSLocalizedStringFromTable(@"Connected", @"UserSettingsSub", @"Connected")] delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        sheet.tag = 2;
 
        sheet.destructiveButtonIndex = [sheet addButtonWithTitle:NSLocalizedStringFromTable(@"Disconnect", @"UserSettingsSub", @"Disconnect")];
        sheet.cancelButtonIndex = [sheet addButtonWithTitle:NSLocalizedStringFromTable(@"Cancel", @"UserSettingsSub", @"Cancel")];
        [sheet showInView:self.view];
    } else {
        if (CurrentUser.accountType == 3) {
            self.isVisible = NO;
            self.isSigningIn = YES;
            [RVC presentSignInWithMessage:@"Sign-in to find your friends!" completion:^(BOOL success) {
                self.isVisible = YES;
                self.isSigningIn = NO;
                [self loadSettings];
            }];
            
            return;
        }

        [AppDelegate.twitterEngine existingAccountsWithCompletion:^(NSError *error, NSArray *items) {
            if (error) NSLog(@"Error: %@", error);
            
            // i18n repetative use
            okString = NSLocalizedStringFromTable(@"OK", @"UserSettingsSub", @"OK");
            
            if (items.count > 0) {
                self.twitterAccounts = items;
                UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedStringFromTable(@"selectTwitterAcc", @"UserSettingsSub", @"Select a Twitter account to use with Veezy:") delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
                sheet.tag = 1;
                
                for (ACAccount *account in items) {
                    [sheet addButtonWithTitle:account.accountDescription];
                }
                
                sheet.cancelButtonIndex = [sheet addButtonWithTitle:NSLocalizedStringFromTable(@"Cancel", @"UserSettingsSub", @"Cancel")];
                [sheet showInView:self.view];
            } else {
                if (error && error.code == 403) {
                    // Not authorized
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"twitterNotAutorized", @"UserSettingsSub", @"Access to Twitter denied")
                                                                    message:NSLocalizedStringFromTable(@"twitterNotAutorizedMsg", @"UserSettingsSub", @"Please authorize Veezy to use your Twitter accounts in iOS Settings > Twitter then try again.")
                                                                   delegate:nil
                                                          cancelButtonTitle:okString
                                                          otherButtonTitles:nil];
                    [alert show];
                } else {
                    // No accounts
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"twitterNoAccounts", @"UserSettingsSub", @"No Twitter Account")
                                                                    message:NSLocalizedStringFromTable(@"twitterNoAccountsMsg", @"UserSettingsSub", @"It seems there are no Twitter accounts connected on this device - add one in iOS Settings > Twitter then try again.")
                                                                   delegate:nil
                                                          cancelButtonTitle:okString
                                                          otherButtonTitles:nil];
                    [alert show];
                }
            }
        }];
    }
}

- (void)btnFacebook_TouchUpInside:(id)sender
{
    if (CurrentUser.isFacebookAuthenticated) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[NSString localizedStringWithFormat:@"%@ %@", self.facebookName, NSLocalizedStringFromTable(@"Connected", @"UserSettingsSub", @"Connected")] delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        sheet.tag = 3;
        
        sheet.destructiveButtonIndex = [sheet addButtonWithTitle:NSLocalizedStringFromTable(@"Disconnect", @"UserSettingsSub", @"Disconnect")];
        sheet.cancelButtonIndex = [sheet addButtonWithTitle:NSLocalizedStringFromTable(@"Cancel", @"UserSettingsSub", @"Cancel")];
        [sheet showInView:self.view];
    } else {
        if (CurrentUser.accountType == 3) {
            self.isVisible = NO;
            self.isSigningIn = YES;
            [RVC presentSignInWithMessage:@"Sign-in to find your friends!" completion:^(BOOL success) {
                self.isVisible = YES;
                self.isSigningIn = NO;
                [self loadSettings];
            }];
            
            return;
        }

        ORFacebookConnectView *vc = [ORFacebookConnectView new];
        [vc setCompletionBlock:^(BOOL success) {
            [self loadSettings];
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [self presentViewController:vc animated:YES completion:nil];

    }
}

- (void)btnGoogle_TouchUpInside:(id)sender
{
    // i18n repetative use
    okString = NSLocalizedStringFromTable(@"OK", @"UserSettingsSub", @"OK");
    
    if (AppDelegate.ge.isAuthenticated) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[NSString localizedStringWithFormat:@"%@ %@", AppDelegate.ge.userEmail, NSLocalizedStringFromTable(@"Connected", @"UserSettingsSub", @"Connected")] delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        sheet.tag = 4;
        
        sheet.destructiveButtonIndex = [sheet addButtonWithTitle:NSLocalizedStringFromTable(@"Disconnect", @"UserSettingsSub", @"Disconnect")];
        sheet.cancelButtonIndex = [sheet addButtonWithTitle:NSLocalizedStringFromTable(@"Cancel", @"UserSettingsSub", @"Cancel")];
        [sheet showInView:self.view];
    } else {
        if (CurrentUser.accountType == 3) {
            self.isVisible = NO;
            self.isSigningIn = YES;
            [RVC presentSignInWithMessage:@"Sign-in to find your friends!" completion:^(BOOL success) {
                self.isVisible = YES;
                self.isSigningIn = NO;
                [self loadSettings];
            }];
            
            return;
        }
        
        [self.aiLoading startAnimating];
        self.btnCancel.hidden = NO;
        self.didCancel = NO;
        self.btnFacebook.enabled = NO;
        self.btnTwitter.enabled = NO;
        self.btnGoogle.enabled = NO;

        AppDelegate.ge.delegate = self;
        
        __weak ORPairingManagerView *weakSelf = self;
        [AppDelegate.ge authenticateWithCompletion:^(NSError *error) {
            if (error) NSLog(@"Error: %@", error);
            
            if (AppDelegate.ge.isAuthenticated) {
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                [prefs setObject:AppDelegate.ge.token forKey:@"googleToken"];
                [prefs setObject:AppDelegate.ge.tokenSecret forKey:@"googleTokenSecret"];
                [prefs setObject:AppDelegate.ge.userID forKey:@"googleUserID"];
                [prefs setObject:AppDelegate.ge.userName forKey:@"googleUserName"];
                [prefs setObject:AppDelegate.ge.userEmail forKey:@"googleUserEmail"];
                [prefs setObject:AppDelegate.ge.profilePicture forKey:@"googleProfilePicture"];
                [prefs synchronize];
                
                NSLog(@"Authenticated with Google: %@", AppDelegate.ge.userEmail);
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ORGooglePaired" object:nil];
                
                CurrentUser.googleToken = AppDelegate.ge.token;
                CurrentUser.googleSecret = AppDelegate.ge.tokenSecret;
                
                OREpicUser *u = [OREpicUser new];
                u.userId = CurrentUser.userId;
                u.googleToken = CurrentUser.googleToken;
                u.googleSecret = CurrentUser.googleSecret;
                
                [ApiEngine savePairing:u cb:^(NSError *error, BOOL result) {
                    if (weakSelf.didCancel) {
                        NSLog(@"Google signed in, but user did cancel before");
                        weakSelf.didCancel = NO;
                        
                        return;
                    }
                    
                    if (error || !result) {
                        NSString *email = AppDelegate.ge.userEmail;
                        [AppDelegate.ge resetOAuthToken];
                        
                        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                        [prefs removeObjectForKey:@"googleToken"];
                        [prefs removeObjectForKey:@"googleTokenSecret"];
                        [prefs removeObjectForKey:@"googleUserID"];
                        [prefs removeObjectForKey:@"googleUserEmail"];
                        [prefs removeObjectForKey:@"googleUserName"];
                        [prefs removeObjectForKey:@"googleProfilePicture"];
                        [prefs synchronize];
                        
                        CurrentUser.googleToken = nil;
                        CurrentUser.googleSecret = nil;
                        
                        if (error) {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                            message:PAIRING_MESSAGE_GO_UNABLE_TO_USE_SELECTED_ACCOUNT
                                                                           delegate:nil
                                                                  cancelButtonTitle:okString
                                                                  otherButtonTitles:nil];
                            [alert show];
                        } else if (!result) {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"@%@", email]
                                                                            message:PAIRING_MESSAGE_GOACCOUNT_PAIRED_TO_OTHER_CCACCOUNT
                                                                           delegate:nil
                                                                  cancelButtonTitle:okString
                                                                  otherButtonTitles:nil];
                            [alert show];
                        }
                    }
                    
                    [CurrentUser saveLocalUser];
                    
                    [weakSelf.aiLoading stopAnimating];
                    weakSelf.btnCancel.hidden = YES;
                    weakSelf.btnTwitter.enabled = YES;
                    weakSelf.btnFacebook.enabled = YES;
                    weakSelf.btnGoogle.enabled = YES;
                    [weakSelf loadSettings];
                }];
            } else {
                [weakSelf.aiLoading stopAnimating];
                weakSelf.btnCancel.hidden = YES;
                weakSelf.btnTwitter.enabled = YES;
                weakSelf.btnFacebook.enabled = YES;
                weakSelf.btnGoogle.enabled = YES;
                [weakSelf loadSettings];
            }
        }];
    }
}

- (void)btnCancel_TouchUpInside:(id)sender
{
    self.didCancel = YES;
    
    [self.aiLoading stopAnimating];
    self.btnCancel.hidden = YES;
    self.btnTwitter.enabled = YES;
    self.btnFacebook.enabled = YES;
    self.btnGoogle.enabled = YES;
    
    [self loadSettings];
}

#pragma mark - Twitter

- (void)twitterSignOut
{
    // i18n repetative use
    okString = NSLocalizedStringFromTable(@"OK", @"UserSettingsSub", @"OK");
    
    if (CurrentUser.accountType == 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"twitterUnpair", @"UserSettingsSub", @"Cannot Unpair")
                                                        message:NSLocalizedStringFromTable(@"twitterUnpairMsg", @"UserSettingsSub", @"You're currently signed into Veezy using your Twitter account.")
                                                       delegate:nil
                                              cancelButtonTitle:okString
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    OREpicUser *u = [OREpicUser new];
    u.userId = CurrentUser.userId;
    u.accountType = 1;
    
    [ApiEngine removePairing:u cb:^(NSError *error, BOOL result) {
        if (error || !result) {
            if (error) NSLog(@"Error: %@", error);
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:NSLocalizedStringFromTable(@"twitterUnpairTryAgain", @"UserSettingsSub", @"Unable to unpair the selected Twitter account. Please try again later.")
                                                           delegate:nil
                                                  cancelButtonTitle:okString
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
            [AppDelegate.twitterEngine resetOAuthToken];
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs removeObjectForKey:@"twitterDisabled"];
            [prefs removeObjectForKey:@"twitterToken"];
            [prefs removeObjectForKey:@"twitterTokenSecret"];
            [prefs removeObjectForKey:@"twitterUserId"];
            [prefs removeObjectForKey:@"twitterScreenName"];
            [prefs removeObjectForKey:@"twitterUserName"];
            [prefs synchronize];

            CurrentUser.twitterId = nil;
            CurrentUser.twitterToken = nil;
            CurrentUser.twitterSecret = nil;
            CurrentUser.twitterName = nil;
            [CurrentUser saveLocalUser];
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:NSLocalizedStringFromTable(@"twitterUnpairSuc", @"UserSettingsSub", @"Twitter Disconnected Successfully.")
                                                           delegate:nil
                                                  cancelButtonTitle:okString
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
        [self.aiLoading stopAnimating];
        self.btnCancel.hidden = YES;
        self.btnTwitter.enabled = YES;
        self.btnFacebook.enabled = YES;
        self.btnGoogle.enabled = YES;
        [self loadSettings];
    }];
}

#pragma mark - Facebook

- (void)facebookSignOut
{
    // i18n repetative use
    okString = NSLocalizedStringFromTable(@"OK", @"UserSettingsSub", @"OK");
    
    if (CurrentUser.accountType == 2) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"FBcantDisconnect", @"UserSettingsSub", @"Cannot Disconnect")
                                                        message:NSLocalizedStringFromTable(@"FBcantDisconnectMsg", @"UserSettingsSub", @"You're currently signed into Veezy using your Facebook account.")
                                                       delegate:nil
                                              cancelButtonTitle:okString
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }

    AppDelegate.isLinkingFacebook = YES;
    
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
													message:NSLocalizedStringFromTable(@"FBDisconnectSuc", @"UserSettingsSub", @"Facebook Disconnected Successfully.")
												   delegate:nil
										  cancelButtonTitle:okString
										  otherButtonTitles:nil];
	[alert show];

    if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        [FBSession.activeSession closeAndClearTokenInformation];
    } else {
        self.facebookName = nil;
        [self loadSettings];
    }
}

- (void)handleORFacebookSignedOut:(NSNotification *)n
{
    if (!self.isVisible || self.isSigningIn) return;
    
    if (self.didCancel) {
        NSLog(@"Facebook signed out, but user did cancel before");
        self.didCancel = NO;
        
        return;
    }
    
    NSLog(@"Facebook sign out handled by ORSocialConfigView");
    
    if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        [FBSession.activeSession closeAndClearTokenInformation];
    }
    
    OREpicUser *u = [OREpicUser new];
    u.userId = CurrentUser.userId;
    u.accountType = 2;
    
    [ApiEngine removePairing:u cb:^(NSError *error, BOOL result) {
        if (error || !result) {
            if (error) NSLog(@"Error: %@", error);
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"VeezyPairing", @"UserSettingsSub", @"Veezy")
                                                            message:NSLocalizedStringFromTable(@"VeezyPairingMsg", @"UserSettingsSub", @"Unable to unpair the selected Facebook account. Please try again later.")
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"UserSettingsSub", @"OK")
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
            CurrentUser.facebookId = nil;
            CurrentUser.facebookToken = nil;
            CurrentUser.facebookName = nil;
            CurrentUser.facebookTokenData = nil;
            [CurrentUser saveLocalUser];
            
            self.facebookName = nil;
        }
        
        [self.aiLoading stopAnimating];
        self.btnCancel.hidden = YES;
        self.btnTwitter.enabled = YES;
        self.btnFacebook.enabled = YES;
        self.btnGoogle.enabled = YES;
        [self loadSettings];
    }];
}

#pragma mark - Google

- (void)googleSignOut
{
    // i18n repetative use
    okString = NSLocalizedStringFromTable(@"OK", @"UserSettingsSub", @"OK");
    
    OREpicUser *u = [OREpicUser new];
    u.userId = CurrentUser.userId;
    u.accountType = 4;
    
    [ApiEngine removePairing:u cb:^(NSError *error, BOOL result) {
        if (error || !result) {
            if (error) NSLog(@"Error: %@", error);
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:NSLocalizedStringFromTable(@"GooUnpairFailedMsg", @"UserSettingsSub", @"Unable to unpair the selected Google account. Please try again later.")
                                                           delegate:nil
                                                  cancelButtonTitle:okString
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
            [AppDelegate.ge resetOAuthToken];
    
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs removeObjectForKey:@"googleToken"];
            [prefs removeObjectForKey:@"googleTokenSecret"];
            [prefs removeObjectForKey:@"googleUserID"];
            [prefs removeObjectForKey:@"googleUserEmail"];
            [prefs removeObjectForKey:@"googleUserName"];
            [prefs removeObjectForKey:@"googleProfilePicture"];
            [prefs synchronize];
            
            CurrentUser.googleToken = nil;
            CurrentUser.googleSecret = nil;
            [CurrentUser saveLocalUser];
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:NSLocalizedStringFromTable(@"GooUnpairSuc", @"UserSettingsSub", @"Google Disconnected Successfully.")
                                                           delegate:nil
                                                  cancelButtonTitle:okString
                                                  otherButtonTitles:nil];
            [alert show];
        }
    
        [self.aiLoading stopAnimating];
        self.btnCancel.hidden = YES;
        self.btnTwitter.enabled = YES;
        self.btnFacebook.enabled = YES;
        self.btnGoogle.enabled = YES;
        [self loadSettings];
    }];
}

- (void)googleEngine:(ORGoogleEngine *)engine needsToOpenURL:(NSURL *)url
{
    if (self.didCancel) {
        [self.aiLoading stopAnimating];
        self.btnCancel.hidden = YES;
        self.btnTwitter.enabled = YES;
        self.btnFacebook.enabled = YES;
        self.btnGoogle.enabled = YES;
        [self loadSettings];

        return;
    }
    
    ORWebView *wv = [[ORWebView alloc] initWithURL:url];
    wv.delegate = self;
    wv.callbackURL = AppDelegate.ge.callbackURL;
    
    ORNavigationController *nav = [[ORNavigationController alloc] initWithRootViewController:wv];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)googleEngine:(ORGoogleEngine *)engine statusUpdate:(NSString *)message
{
    NSLog(@"%@", message);
}

- (void)webView:(ORWebView *)webView didHitCallbackURL:(NSURL *)url
{
    [AppDelegate.ge resumeAuthenticationFlowWithURL:url];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)webView:(ORWebView *)webView didCancelWithError:(NSError *)error
{
    if (error) NSLog(@"Error: %@", error);
    
    [self.aiLoading stopAnimating];
    self.btnCancel.hidden = YES;
    self.btnTwitter.enabled = YES;
    self.btnFacebook.enabled = YES;
    self.btnGoogle.enabled = YES;
    [self loadSettings];

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // i18n repetative use
    okString = NSLocalizedStringFromTable(@"OK", @"UserSettingsSub", @"OK");
    
    switch (actionSheet.tag) {
        case 1: { // Twitter Sign In
            if (buttonIndex == actionSheet.cancelButtonIndex) {
                [self loadSettings];
                return;
            }
            
            if (buttonIndex < self.twitterAccounts.count) {
                NSLog(@"Authenticating with Twitter...");
                
                [self.aiLoading startAnimating];
                self.btnCancel.hidden = NO;
                self.didCancel = NO;
                self.btnFacebook.enabled = NO;
                self.btnTwitter.enabled = NO;
                self.btnGoogle.enabled = NO;
                
                [AppDelegate.twitterEngine reverseAuthWithAccount:self.twitterAccounts[buttonIndex] completion:^(NSError *error) {
                    if (self.didCancel) {
                        NSLog(@"Twitter signed in, but user did cancel before");
                        self.didCancel = NO;
                        
                        return;
                    }

                    if (error) {
                        [self.aiLoading stopAnimating];
                        self.btnCancel.hidden = YES;
                        self.btnTwitter.enabled = YES;
                        self.btnFacebook.enabled = YES;
                        self.btnGoogle.enabled = YES;
                        
                        NSLog(@"Error: %@", error);
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                        message:PAIRING_MESSAGE_TW_UNABLE_TO_USE_SELECTED_ACCOUNT
                                                                       delegate:nil
                                                              cancelButtonTitle:okString
                                                              otherButtonTitles:nil];
                        [alert show];
                        return;
                    }
                    
                    if (AppDelegate.twitterEngine.isAuthenticated) {
                        NSLog(@"Authenticated with Twitter as @%@", AppDelegate.twitterEngine.screenName);
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORTwitterPaired" object:nil];
                        
                        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                        [prefs removeObjectForKey:@"twitterDisabled"];
                        [prefs setObject:AppDelegate.twitterEngine.token forKey:@"twitterToken"];
                        [prefs setObject:AppDelegate.twitterEngine.tokenSecret forKey:@"twitterTokenSecret"];
                        [prefs setObject:AppDelegate.twitterEngine.userId forKey:@"twitterUserId"];
                        [prefs setObject:AppDelegate.twitterEngine.screenName forKey:@"twitterScreenName"];
                        [prefs setObject:AppDelegate.twitterEngine.userName forKey:@"twitterUserName"];
                        [prefs synchronize];
                        
                        CurrentUser.twitterId = AppDelegate.twitterEngine.userId;
                        CurrentUser.twitterToken = AppDelegate.twitterEngine.token;
                        CurrentUser.twitterSecret = AppDelegate.twitterEngine.tokenSecret;
                        CurrentUser.twitterName = AppDelegate.twitterEngine.screenName;
                        
                        OREpicUser *u = [OREpicUser new];
                        u.userId = CurrentUser.userId;
                        u.twitterId = CurrentUser.twitterId;
                        u.twitterToken = CurrentUser.twitterToken;
                        u.twitterSecret = CurrentUser.twitterSecret;
                        u.twitterName = CurrentUser.twitterName;
                        
                        [ApiEngine savePairing:u cb:^(NSError *error, BOOL result) {
                            if (self.didCancel) {
                                NSLog(@"Twitter signed in, but user did cancel before");
                                self.didCancel = NO;
                                
                                return;
                            }

                            if (error || !result) {
                                NSString *screenName = AppDelegate.twitterEngine.screenName;
                                [AppDelegate.twitterEngine resetOAuthToken];
                                
                                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                                [prefs removeObjectForKey:@"twitterDisabled"];
                                [prefs removeObjectForKey:@"twitterToken"];
                                [prefs removeObjectForKey:@"twitterTokenSecret"];
                                [prefs removeObjectForKey:@"twitterUserId"];
                                [prefs removeObjectForKey:@"twitterScreenName"];
                                [prefs removeObjectForKey:@"twitterUserName"];
                                [prefs synchronize];
                                
                                CurrentUser.twitterId = nil;
                                CurrentUser.twitterToken = nil;
                                CurrentUser.twitterSecret = nil;
                                CurrentUser.twitterName = nil;
                                
                                if (error) {
                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                                    message:PAIRING_MESSAGE_TW_UNABLE_TO_USE_SELECTED_ACCOUNT
                                                                                   delegate:nil
                                                                          cancelButtonTitle:okString
                                                                          otherButtonTitles:nil];
                                    [alert show];
                                } else if (!result) {
                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"@%@", screenName]
                                                                                    message:PAIRING_MESSAGE_TWACCOUNT_PAIRED_TO_OTHER_CCACCOUNT
                                                                                   delegate:nil
                                                                          cancelButtonTitle:okString    
                                                                          otherButtonTitles:nil];
                                    [alert show];
                                }
                            }
                            
                            [CurrentUser saveLocalUser];

                            [self.aiLoading stopAnimating];
                            self.btnCancel.hidden = YES;
                            self.btnTwitter.enabled = YES;
                            self.btnFacebook.enabled = YES;
                            self.btnGoogle.enabled = YES;
                            [self loadSettings];
                        }];
                    }
                }];
            }
            
            break;
        }
        case 2: { // Twitter Find Friends / Sign Out
            if (buttonIndex == actionSheet.cancelButtonIndex) return;
            
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                // Sign Out
                [self twitterSignOut];
            }

            break;
        }
        case 3: { // Facebook Sign Out
            if (buttonIndex == actionSheet.cancelButtonIndex) return;
            
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                // Sign Out
                [self facebookSignOut];
            }

            break;
        }
        case 4: { // Google Find Friends / Sign Out
            if (buttonIndex == actionSheet.cancelButtonIndex) return;
            
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                // Sign Out
                [self googleSignOut];
            }
            
            break;
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.twitterAccounts = nil;
}

@end
