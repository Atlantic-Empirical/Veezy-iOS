//
//  ORTwitterConnectView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 12/08/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORTwitterConnectView.h"
#import "ORFindCCFriendsView.h"
#import "ORContact.h"

@interface ORTwitterConnectView () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UIActionSheetDelegate>

@property (nonatomic, assign) BOOL firstLoad;
@property (nonatomic, assign) BOOL didCancel;
@property (nonatomic, strong) NSArray *twitterAccounts;

@end

@implementation ORTwitterConnectView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;
    
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.transitioningDelegate = self;
    self.shouldFindFriends = YES;

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.screenName = @"ConnectingTwitter";
	
    self.viewContent.layer.cornerRadius = 2.0f;
    self.btnCancel.layer.cornerRadius = 2.0f;
    self.aiLoading.color = APP_COLOR_PRIMARY;
    self.firstLoad = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.firstLoad) {
        self.firstLoad = NO;
        
        if (CurrentUser.isTwitterAuthenticated) {
            if (self.shouldFindFriends) {
                [self findFriends];
            } else {
                if (self.completionBlock) self.completionBlock(YES);
                self.completionBlock = nil;
            }
        } else {
            [self startTwitterSignIn];
        }
    }
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

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Custom

- (void)startTwitterSignIn
{
    self.lblTitle.text = @"Connecting Twitter";
    self.didCancel = NO;
    
    [AppDelegate.twitterEngine existingAccountsWithCompletion:^(NSError *error, NSArray *items) {
        if (error) NSLog(@"Error: %@", error);
        
        if (items.count > 0) {
            self.twitterAccounts = items;
            UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Select a Twitter account to use with %@:", APP_NAME] delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            sheet.tag = 1;
            
            for (ACAccount *account in items) {
                [sheet addButtonWithTitle:account.accountDescription];
            }
            
            sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
            [sheet showInView:self.view];
        } else {
            if (error && error.code == 403) {
                // Not authorized
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Access to Twitter denied"
                                                                message:[NSString stringWithFormat:@"Please authorize %@ to use your Twitter accounts in iOS Settings > Twitter then try again.", APP_NAME]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
                // No accounts
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Twitter Account"
                                                                message:@"It seems there are no Twitter accounts connected on this device - add one in iOS Settings > Twitter then try again."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }

            if (self.completionBlock) self.completionBlock(NO);
            self.completionBlock = nil;
        }
    }];
}

- (void)twitterAccountSelected:(NSUInteger)idx
{
    self.didCancel = NO;
    
    [AppDelegate.twitterEngine reverseAuthWithAccount:self.twitterAccounts[idx] completion:^(NSError *error) {
        if (self.didCancel) {
            NSLog(@"Twitter signed in, but user did cancel before");
            self.didCancel = NO;
            
            return;
        }
        
        if (error) {
            NSLog(@"Error: %@", error);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:PAIRING_MESSAGE_TW_UNABLE_TO_USE_SELECTED_ACCOUNT
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
            if (self.completionBlock) self.completionBlock(NO);
            self.completionBlock = nil;

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
            
            if (CurrentUser) {
                [self pairTwitter];
            } else {
                [self signInWithTwitter];
            }
        }
    }];
}

- (void)signInWithTwitter
{
    OREpicUser *u = [OREpicUser new];
    u.accountType = 1;
    u.twitterToken = AppDelegate.twitterEngine.token;
    u.twitterSecret = AppDelegate.twitterEngine.tokenSecret;
    u.twitterName = AppDelegate.twitterEngine.screenName;
    u.appName = APP_NAME;
    if (AppDelegate.firstAppRun) u.justCreated = YES;
    
    [ApiEngine signInWithUser:u cb:^(NSError *error, OREpicUser *user) {
        if (self.didCancel) {
            NSLog(@"Twitter signed in, but user did cancel before");
            self.didCancel = NO;
            
            return;
        }
        
        if (error || !user) {
            [AppDelegate.twitterEngine resetOAuthToken];
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs removeObjectForKey:@"twitterDisabled"];
            [prefs removeObjectForKey:@"twitterToken"];
            [prefs removeObjectForKey:@"twitterTokenSecret"];
            [prefs removeObjectForKey:@"twitterUserId"];
            [prefs removeObjectForKey:@"twitterScreenName"];
            [prefs removeObjectForKey:@"twitterUserName"];
            [prefs synchronize];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Twitter Sign-in"
                                                            message:@"Unable to Sign-in with that Twitter account. Please try again or use another account."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
            if (self.completionBlock) self.completionBlock(NO);
            self.completionBlock = nil;
        } else {
            CurrentUser = user;
            
            if (PUSH_ENABLED && ApiEngine.currentDeviceId && ![CurrentUser.deviceID isEqualToString:ApiEngine.currentDeviceId]) {
                CurrentUser.deviceID = ApiEngine.currentDeviceId;
                [ApiEngine updateDeviceId:CurrentUser.deviceID forUser:CurrentUser.userId cb:nil];
            }
            
            [CurrentUser saveLocalUser];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORUserSignedIn" object:nil userInfo:@{@"first_signin": @YES}];

            if (self.shouldFindFriends) {
                [self findFriends];
            } else {
                if (self.completionBlock) self.completionBlock(YES);
                self.completionBlock = nil;
            }
        }
    }];
}

- (void)pairTwitter
{
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
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            } else if (!result) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"@%@", screenName]
                                                                message:PAIRING_MESSAGE_TWACCOUNT_PAIRED_TO_OTHER_CCACCOUNT
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }
        
        [CurrentUser saveLocalUser];
        
        if (result) {
            if (self.shouldFindFriends) {
                [self findFriends];
            } else {
                if (self.completionBlock) self.completionBlock(YES);
                self.completionBlock = nil;
            }
        } else {
            if (self.completionBlock) self.completionBlock(NO);
            self.completionBlock = nil;
        }
    }];
}

- (void)btnCancel_TouchUpInside:(id)sender
{
    self.didCancel = YES;
    
    if (self.completionBlock) self.completionBlock(NO);
    self.completionBlock = nil;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case 1: { // Twitter Sign In
            if (buttonIndex == actionSheet.cancelButtonIndex) {
                if (self.completionBlock) self.completionBlock(NO);
                self.completionBlock = nil;

                return;
            }
            
            if (buttonIndex < self.twitterAccounts.count) {
                [self twitterAccountSelected:buttonIndex];
            }
            
            break;
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.twitterAccounts = nil;
}

- (void)findFriends
{
    if (self.didCancel) {
        NSLog(@"Trying to load friends, but user did cancel before");
        self.didCancel = NO;
        
        return;
    }

    self.lblTitle.text = @"Loading Friends";

    __weak ORTwitterConnectView *weakSelf = self;
    
    [[ORDataController sharedInstance] twitterContactsForceReload:YES cacheOnly:NO completion:^(NSError *error, NSMutableOrderedSet *items) {
        if (error) NSLog(@"Error: %@", error);
        if (weakSelf.didCancel) return;
        
        if (items && weakSelf) {
            NSMutableArray *following = [NSMutableArray arrayWithCapacity:1];
            NSMutableArray *notFollowing = [NSMutableArray arrayWithCapacity:1];
            NSMutableArray *other = [NSMutableArray arrayWithCapacity:1];
            NSOrderedSet *friends = CurrentUser.following;
            
            for (ORContact *contact in items) {
                if (contact.user) {
                    if ([contact.user.userId isEqualToString:CurrentUser.userId]) continue;
                    if (!contact.user.profileImageUrl) contact.user.profileImageUrl = contact.imageURL;
                    
                    if ([friends containsObject:contact.user]) {
                        [following addObject:contact.user];
                    } else {
                        [notFollowing addObject:contact.user];
                    }
                } else {
                    [other addObject:contact];
                }
            }
            
            if (notFollowing.count > 0 || other.count > 0) {
                ORFindCCFriendsView *vc = [[ORFindCCFriendsView alloc] initWithNotFollowing:notFollowing andFollowing:following andContacts:other];
                [vc setCompletionBlock:^(BOOL followed) {
                    [weakSelf dismissViewControllerAnimated:YES completion:^{
                        if (weakSelf.completionBlock) weakSelf.completionBlock(YES);
                        weakSelf.completionBlock = nil;
                    }];
                }];
                
                [weakSelf presentViewController:vc animated:YES completion:nil];
            } else {
                if (weakSelf.completionBlock) weakSelf.completionBlock(YES);
                weakSelf.completionBlock = nil;
            }
        }
    }];
}

@end
