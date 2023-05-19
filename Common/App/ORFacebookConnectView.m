//
//  ORFacebookConnectView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 12/08/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORFacebookConnectView.h"
#import "ORFindCCFriendsView.h"
#import "ORContact.h"

@interface ORFacebookConnectView () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL didCancel;
@property (nonatomic, strong) NSString *facebookName;
@property (nonatomic, strong) NSString *facebookId;

@end

@implementation ORFacebookConnectView

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
	
	self.screenName = @"ConnectingFacebook";
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORFacebookSignedIn:) name:@"ORFacebookSignedIn" object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORFacebookSignedOut:) name:@"ORFacebookSignedOut" object:nil];
    
    self.viewContent.layer.cornerRadius = 2.0f;
    self.btnCancel.layer.cornerRadius = 2.0f;
    self.aiLoading.color = APP_COLOR_PRIMARY;
    
    if (CurrentUser.isFacebookAuthenticated) {
        if (self.shouldFindFriends) {
            [self findFriends];
        } else {
            if (self.completionBlock) self.completionBlock(YES);
            self.completionBlock = nil;
        }
    } else {
        [self startFacebookSignIn];
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

#pragma mark - Orientation

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Custom

- (void)startFacebookSignIn
{
    self.lblTitle.text = @"Connecting Facebook";
    AppDelegate.isLinkingFacebook = YES;
    self.didCancel = NO;
    
    [AppDelegate facebookSignInAllowLoginUI:YES];
}

- (void)btnCancel_TouchUpInside:(id)sender
{
    self.didCancel = YES;
    
    if (self.completionBlock) self.completionBlock(NO);
    self.completionBlock = nil;
}

- (void)signInWithFacebook
{
    OREpicUser *u = [OREpicUser new];
    u.accountType = 2;
    u.facebookToken = FBSession.activeSession.accessTokenData.accessToken;
    u.appName = APP_NAME;
    if (AppDelegate.firstAppRun) u.justCreated = YES;
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:FBSession.activeSession.accessTokenData.dictionary];
    if (data) u.facebookTokenData = [data base64EncodedString];
    
    [ApiEngine signInWithUser:u cb:^(NSError *error, OREpicUser *user) {
        if (self.didCancel) {
            NSLog(@"Facebook signed in, but user did cancel before");
            self.didCancel = NO;
            
            return;
        }
        
        if (error || !user) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook Sign-in"
                                                            message:PAIRING_MESSAGE_FB_UNABLE_TO_USE_SELECTED_ACCOUNT
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

- (void)pairFacebook
{
    CurrentUser.facebookName = self.facebookName;
    CurrentUser.facebookId = self.facebookId;
    CurrentUser.facebookToken = FBSession.activeSession.accessTokenData.accessToken;

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:FBSession.activeSession.accessTokenData.dictionary];
    if (data) CurrentUser.facebookTokenData = [data base64EncodedString];
    
    [CurrentUser saveLocalUser];
    
    OREpicUser *u = [OREpicUser new];
    u.userId = CurrentUser.userId;
    u.facebookId = CurrentUser.facebookId;
    u.facebookToken = CurrentUser.facebookToken;
    u.facebookName = CurrentUser.facebookName;
    u.facebookTokenData = CurrentUser.facebookTokenData;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORFacebookPaired" object:nil];
    
    [ApiEngine savePairing:u cb:^(NSError *error, BOOL result) {
        if (error || !result) {
            NSString *name = CurrentUser.facebookName;
            [FBSession.activeSession closeAndClearTokenInformation];
            
            CurrentUser.facebookName = nil;
            CurrentUser.facebookId = nil;
            CurrentUser.facebookToken = nil;
            CurrentUser.facebookTokenData = nil;
            
            if (error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                message:PAIRING_MESSAGE_FB_UNABLE_TO_USE_SELECTED_ACCOUNT
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            } else if (!result) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@", name]
                                                                message:PAIRING_MESSAGE_FBACCOUNT_PAIRED_TO_OTHER_CCACCOUNT
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

#pragma mark - Facebook Notifications

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
    
    NSLog(@"Facebook sign in handled by ORFacebookConnectView");
    
    if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        [FBRequestConnection startWithGraphPath:@"me?fields=id,name" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                self.facebookName = result[@"name"];
                self.facebookId = result[@"id"];
                
                if (CurrentUser) {
                    [self pairFacebook];
                } else {
                    [self signInWithFacebook];
                }
            } else {
                [FBSession.activeSession closeAndClearTokenInformation];
                if (self.completionBlock) self.completionBlock(NO);
                self.completionBlock = nil;
            }
        }];
    } else {
        if (self.completionBlock) self.completionBlock(NO);
        self.completionBlock = nil;
    }
}

- (void)handleORFacebookSignedOut:(NSNotification *)n
{
    if (self.didCancel) {
        NSLog(@"Facebook signed out, but user did cancel before");
        self.didCancel = NO;
        
        return;
    }
    
    NSLog(@"Facebook sign out handled by ORFacebookConnectView");
    
    if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        [FBSession.activeSession closeAndClearTokenInformation];
    }
    
    if (CurrentUser) {
        OREpicUser *u = [OREpicUser new];
        u.userId = CurrentUser.userId;
        u.accountType = 2;
        
        [ApiEngine removePairing:u cb:^(NSError *error, BOOL result) {
            if (error || !result) {
                if (error) NSLog(@"Error: %@", error);
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME
                                                                message:@"Unable to unpair the selected Facebook account. Please try again later."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
                CurrentUser.facebookId = nil;
                CurrentUser.facebookToken = nil;
                CurrentUser.facebookName = nil;
                CurrentUser.facebookTokenData = nil;
                [CurrentUser saveLocalUser];
            }
            
            if (self.completionBlock) self.completionBlock(NO);
            self.completionBlock = nil;
        }];
    } else {
        if (self.completionBlock) self.completionBlock(NO);
        self.completionBlock = nil;
    }
}

- (void)findFriends
{
    if (self.didCancel) {
        NSLog(@"Trying to load friends, but user did cancel before");
        self.didCancel = NO;
        
        return;
    }

    self.lblTitle.text = @"Loading Friends";

    __weak ORFacebookConnectView *weakSelf = self;
    
    [[ORDataController sharedInstance] facebookContactsForceReload:YES cacheOnly:NO completion:^(NSError *error, NSMutableOrderedSet *items) {
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
        } else {
            if (weakSelf.completionBlock) weakSelf.completionBlock(YES);
            weakSelf.completionBlock = nil;
        }
    }];
}

@end
