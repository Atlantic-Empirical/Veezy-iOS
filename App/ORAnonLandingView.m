//
//  ORAnonLandingView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 8/19/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORAnonLandingView.h"
#import "ORStringHash.h"
#import "ORPermissionsEngine.h"
#import "ORPermissionsView.h"

@interface ORAnonLandingView ()

@end

@implementation ORAnonLandingView

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.screenName = @"AnonLanding";
    
    UIToolbar *blur = [[UIToolbar alloc] initWithFrame:self.view.bounds];
    blur.barTintColor = nil;
    blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blur.barStyle = UIBarStyleDefault;
    blur.alpha = 0.99f;
    [self.view insertSubview:blur atIndex:0];
    [blur addSubview:self.viewContent];
    
    self.blur = blur;
    self.btnSignIn.layer.cornerRadius = 2.0f;
}

- (void)closeWithSuccess:(BOOL)success
{
    if (success) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORUserSignedIn" object:nil userInfo:@{@"first_signin": @YES}];
    }
    
    [RVC dismissModalVC];
}

- (IBAction)btnSignIn_TouchUpInside:(id)sender
{
    [RVC presentSignInWithMessage:@"Sign-In" completion:^(BOOL success) {
        if (success) {
            [self closeWithSuccess:NO];
        }
    }];
}

- (IBAction)viewBg_TouchUpInside:(id)sender
{
    self.view.userInteractionEnabled = NO;
    [self.aiLoading startAnimating];
    
    NSString *oldId = (CurrentUser.accountType == 3) ? CurrentUser.userId : nil;
    
    CurrentUser = [OREpicUser new];
    CurrentUser.anonymousUserId = oldId;
    CurrentUser.name = [[UIDevice currentDevice] name];
    CurrentUser.password = [ORStringHash createSHA512:CurrentUser.name];
    CurrentUser.accountType = 3;
    CurrentUser.appName = APP_NAME;
    if (AppDelegate.firstAppRun) CurrentUser.justCreated = YES;
    
    [ApiEngine createUser:CurrentUser cb:^(NSError *error, OREpicUser *user) {
        [self.aiLoading stopAnimating];
        
        if (error || !user) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME message:@"An error occurred while trying to create an account. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            
            self.view.userInteractionEnabled = YES;
        } else {
            CurrentUser = user;
            [CurrentUser saveLocalUser];
            
            if ([[ORPermissionsEngine sharedInstance] needsPermissionView]) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORPermissionsViewDismissed:) name:@"ORPermissionsViewDismissed" object:nil];
                
                ORPermissionsView *pv = [ORPermissionsView new];
                [self presentViewController:pv animated:YES completion:nil];
            } else {
                [self closeWithSuccess:YES];
            }
        }
    }];
}

- (void)handleORPermissionsViewDismissed:(NSNotification *)n
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ORPermissionsViewDismissed" object:nil];
    [self closeWithSuccess:YES];
}

@end
