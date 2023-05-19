//
//  ORRootViewController.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 12/24/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import "ORRootViewController.h"
#import "ORSignInViewController.h"
#import "ORNotificationView.h"
#import "ORCaptureView.h"
#import "ORNavigationView.h"
#import "ORWatchView.h"
#import "ORPostCaptureView.h"
#import "ORUserProfileView.h"
#import "ORNavigationController.h"
#import "ORSubscriptionController.h"
#import "ORFaspPersistentEngine.h"
#import "ORUserFeedView.h"
#import "ORCapturePreview.h"
#import "ORAddEmailView.h"
#import "ORVerifyEmailView.h"
#import "AddressBook.h"
#import "ORPendingVideosView.h"
#import "ORAddressBookNudgeView.h"
#import "ORInviteFriendsNudgeView.h"
#import "ORFacebookNudgeView.h"
#import "ORTwitterNudgeView.h"
#import "ORPushNudgeView.h"
#import "ORAnonLandingView.h"
#import "ORExpiringVideoView.h"
#import "ORPermissionsEngine.h"
#import "ORPermissionsView.h"
#import "ORPreCaptureView.h"

#define NUDGE_CELLS_TO_SHOW 1
#define DAYS_SHOW_EMAIL_ADD 2
#define DAYS_SHOW_EMAIL_VERIFY 2
#define TOP_PADDING 40.0f

@interface ORRootViewController () <UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, assign) BOOL isSignedIn;
@property (nonatomic, assign) BOOL shouldDisplaySignIn;
@property (nonatomic, assign) BOOL isAlreadyVisible;
@property (nonatomic, assign) BOOL askedForLocation;

@property (nonatomic, strong) NSArray *twitterAccounts;

@property (nonatomic, strong) ORNavigationView *navigationView;
@property (nonatomic, strong) ORNavigationController *mainView;
@property (nonatomic, strong) ORNotificationView *notificationView;
@property (nonatomic, strong) ORPreCaptureView *preCaptureView;
@property (nonatomic, strong) UIViewController *modalVC;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *lblOffline;

@property (nonatomic, strong) NSDictionary *pendingNotification;
@property (nonatomic, strong) NSURL *pendingURL;

@property (nonatomic, strong) ORNavigationController *pcv;
@property (readwrite, assign) ORUIState currentState;

@property (nonatomic, strong) NSMutableDictionary *eventLastDisplayedDates;

@property (nonatomic, assign) double uploadBitrateMax;
@property (nonatomic, assign) double uploadBitrateMin;
@property (nonatomic, assign) double uploadBitrateAvg;
@property (nonatomic, strong) UIAlertView *alertView;

@property (nonatomic, assign) BOOL didAutoHide;
@property (nonatomic, assign) BOOL pendingVideosVisible;
@property (nonatomic, assign) BOOL shouldUpdateFacebookPairing;
@property (nonatomic, strong) ORPendingVideosView *pendingVideos;
@property (nonatomic, strong) NSMutableArray *nudgeViews;

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, assign) BOOL alerted;

@end

@implementation ORRootViewController

- (void)dealloc
{
    self.alertView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
    self = [super init];
    if (!self) return nil;
    
    self.currentSupportedOrientations = UIInterfaceOrientationMaskAllButUpsideDown;

    return self;
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self registerForNotifications];
    
    self.contentView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.contentView];

//	// Launch Screen Match
//	self.launchMatchView = [ORLaunchScreenMatchRevealView new];
//	self.launchMatchView.view.frame = self.view.bounds;
//	[self.view addSubview:self.launchMatchView.view];
	
    // Events
    NSString *file = [[ORUtility documentsDirectory] stringByAppendingPathComponent:@"eventdates.dat"];
    self.eventLastDisplayedDates = [[NSKeyedUnarchiver unarchiveObjectWithFile:file] mutableCopy];
    if (!self.eventLastDisplayedDates) self.eventLastDisplayedDates = [NSMutableDictionary dictionary];
	
    // Status bar is visible by default
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
 
    // Set main app state
    self.currentState = ORUIStateCamera;

    // Initialize Capture
    self.captureView = [ORCaptureView new];
    [self addChildViewController:self.captureView];
    [self.captureView.view setFrame:self.contentView.bounds];
    [self.contentView addSubview:self.captureView.view];
    [self.captureView didMoveToParentViewController:self];
    
    // Initialize Navigation
    self.navigationView = [ORNavigationView new];
    [self addChildViewController:self.navigationView];
    [self.navigationView.view setFrame:self.contentView.bounds];
    [self.contentView addSubview:self.navigationView.view];
    [self.navigationView didMoveToParentViewController:self];

    // Initialize Pre-Capture
    self.preCaptureView = [ORPreCaptureView new];
    [self addChildViewController:self.preCaptureView];
    CGRect f = self.contentView.bounds;
    f.size.height -= CGRectGetHeight(self.navigationView.viewMainNav.frame);
    [self.preCaptureView.view setFrame:f];
    [self.contentView insertSubview:self.preCaptureView.view aboveSubview:self.captureView.view];
    [self.preCaptureView didMoveToParentViewController:self];

//    // Add blur over the camera
//    // http://stackoverflow.com/questions/17055740/how-can-i-produce-an-effect-similar-to-the-ios-7-blur-view
//    self.blurView = [[UIToolbar alloc] initWithFrame:self.view.bounds];
//    self.blurView.barTintColor = nil;
//    self.blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    self.blurView.barStyle = UIBarStyleDefault;
//    self.blurView.alpha = 0.99f;
//    [self.view insertSubview:self.blurView belowSubview:self.launchMatchView.view];
    
    // Notifications
//    self.notificationsTable = [ORNotificationsTable new];
//    [self addChildViewController:self.notificationsTable];
//    CGRect f = self.contentView.bounds;
//    f.origin.y = f.size.height;
//    self.notificationsTable.view.frame = f;
//    [self.contentView addSubview:self.notificationsTable.view];
//    [self.notificationsTable didMoveToParentViewController:self];
    
    // Pending Videos
    self.pendingVideos = [ORPendingVideosView new];
    [self addChildViewController:self.pendingVideos];
    self.pendingVideos.view.frame = CGRectMake(10.0f, -60.0f, 300.0f, 60.0f);
    self.pendingVideos.view.hidden = YES;
    [self.contentView insertSubview:self.pendingVideos.view aboveSubview:self.preCaptureView.view];
    [self.pendingVideos didMoveToParentViewController:self];

    // Tab Bar
//    UITabBarController *tabBar = [[UITabBarController alloc] init];
//    ORHomeView *home = [ORHomeView new];
//    ORDiscoveryParentView *discovery = [ORDiscoveryParentView new];
//    ORProfileView *profile = [ORProfileView new];
//    [tabBar setViewControllers:@[home, discovery, people, profile]];

    if (CurrentUser) {
        ApiEngine.currentUserID = CurrentUser.userId;
    }

	[self loadCurrentUser];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self configureForOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0.0f];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!self.isAlreadyVisible && CurrentUser) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORUserSignedIn" object:nil];
    }

    self.screenName = @"RVC";
    self.isAlreadyVisible = YES;
    
    if (self.shouldDisplaySignIn) {
		[self presentSignInDialog];
	} else {
        // Handle any pending notifications / URLs
        if (self.pendingNotification) [self handleNotification:self.pendingNotification];
        if (self.pendingURL) [self handleURL:self.pendingURL];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORPausePlayerSOFT" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Custom

- (CGFloat)bottomMargin
{
    return CGRectGetHeight(self.navigationView.viewMainNav.frame);
}

- (void)setOfflineBannerVisible:(BOOL)visible
{
    if (visible) {
        if (!self.lblOffline) {
            self.lblOffline = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 20.0f, self.view.frame.size.width, 20.0f)];
            self.lblOffline.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
            self.lblOffline.backgroundColor = [UIColor redColor];
            self.lblOffline.textColor = [UIColor whiteColor];
            self.lblOffline.text = @"OFFLINE";
            self.lblOffline.textAlignment = NSTextAlignmentCenter;
            self.lblOffline.font = [UIFont systemFontOfSize:12.0f];
            self.lblOffline.alpha = 0.6f;
            [self.view insertSubview:self.lblOffline aboveSubview:self.navigationView.view];
        }
    } else {
        [self.lblOffline removeFromSuperview];
        self.lblOffline = nil;
    }
}

- (void)resetMainViewWith:(UIViewController *)vc completion:(void (^)())completion
{
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        [AppDelegate forcePortrait];
        [AppDelegate unlockOrientation];
    }
    
    [self hideMenu];
    [AppDelegate nativeBarAppearance_default];
    
    if (self.currentState == ORUIStateMainInterface) {
//        [self.mainView.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        [self.mainView setViewControllers:@[vc]];
        if (completion) completion();
    } else {
        if (self.mainView) {
            [self.mainView willMoveToParentViewController:nil];
            [self.mainView.view removeFromSuperview];
            [self.mainView removeFromParentViewController];
            self.mainView = nil;
        }
        
        // Reinitialize Main View
        self.mainView = [[ORNavigationController alloc] initWithRootViewController:vc];
        [self addChildViewController:self.mainView];
        
        CGRect f = self.contentView.bounds;
        f.size.height -= CGRectGetHeight(self.navigationView.viewMainNav.frame);
        [self.mainView.view setFrame:f];
        
        [self.mainView.view setAlpha:0.0f];
        [self.contentView insertSubview:self.mainView.view belowSubview:self.navigationView.view];
        [self.mainView didMoveToParentViewController:self];
        
        [self showMainInterfaceWithCompletion:completion];
    }
}

- (void)pushToMainViewController:(UIViewController *)vc completion:(void (^)())completion
{
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        [AppDelegate forcePortrait];
        [AppDelegate unlockOrientation];
    }
    
    [self hideMenu];
	[AppDelegate nativeBarAppearance_default];
    
    if (self.currentState == ORUIStateMainInterface) {
        [self.mainView pushViewController:vc animated:YES];
        if (completion) completion();
    } else {
        if (self.mainView) {
            [self.mainView willMoveToParentViewController:nil];
            [self.mainView.view removeFromSuperview];
            [self.mainView removeFromParentViewController];
            self.mainView = nil;
        }
        
        // Reinitialize Main View
        self.mainView = [[ORNavigationController alloc] initWithRootViewController:vc];
        [self addChildViewController:self.mainView];

        CGRect f = self.contentView.bounds;
        f.size.height -= CGRectGetHeight(self.navigationView.viewMainNav.frame);
        [self.mainView.view setFrame:f];

        [self.mainView.view setAlpha:0.0f];
        [self.contentView insertSubview:self.mainView.view belowSubview:self.navigationView.view];
        [self.mainView didMoveToParentViewController:self];
        
        [self showMainInterfaceWithCompletion:completion];
    }
}

- (void)presentVCModally:(UIViewController *)vc
{
    if (self.modalVC) {
        [self.modalVC willMoveToParentViewController:nil];
        [self.modalVC.view removeFromSuperview];
        [self.modalVC removeFromParentViewController];

        self.modalVC = nil;
    }
    
    self.modalVC = vc;
    [AppDelegate forcePortrait];
    
    [self addChildViewController:self.modalVC];
    self.modalVC.view.frame = self.contentView.bounds;
    self.modalVC.view.alpha = 0.0f;
    [self.contentView addSubview:self.modalVC.view];
    [self.modalVC didMoveToParentViewController:self];
    
    [self.captureView.view bringSubviewToFront:self.captureView.viewVideoPreview];
    [self hideAllNudges];
    
    if ([self.modalVC isKindOfClass:[ORAnonLandingView class]]) {
        ORAnonLandingView *anon = (ORAnonLandingView *)self.modalVC;
        anon.view.alpha = 1.0f;
        anon.blur.alpha = 0;
        
        [UIView animateWithDuration:0.3f animations:^{
            anon.blur.alpha = 1.0f;
        }];
    } else {
        [UIView animateWithDuration:0.3f animations:^{
            self.modalVC.view.alpha = 1.0f;
        }];
    }
}

- (void)dismissModalVC
{
    [self.captureView.view sendSubviewToBack:self.captureView.viewVideoPreview];

    if ([self.modalVC isKindOfClass:[ORAnonLandingView class]]) {
        ORAnonLandingView *anon = (ORAnonLandingView *)self.modalVC;

        [UIView animateWithDuration:0.3f animations:^{
            anon.blur.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [self.modalVC willMoveToParentViewController:nil];
            [self.modalVC.view removeFromSuperview];
            [self.modalVC removeFromParentViewController];
            self.modalVC = nil;
            [AppDelegate unlockOrientation];
        }];
    } else {
        [UIView animateWithDuration:0.3f animations:^{
            self.modalVC.view.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [self.modalVC willMoveToParentViewController:nil];
            [self.modalVC.view removeFromSuperview];
            [self.modalVC removeFromParentViewController];
            [AppDelegate unlockOrientation];
        }];
    }
}

- (void)presentModalVC:(UIViewController *)vc
{
    if (self.presentedViewController) {
        [self.presentedViewController presentViewController:vc animated:YES completion:nil];
    } else {
        [self presentViewController:vc animated:YES completion:nil];
    }
}

- (void)showMainInterfaceWithCompletion:(void (^)())completion
{
    if (self.currentState == ORUIStateMainInterface) {
        if (completion) completion();
        return;
    }

    [self showNormalStatusBar];
	[AppDelegate nativeBarAppearance_default];
    
    if (!self.mainView) {
        // Initialize Main View
        self.mainView = [[ORNavigationController alloc] initWithRootViewController:[ORUserFeedView new]];
        [self addChildViewController:self.mainView];
        
        CGRect f = self.contentView.bounds;
        f.size.height -= CGRectGetHeight(self.navigationView.viewMainNav.frame);
        [self.mainView.view setFrame:f];
        
        [self.mainView.view setAlpha:0.0f];
        [self.contentView insertSubview:self.mainView.view belowSubview:self.navigationView.view];
        [self.mainView didMoveToParentViewController:self];
    }

    CGRect f = self.contentView.bounds;
    f.origin.y = f.size.height;
    f.size.height -= CGRectGetHeight(self.navigationView.viewMainNav.frame);

    self.currentState = ORUIStateMainInterface;
    self.mainView.view.alpha = 1.0f;
    self.mainView.view.frame = f;
    
    f.origin.y = 0;
    
    [UIView animateWithDuration:0.2f animations:^{
        self.navigationView.viewMainNav.backgroundColor = APP_COLOR_PRIMARY_ALPHA(1.0f);
        self.mainView.view.frame = f;
    } completion:^(BOOL finished) {
        [self.captureView performSelector:@selector(stopPreview) withObject:nil afterDelay:60.0f];
        if (completion) completion();
    }];
}

- (void)showCamera
{
    [self showCamera:NO];
}

- (void)showCamera:(BOOL)automatic
{
    if (self.currentState == ORUIStateCamera) return;
    
    CGRect f = self.contentView.bounds;
    f.origin.y = f.size.height;
    f.size.height -= CGRectGetHeight(self.navigationView.viewMainNav.frame);
    
    self.currentState = ORUIStateCamera;
    self.didAutoHide = automatic;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self.captureView selector:@selector(stopPreview) object:nil];
    [self.captureView startPreview];
    
    [UIView animateWithDuration:0.2f animations:^{
        self.navigationView.viewMainNav.backgroundColor = APP_COLOR_PRIMARY_ALPHA(0.9f);
        self.mainView.view.frame = f;
    } completion:^(BOOL finished) {
        if (!self.didAutoHide) {
            [self.mainView willMoveToParentViewController:nil];
            [self.mainView.view removeFromSuperview];
            [self.mainView removeFromParentViewController];
            self.mainView = nil;
        }
    }];
}

- (void)ShowCameraNotAnimated
{
    self.currentState = ORUIStateCamera;

    [NSObject cancelPreviousPerformRequestsWithTarget:self.captureView selector:@selector(stopPreview) object:nil];
    [self.captureView startPreview];
    
    self.navigationView.viewMainNav.backgroundColor = APP_COLOR_PRIMARY_ALPHA(0.9f);

    [self.mainView willMoveToParentViewController:nil];
    [self.mainView.view removeFromSuperview];
    [self.mainView removeFromParentViewController];
    self.mainView = nil;
}

- (void)showMenu
{
	[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

- (void)hideMenu
{
	[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

- (void)showNormalStatusBar
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)startPreview
{
    [self.captureView startPreview];
}

- (void)stopPreview
{
    [self.captureView stopPreview];
}

- (void)presentPCVWithVideo:(OREpicVideo *)video andPlaces:(NSArray *)places force:(BOOL)force
{
//    if (!force && CurrentUser.totalVideoCount == 1) {
//        ORMessageOverlayView *vc = [[ORMessageOverlayView alloc] initWithTitle:@"Awesome!"
//                                                                             message:@"You've created your first video and it's already saved to the cloud."
//                                                                         buttonTitle:@"Okay"];
//        
//        __weak ORRootViewController *weakSelf = self;
//        [self.captureView.view bringSubviewToFront:self.captureView.viewVideoPreview];
//        
//        [vc presentInViewController:self completion:^{
//            [weakSelf.captureView.view sendSubviewToBack:weakSelf.captureView.viewVideoPreview];
//            [weakSelf presentPCVWithVideo:video andPlaces:places force:YES];
//        }];
//    } else {
        [AppDelegate forcePortraitWithCompletion:^{
            if (self.didAutoHide && self.mainView) {
                self.didAutoHide = NO;
                [self showMainInterfaceWithCompletion:nil];
            }
            
            ORPostCaptureView *vc = [[ORPostCaptureView alloc] initWithVideo:video andPlaces:places];
            self.pcv = [[ORNavigationController alloc] initWithRootViewController:vc];
            
            self.pcv.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:self.pcv animated:YES completion:nil];
        }];
//    }
}

- (void)dismissPCVWithCompletion:(void (^)())completion;
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (completion) completion();
        self.pcv = nil;
        [AppDelegate unlockOrientation];
    }];
}

#pragma mark - Orientation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self configureForOrientation:toInterfaceOrientation duration:duration];
}

- (void)configureForOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        self.alerted = YES;
        [self stopMotionDetect];
        
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        self.pendingVideos.view.alpha = 0;
        self.navigationView.view.alpha = 0;
        self.preCaptureView.view.alpha = 0;
        
        for (ORNudgeView *nudge in self.nudgeViews) {
            nudge.view.alpha = 0.0f;
        }

        [self hideMenu];
        
        if (![self.mainView.topViewController isKindOfClass:[ORWatchView class]]) {
            [self.view endEditing:YES];
            
            if (self.currentState != ORUIStateCamera) {
                [self showCamera:YES];
            }
            
            if (!AppDelegate.isAllowedToUseLocationManager) {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                BOOL askedAlready = [defaults boolForKey:@"askedForLocation"];
                if (!askedAlready && !self.askedForLocation) {
                    self.askedForLocation = YES;
                    [self requestLocationPermissionFromUser];
                } else if (askedAlready && !self.askedForLocation) {
                    self.askedForLocation = YES;
                    [self requestLocationPermissionFromOS];
                }
            }
        } else {
            if (self.currentState == ORUIStateMainInterface) {
                self.mainView.view.frame = self.contentView.bounds;
            }
        }
    } else {
        self.navigationView.view.alpha = 1.0f;
        self.preCaptureView.view.alpha = 1.0f;

        if (AppDelegate.isRecording) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            self.pendingVideos.view.alpha = 0.0f;

            for (ORNudgeView *nudge in self.nudgeViews) {
                nudge.view.alpha = 0.0f;
            }
        } else {
            [[UIApplication sharedApplication] setStatusBarHidden:NO];
            self.pendingVideos.view.alpha = 1.0f;
            
            for (ORNudgeView *nudge in self.nudgeViews) {
                nudge.view.alpha = 1.0f;
            }
            
            if (self.didAutoHide && self.mainView) {
                self.didAutoHide = NO;
                [self showMainInterfaceWithCompletion:nil];
            }
            
            if (self.currentState == ORUIStateMainInterface) {
                CGRect f = self.contentView.bounds;
                f.size.height -= CGRectGetHeight(self.navigationView.viewMainNav.frame);
                [self.mainView.view setFrame:f];
            }
        }
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    return self.currentSupportedOrientations;
}

#pragma mark - SignIn

- (void)presentSignInDialog
{
    if (!self.isAlreadyVisible) {
        self.shouldDisplaySignIn = YES;
        return;
    }
    
//    // First, let's check for cold start view
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    BOOL cs = [defaults boolForKey:@"coldStart"];
//    
//    if (!cs) {
//        self.shouldDisplaySignIn = NO;
//        
//        self.coldStart = [ORColdStartView new];
//        self.coldStart.parentView = self;
//        self.coldStart.firstTime = YES;
//        self.coldStart.view.frame = self.view.bounds;
//
//        [UIView transitionFromView:self.view
//        					toView:self.coldStart.view
//        				  duration:1
//        				   options:UIViewAnimationOptionTransitionFlipFromTop
//        				completion:nil];
//        
//        return;
//    }
	
    self.shouldDisplaySignIn = NO;
    
	self.mainView.view.hidden = YES;
    
    if (PUSH_ENABLED && CurrentUser.userId) {
        [ApiEngine updateDeviceId:nil forUser:CurrentUser.userId cb:nil];
    }
    
    AppDelegate.isSignedIn = NO;
    CurrentUser = nil;
    [OREpicUser removeUserFromLocalStorage];
    [self handleORUpdateBadge:nil];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    ORAnonLandingView *anon = [ORAnonLandingView new];
    [anon view];
    
    [self presentVCModally:anon];
}

- (void)loadCurrentUser
{
    if (CurrentUser) {
		if (CurrentUser.accountType == 3 && CurrentUser.totalVideoCount > 0) {
			self.alertView = [[UIAlertView alloc] initWithTitle:@"Trial Account"
															message:@"You are using Veezy with an trial account. If you delete the app or sign-out you will have no way to retrieve the videos you've shot."
														   delegate:self
												  cancelButtonTitle:@"Continue"
												  otherButtonTitles:@"Sign-in Now", nil];
			self.alertView.tag = 1;
			[self.alertView show];
		}
		
        if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
            NSLog(@"Opening Facebook session...");
            
            [AppDelegate facebookSignInAllowLoginUI:NO];            
            if (CurrentUser.accountType == 2) return;
        }

        [ApiEngine signInWithUser:CurrentUser cb:^(NSError *error, OREpicUser *userSignedIn) {
            if (error) {
                NSLog(@"Sign-In error: %@", error);
                ApiEngine.currentUserID = CurrentUser.userId;
                [self innerCompleteUserLoad];
            } else {
                if (userSignedIn) {
                    if (CurrentUser) {
                        [CurrentUser updateWithUser:userSignedIn];
                    } else {
                        CurrentUser = userSignedIn;
                    }
                    [self innerCompleteUserLoad];
                } else {
                    NSLog(@"Authentication failure: %@", CurrentUser);
                    
                    // Authentication failure
                    [self handleORUserSignedOut:nil];
                }
            }
        }];
    } else {
        NSLog(@"No local user, will present sign-in");
        [self presentSignInDialog];
    }
}

- (void)innerCompleteUserLoad
{
	[CurrentUser saveLocalUser];
    [self handleORUpdateBadge:nil];
    
    [[ORFaspPersistentEngine sharedInstance] parseToken:CurrentUser.faspToken];
    
    if (!AppDelegate.pushNotificationsEnabled && CurrentUser.followersCount > 0) {
        // Existing user, probably migration from CC -> Veezy, request push permissions again
        [AppDelegate registerForPushNotifications];
    }
    
    if (CurrentUser.feedCount > 0) [[ORDataController sharedInstance] invalidateFeedCache];
    if (CurrentUser.notificationCount > 0) [[ORDataController sharedInstance] invalidateNotificationCache];
    
    ApiEngine.needsSessionStart = NO;
    [ApiEngine startSessionWithCB:^(NSError *error, NSString *result) {
        ApiEngine.needsSessionStart = (error != nil);
    }];
    
    if (ApiEngine.currentNetworkStatus != NotReachable && CurrentUser.accountType != 3) {
        // IAP
        if (!ORIsEmpty(CurrentUser.pendingSubscription)) {
            [[ORSubscriptionController sharedInstance] validateUserSubscription];
        }
        
        if (ORIsEmpty(CurrentUser.emailAddress) && !CurrentUser.justCreated && UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSDate *lastAskedForEmail = [defaults objectForKey:@"lastAskedForEmail"];

            if (!lastAskedForEmail || [[NSDate date] timeIntervalSinceDate:lastAskedForEmail] > (DAYS_SHOW_EMAIL_ADD * 86400)) {
                lastAskedForEmail = [NSDate date];
                [defaults setObject:lastAskedForEmail forKey:@"lastAskedForEmail"];
                [defaults synchronize];
                
                // Add Email
                ORAddEmailView *vc = [ORAddEmailView new];
                [self presentModalVC:vc];
            }
        } else if (!CurrentUser.verified && !CurrentUser.justCreated && UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSDate *lastVerifiedEmail = [defaults objectForKey:@"lastVerifiedEmail"];
            
            if (!lastVerifiedEmail || [[NSDate date] timeIntervalSinceDate:lastVerifiedEmail] > (DAYS_SHOW_EMAIL_VERIFY * 86400)) {
                lastVerifiedEmail = [NSDate date];
                [defaults setObject:lastVerifiedEmail forKey:@"lastVerifiedEmail"];
                [defaults synchronize];
                
                // Verify Email
                ORVerifyEmailView *vc = [ORVerifyEmailView new];
                [self presentModalVC:vc];
            }
        }
        
        // Reload Friends
        [CurrentUser reloadFollowingForceReload:NO completion:^(NSError *error) {
            if (error) NSLog(@"Error: %@", error);
        }];
        
        // Reload Followers
        [CurrentUser reloadFollowersForceReload:YES completion:^(NSError *error) {
            if (error) NSLog(@"Error: %@", error);
        }];
    }
    
    // Facebook account...
    if (self.shouldUpdateFacebookPairing) {
        [self updateFacebookPairing];
    }
    
    if (FBSession.activeSession.state != FBSessionStateOpen && FBSession.activeSession.state != FBSessionStateOpenTokenExtended) {
        if (CurrentUser.facebookTokenData) {
            AppDelegate.isLinkingFacebook = NO;
            [AppDelegate facebookSignInAllowLoginUI:NO];
        } else if (CurrentUser.facebookId || CurrentUser.facebookToken) {
            [self removeFacebookPairing];
        }
    }
    
    // Google account...
    if (!AppDelegate.ge.isAuthenticated && CurrentUser.googleToken && CurrentUser.googleSecret) {
        [AppDelegate.ge setAccessToken:CurrentUser.googleToken secret:CurrentUser.googleSecret];
        [AppDelegate.ge getProfileWithCompletion:^(NSError *error) {
            if (!error) {
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                [prefs setObject:AppDelegate.ge.token forKey:@"googleToken"];
                [prefs setObject:AppDelegate.ge.tokenSecret forKey:@"googleTokenSecret"];
                [prefs setObject:AppDelegate.ge.userID forKey:@"googleUserID"];
                [prefs setObject:AppDelegate.ge.userEmail forKey:@"googleUserEmail"];
                [prefs setObject:AppDelegate.ge.userName forKey:@"googleUserName"];
                [prefs setObject:AppDelegate.ge.profilePicture forKey:@"googleProfilePicture"];
                [prefs synchronize];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ORGooglePaired" object:nil];
            } else {
                NSLog(@"Error: %@", error);
                CurrentUser.googleToken = nil;
                CurrentUser.googleSecret = nil;
            }
        }];
    }
    
    // Preload IAP products
    [[ORSubscriptionController sharedInstance] loadProductsWithCompletion:^(NSError *error, BOOL result) {
        NSLog(@"IAP Products refreshed");
    }];
    
    // Twitter account...
    if (CurrentUser.accountType != 1 || !AppDelegate.twitterEngine.isAuthenticated || (!ORIsEmpty(CurrentUser.twitterToken) && ![AppDelegate.twitterEngine.token isEqualToString:CurrentUser.twitterToken])) {
        if (CurrentUser.twitterToken && CurrentUser.twitterSecret) {
            [AppDelegate.twitterEngine setAccessToken:CurrentUser.twitterToken secret:CurrentUser.twitterSecret];
            [self verifyTwitterCredentials];
        } else {
            [self signInFlowIsComplete];
        }
    } else if (CurrentUser.accountType != 1 && AppDelegate.twitterEngine.isAuthenticated) {
        [self verifyTwitterCredentials];
    } else {
        [self signInFlowIsComplete];
    }
}

- (void)verifyTwitterCredentials
{
    [AppDelegate.twitterEngine getProfileWithCompletion:^(NSError *error) {
        if (!error) {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs removeObjectForKey:@"twitterDisabled"];
            [prefs setObject:AppDelegate.twitterEngine.token forKey:@"twitterToken"];
            [prefs setObject:AppDelegate.twitterEngine.tokenSecret forKey:@"twitterTokenSecret"];
            [prefs setObject:AppDelegate.twitterEngine.userId forKey:@"twitterUserId"];
            [prefs setObject:AppDelegate.twitterEngine.screenName forKey:@"twitterScreenName"];
            [prefs setObject:AppDelegate.twitterEngine.userName forKey:@"twitterUserName"];
            [prefs synchronize];
            
            if (![AppDelegate.twitterEngine.token isEqualToString:CurrentUser.twitterToken] || ![AppDelegate.twitterEngine.screenName isEqualToString:CurrentUser.twitterName]) {
                CurrentUser.twitterId = AppDelegate.twitterEngine.userId;
                CurrentUser.twitterToken = AppDelegate.twitterEngine.token;
                CurrentUser.twitterSecret = AppDelegate.twitterEngine.tokenSecret;
                CurrentUser.twitterName = AppDelegate.twitterEngine.screenName;
                [CurrentUser saveLocalUser];
                
                OREpicUser *u = [OREpicUser new];
                u.userId = CurrentUser.userId;
                u.twitterId = CurrentUser.twitterId;
                u.twitterToken = CurrentUser.twitterToken;
                u.twitterSecret = CurrentUser.twitterSecret;
                u.twitterName = CurrentUser.twitterName;
                
                [ApiEngine savePairing:u cb:^(NSError *error, BOOL result) {
                    if (error) NSLog(@"Error: %@", error);
                }];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORTwitterPaired" object:nil];
            [self signInFlowIsComplete];
        } else if (error.code == 401) { // Invalid Credentials
            CurrentUser.twitterId = nil;
            CurrentUser.twitterToken = nil;
            CurrentUser.twitterSecret = nil;
            CurrentUser.twitterName = nil;
            [CurrentUser saveLocalUser];
            
            [AppDelegate.twitterEngine existingAccountsWithCompletion:^(NSError *error, NSArray *items) {
                if (error) NSLog(@"Error: %@", error);
                
                if (items.count > 0) {
                    self.twitterAccounts = items;
                    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Looks like you've been signed out of Twitter. Select an account to use with Veezy:" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
                    
                    for (ACAccount *account in items) {
                        [sheet addButtonWithTitle:account.accountDescription];
                    }
                    
                    sheet.destructiveButtonIndex = [sheet addButtonWithTitle:@"Don't Connect Twitter"];
                    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Later"];
                    
                    UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
                    if ([window.subviews containsObject:self.contentView]) {
                        [sheet showInView:self.contentView];
                    } else {
                        [sheet showInView:window];
                    }
                }
            }];
        } else {
            NSLog(@"Error: %@", error);
            CurrentUser.twitterId = nil;
            CurrentUser.twitterToken = nil;
            CurrentUser.twitterSecret = nil;
            CurrentUser.twitterName = nil;
            [CurrentUser saveLocalUser];
        }
    }];
    
}

- (void)signInFlowIsComplete
{
    // Refresh Feed/Activity (if needed)
    [[ORDataController sharedInstance] userFeedForceReload:NO cacheOnly:NO completion:nil];
    [[ORDataController sharedInstance] userNotificationsForceReload:NO cacheOnly:NO completion:nil];
    
    // Refresh contacts (if needed)
    [[ORDataController sharedInstance] checkAndRefreshABContacts];
    [[ORDataController sharedInstance] facebookContactsForceReload:NO cacheOnly:NO completion:nil];
    [[ORDataController sharedInstance] twitterContactsForceReload:NO cacheOnly:NO completion:nil];
    [[ORDataController sharedInstance] googleContactsForceReload:NO cacheOnly:NO completion:nil];
    
//    NSDictionary *d = @{@"aps": @{@"alert": @"This is a test notification"}};
//    [self presentNotification:d];
}

- (void)removeFacebookPairing
{
    if (CurrentUser.accountType == 2) return;
    
    OREpicUser *u = [OREpicUser new];
    u.userId = CurrentUser.userId;
    u.accountType = 2;

    CurrentUser.facebookId = nil;
    CurrentUser.facebookToken = nil;
    CurrentUser.facebookName = nil;
    CurrentUser.facebookTokenData = nil;

    [ApiEngine removePairing:u cb:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
        
        if (result) {
            CurrentUser.facebookId = nil;
            CurrentUser.facebookToken = nil;
            CurrentUser.facebookName = nil;
            CurrentUser.facebookTokenData = nil;
            [CurrentUser saveLocalUser];
        }
    }];
}

- (void)updateFacebookPairing
{
    if (ORIsEmpty(CurrentUser.facebookToken)) {
        self.shouldUpdateFacebookPairing = YES;
        return;
    }
    
    self.shouldUpdateFacebookPairing = NO;
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
    
    [ApiEngine savePairing:u cb:^(NSError *error, BOOL result) {
        if (error || !result) {
            NSLog(@"Error Updating FB pairing: %@", error);
        }
    }];
    
}

- (void)handleFacebookSignIn
{
    NSLog(@"Facebook sign in handled by ORRootViewController");
    
    [FBSession.activeSession refreshPermissionsWithCompletionHandler:^(FBSession *session, NSError *error) {
        if (error) NSLog(@"Error: %@", error);

        if (CurrentUser.accountType != 2) {
            [self updateFacebookPairing];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORFacebookPaired" object:nil];
        } else {
            OREpicUser *u = (CurrentUser) ?: [[OREpicUser alloc] init];
            u.accountType = 2;
            u.facebookToken = FBSession.activeSession.accessTokenData.accessToken;
            u.appName = APP_NAME;
            
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:FBSession.activeSession.accessTokenData.dictionary];
            if (data) u.facebookTokenData = [data base64EncodedString];
            
            [ApiEngine signInWithUser:u cb:^(NSError *error, OREpicUser *user) {
                if (error) {
                    NSLog(@"Sign-In error: %@", error);
                    ApiEngine.currentUserID = CurrentUser.userId;
                    [self innerCompleteUserLoad];
                } else {
                    if (user) {
                        if (CurrentUser) {
                            [CurrentUser updateWithUser:user];
                        } else {
                            CurrentUser = user;
                        }
                        
                        [self innerCompleteUserLoad];
                    } else {
                        // Authentication failure
                        [self handleORUserSignedOut:nil];
                    }
                }
            }];
        }
    }];
}

- (void)handleFacebookSignOut
{
    NSLog(@"Facebook sign out handled by ORRootViewController");
    
    if (CurrentUser && CurrentUser.accountType == 2) {
        [self handleORUserSignedOut:nil];
    }
}

- (void)presentSignInWithMessage:(NSString *)msg completion:(void (^)(BOOL))completion
{
    return [self presentSignInWithMessage:msg accountType:-1 cancelTitle:nil completion:completion];
}

- (void)presentSignInWithMessage:(NSString *)msg cancelTitle:(NSString *)cancelTitle completion:(void (^)(BOOL))completion
{
    return [self presentSignInWithMessage:msg accountType:-1 cancelTitle:cancelTitle completion:completion];
}

- (void)presentSignInWithMessage:(NSString *)msg accountType:(NSUInteger)accountType completion:(void (^)(BOOL))completion
{
    return [self presentSignInWithMessage:msg accountType:accountType cancelTitle:nil completion:completion];
}

- (void)presentSignInWithMessage:(NSString *)msg accountType:(NSUInteger)accountType cancelTitle:(NSString *)cancelTitle completion:(void (^)(BOOL))completion
{
    ORSignInViewController *signIn = [ORSignInViewController new];
    
    [signIn enableDismissal];
    signIn.completionBlock = completion;
    if (msg) signIn.lblReason.text = msg;
    if (accountType != -1) signIn.automaticAccountType = accountType;
    if (cancelTitle) [signIn.btnNotNow setTitle:cancelTitle forState:UIControlStateNormal];
    if (ORIsEmpty(signIn.lblReason.text)) signIn.lblReason.text = @"Sign-in!";
    
    [self presentModalVC:signIn];
}

#pragma mark - Lead Event

//- (void)leadEventCheck:(BOOL)fromSignIn
//{
//	AppDelegate.leadEvent = nil;
//	DLog(@"leadEventCheck. from signin: %@", NSStringFromBOOL(fromSignIn));
//    
//	[ApiEngine getLeadEventForLatitude:AppDelegate.lastKnownLocation.coordinate.latitude andLongitude:AppDelegate.lastKnownLocation.coordinate.latitude completion:^(NSError *error, OREpicEvent *event) {
//		if (error) {
//			DLog(@"Error getting lead event: %@", error.localizedDescription);
//		} else {
//			if (self.sponsorInterstital) return; // it's already open -- this can happen if this method is called twice quickly
//			if (!event) {
//				DLog(@"Event is nil");
//			} else {
//                AppDelegate.leadEvent = event;
//                
//                // Don't show if displayed less than 24 hours ago
//                NSDate *lastDisplayed = self.eventLastDisplayedDates[event.eventId];
//                if (lastDisplayed && [[NSDate date] timeIntervalSinceDate:lastDisplayed] < 86400) return;
//                
//                self.eventLastDisplayedDates[event.eventId] = [NSDate date];
//                NSString *file = [[ORUtility documentsDirectory] stringByAppendingPathComponent:@"eventdates.dat"];
//                [NSKeyedArchiver archiveRootObject:self.eventLastDisplayedDates toFile:file];
//                
//                self.sponsorInterstital = [[ORLeadEventOpeningInterstitialView alloc] initWithEvent:event];
//                self.sponsorInterstital.view.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
//                self.sponsorInterstital.isFromSignIn = fromSignIn;
//                [self.view addSubview:self.sponsorInterstital.view];
//                [UIView animateWithDuration:0.3f delay:0.0f
//                                    options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut
//                                 animations:^{
//                                     self.sponsorInterstital.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
//                                 } completion:^(BOOL finished) {
//                                     //
//                                 }];
//                
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"ORLeadEventReloaded" object:nil];
//			}
//		}
//	}];
//}

#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) return;
    
    if (buttonIndex < self.twitterAccounts.count) {
        NSLog(@"Authenticating with Twitter...");
        
        [AppDelegate.twitterEngine reverseAuthWithAccount:self.twitterAccounts[buttonIndex] completion:^(NSError *error) {
            if (error) {
                NSLog(@"Error: %@", error);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                message:PAIRING_MESSAGE_TW_UNABLE_TO_USE_SELECTED_ACCOUNT
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
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
                }];
            }
        }];
    } else {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:@(YES) forKey:@"twitterDisabled"];
        [prefs synchronize];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.twitterAccounts = nil;
}

#pragma mark - NSNotifications

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORPresentSignIn:) name:@"ORPresentSignIn" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORUserSignedIn:) name:@"ORUserSignedIn" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORUserSignedOut:) name:@"ORUserSignedOut" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORDismissNotification:) name:@"ORDismissNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORUnpausePlayerIfVisible:) name:@"ORUnpausePlayerIfVisible" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORUploadProgress:) name:@"ORUploadProgress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORRecordingStarted:) name:@"ORRecordingStarted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORRecordingStopped:) name:@"ORRecordingStopped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOROpenABTestView:) name:@"OROpenABTestView" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORVideoUploaded:) name:@"ORVideoUploaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORUploadProgress:) name:@"ORUploadProgress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORUpdateBadge:) name:@"ORUpdateBadge" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORPresentFindFriends:) name:@"ORPresentFindFriends" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopMotionDetect) name:@"ORVideoAdded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORSubscriptionStarted:) name:@"ORSubscriptionStarted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORSubscriptionEnded:) name:@"ORSubscriptionEnded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)handleDidEnterBackground:(NSNotification *)n
{
    [self pauseMotionDetect];
}

- (void)handleWillEnterForeground:(NSNotification *)n
{
    [self performSelector:@selector(unpauseMotionDetect) withObject:nil afterDelay:5.0f];
}

- (void)handleORUpdateBadge:(NSNotification *)n
{
    [self.navigationView updateBadges];
}

- (void)handleORPresentSignIn:(NSNotification *)n
{
    [self presentSignInDialog];
}

- (void)handleOROpenABTestView:(NSNotification*)n
{
//	ORABTestAdmin *vc = [ORABTestAdmin new];
//	[self pushToMainViewController:vc completion:nil];
}

- (void)handleORUnpausePlayerIfVisible:(NSNotification*)n
{
	[self unpause];
}

- (void)handleORPermissionsViewDismissed:(NSNotification *)n
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ORPermissionsViewDismissed" object:nil];
    [self handleORUserSignedIn:nil];
}

- (void)handleORUserSignedIn:(NSNotification *)notification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL completed = [defaults boolForKey:@"permissionsViewCompleted"];
    
    if (!completed) {
        if ([[ORPermissionsEngine sharedInstance] needsPermissionView]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORPermissionsViewDismissed:) name:@"ORPermissionsViewDismissed" object:nil];
            
            ORPermissionsView *pv = [ORPermissionsView new];
            [self presentViewController:pv animated:YES completion:nil];
            return;
        } else {
            [defaults setBool:YES forKey:@"permissionsViewCompleted"];
            [defaults synchronize];
        }
    }
    
    AppDelegate.isSignedIn = YES;
    
    OREpicFriend *friend = [[OREpicFriend alloc] initWithUser:CurrentUser];
    [CurrentUser relatedUserWithUser:friend];
    
    // Update badges
    [self handleORUpdateBadge:nil];
    
    if (AppDelegate.firstAppRun) {
        AppDelegate.firstAppRun = NO;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // Crashlytics
    [Crashlytics setObjectValue:ApiEngine.currentSessionID forKey:@"session_id"];
    if (CurrentUser.userId) [Crashlytics setUserIdentifier:CurrentUser.userId];
    if (CurrentUser.emailAddress) [Crashlytics setUserEmail:CurrentUser.emailAddress];
    if (CurrentUser.name) [Crashlytics setUserName:CurrentUser.name];

	// Mixpanel
	[AppDelegate.mixpanel identify:CurrentUser.userId];
    [AppDelegate.mixpanel.people set:@{@"UserId": CurrentUser.userId}];
	if (CurrentUser.name) [AppDelegate.mixpanel.people set:@{@"$name": CurrentUser.name}];
	if (CurrentUser.emailAddress) [AppDelegate.mixpanel.people set:@{@"$email": CurrentUser.emailAddress}];
	if (CurrentUser.signupDate) [AppDelegate.mixpanel.people set:@{@"$created": CurrentUser.signupDate}];
    if (CurrentUser.twitterId) [AppDelegate.mixpanel.people set:@{@"TwitterId": CurrentUser.twitterId}];
    if (CurrentUser.facebookId) [AppDelegate.mixpanel.people set:@{@"FacebookId": CurrentUser.facebookId}];
    
    double freePercent = [ORUtility deviceFreeSpacePercent];
    [AppDelegate.mixpanel track:@"Signed In" properties:@{@"Free Space %": @(freePercent)}];
    [ORLoggingEngine logEvent:@"DeviceSpace" params:[[ORUtility deviceSpace] mutableCopy]];
	
    [self.captureView startPreview];
    self.mainView.view.hidden = NO;
	
//    // Show Cold Start if Needed
//    if (!self.checkedForColdStart) {
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//        BOOL cs = [defaults boolForKey:@"coldStart"];
//        if (!cs) {
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"OROpenWhatMakesVeezyAmazing" object:@(YES)];
//            self.checkedForColdStart = YES;
//            return;
//        }
//        
//        self.checkedForColdStart = YES;
//    }
    
    // Start the Location Manager
    if (AppDelegate.isAllowedToUseLocationManager) {
        [AppDelegate updateLocation];
    }
    
#ifdef DEBUG
	NSString *abtest_1 = [defaults objectForKey:@"abtest-1"];
	if (abtest_1) {
		CurrentUser.abTests = [NSMutableArray array];
		[CurrentUser.abTests addObject:abtest_1];
	}
#endif
	
    self.isSignedIn = YES;
    
    NSLog(@"---");
    NSLog(@"User signed in: %@", CurrentUser);
    NSLog(@"---");
    
    // Handle any pending notifications / URLs
    if (self.pendingNotification) [self handleNotification:self.pendingNotification];
    if (self.pendingURL) [self handleURL:self.pendingURL];
    
    [self hideAllNudges];
    [self prepareNudges];
    
    // First sign in is handled differently
    if ([notification.userInfo objectForKey:@"first_signin"]) {
        [self innerCompleteUserLoad];
    }
}

- (void)handleORUserSignedOut:(NSNotification *)n
{
    // Cancel any pending uploads
    [[ORFaspPersistentEngine sharedInstance] cancelAllUploads];

    ApiEngine.currentSessionID = [ORUtility newGuidString];
    [AppDelegate.twitterEngine resetOAuthToken];
    [AppDelegate.ge resetOAuthToken];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs removeObjectForKey:@"twitterDisabled"];
    [prefs removeObjectForKey:@"twitterToken"];
    [prefs removeObjectForKey:@"twitterTokenSecret"];
    [prefs removeObjectForKey:@"twitterUserId"];
    [prefs removeObjectForKey:@"twitterScreenName"];
    [prefs removeObjectForKey:@"twitterUserName"];
    [prefs removeObjectForKey:@"googleToken"];
    [prefs removeObjectForKey:@"googleTokenSecret"];
    [prefs removeObjectForKey:@"googleUserID"];
    [prefs removeObjectForKey:@"googleUserName"];
    [prefs removeObjectForKey:@"googleUserEmail"];
    [prefs removeObjectForKey:@"googleProfilePicture"];
    [prefs synchronize];
    
    if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        [FBSession.activeSession closeAndClearTokenInformation];
    }
 
    self.eventLastDisplayedDates = [NSMutableDictionary dictionary];
    NSString *file = [[ORUtility documentsDirectory] stringByAppendingPathComponent:@"eventdates.dat"];
    [NSKeyedArchiver archiveRootObject:self.eventLastDisplayedDates toFile:file];
    
    // Delete caches
    BOOL isDir;
    NSString *path = [[ORUtility cachesDirectory] stringByAppendingPathComponent:@"user_cache"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
        if (isDir) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            if (error) NSLog(@"Error: %@", error);
        }
    }
    
    // Recreate caches
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // Remove any badges
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [self handleORUpdateBadge:nil];

    // Make sure we don't display Cold Start after sign out
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:YES forKey:@"coldStart"];
	[defaults synchronize];
    
    [self ShowCameraNotAnimated];
    	
    NSLog(@"User signed out, will present sign-in");
	[self presentSignInDialog];
}

- (void)handleORDismissNotification:(NSNotification *)notification
{
    [self dismissNotification];
    
    if (notification.userInfo) {
        // Dismiss the keyboard, if visible
        [ORUtility resignFirstResponderRecursive:[[UIApplication sharedApplication] keyWindow]];
        
        [self handleNotification:notification.userInfo];
    }
}

- (void)handleORRecordingStarted:(NSNotification *)notification
{
    self.navigationView.view.hidden = YES;
    
	self.uploadBitrateAvg = 0;
	self.uploadBitrateMax = 0;
	self.uploadBitrateMin = DBL_MAX;
}

- (void)handleORRecordingStopped:(NSNotification *)notification
{
    self.navigationView.view.hidden = NO;
}

- (void)handleORUploadProgress:(NSNotification *)n
{
	if (!n.object) return;
	
    double uploadProgress = [n.object doubleValue];
		
	self.uploadBitrateAvg = uploadProgress;
	self.uploadBitrateMax = MAX(uploadProgress, self.uploadBitrateMax);
	self.uploadBitrateMin = MIN(uploadProgress, self.uploadBitrateMin);
	
}

- (void)handleORVideoUploaded:(NSNotification *)notification
{
	NetworkStatus status = ApiEngine.currentNetworkStatus;
	NSString *netType;
	switch (status) {
		case ReachableViaWiFi:
			netType = @"Wifi";
			break;
		case ReachableViaWWAN:
			netType = @"Wwan";
			break;
		default:
            netType = @"NotReachable";
			break;
	}
	
	[AppDelegate.mixpanel track:@"Upload Bitrate" properties:@{
		@"AvgBitrate": [NSString stringWithFormat:@"%f", self.uploadBitrateAvg],
		@"MaxBitrate": [NSString stringWithFormat:@"%f", self.uploadBitrateMax],
		@"MinBitrate": [NSString stringWithFormat:@"%f", self.uploadBitrateMin],
		@"ConnectionType": netType,
		@"Latitude": [NSString stringWithFormat:@"%f", AppDelegate.lastKnownLocation.coordinate.latitude],
		@"Longitude": [NSString stringWithFormat:@"%f", AppDelegate.lastKnownLocation.coordinate.longitude]
															}];
}

- (void)handleORPresentFindFriends:(NSNotification *)n
{
    ORUserProfileView *vc = [[ORUserProfileView alloc] initWithFriend:CurrentUser.asFriend];
    vc.openInConnect = YES;
    [self pushToMainViewController:vc completion:nil];
}

- (void)handleORSubscriptionStarted:(NSNotification *)n
{
    if (CurrentUser.hasExpiringVideos) {
        self.alertView.delegate = nil;
        
        NSString *title = (CurrentUser.subscriptionIsTrial) ? @"Trial Started!" : @"Thanks for Subscribing!";
        self.alertView = [[UIAlertView alloc] initWithTitle:title
                                                    message:@"You have videos that will expire soon. Do you want to remove the expiration from them and keep them indefinitely?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
        
        self.alertView.tag = 4;
        [self.alertView show];
    } else {
        [self checkIfUserHasEmail];
    }
}

- (void)checkIfUserHasEmail
{
    if (ORIsEmpty(CurrentUser.emailAddress)) {
        // Add Email
        ORAddEmailView *vc = [ORAddEmailView new];
        [self presentModalVC:vc];
    }
}

- (void)handleORSubscriptionEnded:(NSNotification *)n
{
    // TODO: warn user that his/her subscription has ended
    NSLog(@"User Subscription Ended");
}

#pragma mark - Push Notifications

- (void)presentNotification:(NSDictionary *)notification
{
    if ([notification[@"type"] isEqualToString:@"epic_videocomment"]) {
        if ([self.mainView.topViewController isKindOfClass:[ORWatchView class]]) {
            ORWatchView *vc = (ORWatchView *)self.mainView.topViewController;
            
            if ([vc.video.videoId isEqualToString:notification[@"video_id"]]) {
                [vc handleCommentNotification:notification];
                return;
            }
        }
    } else if ([notification[@"type"] isEqualToString:@"epic_usertyping"]) {
        if ([self.mainView.topViewController isKindOfClass:[ORWatchView class]]) {
            ORWatchView *vc = (ORWatchView *)self.mainView.topViewController;
            
            if ([vc.video.videoId isEqualToString:notification[@"video_id"]]) {
                [vc handleTypingNotification:notification];
                return;
            }
        }
        
        return;
    } else if ([notification[@"type"] isEqualToString:@"epic_newuserfollower"]) {
        // Reload Followers
        [CurrentUser reloadFollowersForceReload:YES completion:^(NSError *error) {
            if (error) NSLog(@"Error: %@", error);
        }];
    } else if (ORIsEmpty([notification valueForKeyPath:@"aps.alert"])) {
        // Empty Notification
        return;
    }
        
    if (self.notificationView) {
        [self.notificationView.view removeFromSuperview];
        self.notificationView = nil;
    }
    
    self.notificationView = [[ORNotificationView alloc] initWithNotification:notification];
    
    CGRect frame = self.notificationView.view.frame;
    frame.size.height = ([UIApplication sharedApplication].statusBarHidden) ? 44.0f : 64.0f;
    frame.origin.x = 0;
    frame.origin.y = -frame.size.height;
    frame.size.width = self.contentView.bounds.size.width;
    self.notificationView.view.frame = frame;
    [self.contentView addSubview:self.notificationView.view];
    
    frame.origin.y += frame.size.height;
    
    [UIView animateWithDuration:0.2f animations:^{
        self.notificationView.view.frame = frame;
    } completion:^(BOOL finished) {
        [self performSelector:@selector(dismissNotification) withObject:nil afterDelay:4.0f];
    }];
    
}

- (void)dismissNotification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissNotification) object:nil];
    
    if (self.notificationView) {
        CGRect frame = self.notificationView.view.frame;
        frame.origin.y = -frame.size.height;
		
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        
        [UIView animateWithDuration:0.2f animations:^{
            self.notificationView.view.frame = frame;
        } completion:^(BOOL finished) {
            [self.notificationView.view removeFromSuperview];
            self.notificationView = nil;
        }];
    }
}

- (void)handleNotification:(NSDictionary *)notification
{
    if (!self.isAlreadyVisible || !self.isSignedIn) {
        self.pendingNotification = notification;
        return;
    }
    
    self.pendingNotification = nil;
    
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self handleNotification:notification];
        }];
        
        return;
    }
    
    if (!ORIsEmpty(notification[@"video_id"])) {
        if ([notification[@"type"] isEqualToString:@"epic_videoexpiring"]) {
            ORExpiringVideoView *vc = [[ORExpiringVideoView alloc] initWithVideoId:notification[@"video_id"]];
            ORNavigationController *nav = [[ORNavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:nav animated:YES completion:nil];
            
            return;
        }
        
        ORWatchView *watch = [[ORWatchView alloc] initWithVideoId:notification[@"video_id"]];
        if ([notification[@"type"] isEqualToString:@"epic_videocomment"]) {
            watch.shouldScrollToBottom = YES;
        } else {
            watch.shouldAutoplay = YES;
        }
        
        [self pushToMainViewController:watch completion:nil];
    } else if (!ORIsEmpty(notification[@"user_id"])) {
		[ApiEngine friendWithId:notification[@"user_id"] completion:^(NSError *error, OREpicFriend *epicFriend) {
			if (epicFriend) {
				ORUserProfileView *profile = [[ORUserProfileView alloc] initWithFriend:epicFriend];
                if ([notification[@"type"] isEqualToString:@"epic_friendjoined"]) profile.askToFollow = YES;
				[self pushToMainViewController:profile completion:nil];
			}
		}];
	}
}

- (BOOL)handleURL:(NSURL *)url
{
    if (!self.isAlreadyVisible || !self.isSignedIn) {
        self.pendingURL = url;
        return YES;
    }
    
    self.pendingURL = nil;
    
    NSString *onlyPath = [url.absoluteString stringByReplacingOccurrencesOfString:@"veezy://" withString:@""];
    NSArray *path = [onlyPath componentsSeparatedByString:@"/"];
    if (path.count < 2) return YES;
    
    if ([url.host isEqualToString:@"v"]) {
        [ApiEngine videoWithId:path[1] completion:^(NSError *error, OREpicVideo *video) {
            if (video) {
				ORWatchView *watch = [[ORWatchView alloc] initWithVideo:video];
                watch.shouldAutoplay = YES;
                
                [self pushToMainViewController:watch completion:nil];
            }
        }];
        
        return YES;
    } else if ([url.host isEqualToString:@"u"]) {
		[ApiEngine friendWithId:path[1] completion:^(NSError *error, OREpicFriend *epicFriend) {
			if (epicFriend) {
				ORUserProfileView *profile = [[ORUserProfileView alloc] initWithFriend:epicFriend];
				[self pushToMainViewController:profile completion:nil];
			}
		}];
        
        return YES;
    }
    
    return NO;
}

#pragma mark - Player Management

- (void)unpause
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORUnpausePlayer" object:nil];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    
	switch (alertView.tag) {

		case 1: {
            if (buttonIndex == alertView.cancelButtonIndex) return;
			[self presentSignInWithMessage:@"Sign-in Now" completion:nil];
			break;
        }
			
//		case 2: // User responded to camera rationale alert
//			if (buttonIndex == 1) {
//				[self requestMicrophonePermissionFromOS];
//			} else {
//				// user doesn't want to grant camera permission right now, nudge them
//				[self nudgeUserForMicrophonePermission];
//			}
//			break;
			
		case 3: // user responded to location rationale alert
			if (buttonIndex == 1) {
				[self requestLocationPermissionFromOS];
			} else {
				// user doesn't want to grant location permission right now
				// don't say anything more for right now
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES forKey:@"deniedLocation"];
                [defaults synchronize];
			}
            
			break;
            
        case 4: // Expiring Videos
            if (buttonIndex == alertView.cancelButtonIndex) {
				self.alertView = [[UIAlertView alloc] initWithTitle:@"Video Expirations Unchanged"
															message:@"Any of your videos that previously had expirations will still expire as before."
														   delegate:self
												  cancelButtonTitle:@"Ok"
												  otherButtonTitles:nil];
				
				[self.alertView show];
                [self checkIfUserHasEmail];
            } else {
                [ApiEngine removeVideoExpirationsWithCompletion:^(NSError *error, BOOL result) {
                    if (error) NSLog(@"Error: %@", error);
					if (result) {
                        [[ORDataController sharedInstance] invalidateFeedCache];
                        [[ORDataController sharedInstance] invalidateUserVideosCache];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORVideoExpirationsChanged" object:nil];
                        
						CurrentUser.hasExpiringVideos = NO;
						self.alertView = [[UIAlertView alloc] initWithTitle:@"Video Expirations Removed"
																	message:@"Any of your videos that previously had expirations will no longer expire."
																   delegate:self
														  cancelButtonTitle:@"Ok"
														  otherButtonTitles:nil];
						
						[self.alertView show];
					}
					[self checkIfUserHasEmail];
                }];
            }
			
            break;
    }
}

#pragma mark - Camera Permission

- (void)requestMicrophonePermissionFromOSWithCompletion:(void(^)(BOOL granted))completion
{
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
					if (completion) completion(YES);
                } else {
                    if (completion) completion(NO);
					[self microphonePermissionOSDenied];
                }
            });
        }];
    } else {
        if (completion) completion(YES);
    }
}

- (void)microphonePermissionOSDenied
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Microphone Permission"
                                                    message:PERMISSION_MICROPHONE_OS_DENIED
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Location Permission

- (void)requestLocationPermissionFromUser
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"askedForLocation"];
    [defaults synchronize];

    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Permission"
                                                        message:PERMISSION_LOCATION_OS_DENIED
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
//        self.alertView.delegate = nil;
//        self.alertView = [[UIAlertView alloc] initWithTitle:@"Location Permission"
//                                                    message:PERMISSION_LOCATION
//                                                   delegate:self
//                                          cancelButtonTitle:@"No"
//                                          otherButtonTitles:@"Yes", nil];
//        self.alertView.tag = 3;
//        [self.alertView show];
        
        // Pre-OS permission requests are disabled for now
        [self requestLocationPermissionFromOS];
    }
}

- (void)requestLocationPermissionFromOS
{
    [AppDelegate requestLocationPermission];
}

#pragma mark - Nudge Cells

- (void)showPendingVideos
{
    if (self.pendingVideosVisible) return;
    
    self.pendingVideosVisible = YES;
    self.pendingVideos.view.hidden = NO;
    
    CGRect f = self.pendingVideos.view.frame;
    f.origin.y = TOP_PADDING;
    if (CurrentUser.accountType == 3) f.origin.y += 60.0f;
    
    [UIView animateWithDuration:0.2f animations:^{
        self.pendingVideos.view.frame = f;
    }];
    
    [self showNudges];
}

- (void)hidePendingVideos
{
    if (!self.pendingVideosVisible) return;
    
    self.pendingVideosVisible = NO;
    CGRect f = self.pendingVideos.view.frame;
    f.origin.y = -f.size.height;
    
    [UIView animateWithDuration:0.2f animations:^{
        self.pendingVideos.view.frame = f;
    } completion:^(BOOL finished) {
        self.pendingVideos.view.hidden = YES;
    }];
    
    [self showNudges];
}

- (void)hideNudge:(ORNudgeView *)nudge
{
    CGRect f = nudge.view.frame;
    f.origin.y = -f.size.height;
    
    [self.nudgeViews removeObject:nudge];
    
    [UIView animateWithDuration:0.2f animations:^{
        nudge.view.frame = f;
    } completion:^(BOOL finished) {
        [nudge willMoveToParentViewController:nil];
        [nudge.view removeFromSuperview];
        [nudge removeFromParentViewController];
    }];
    
    [self showNudges];
}

- (void)hideAllNudges
{
    NSArray *nudges = [self.nudgeViews copy];
    self.nudgeViews = nil;
    
    [UIView animateWithDuration:0.2f animations:^{
        for (ORNudgeView *view in nudges) {
            CGRect f = view.view.frame;
            f.origin.y = -f.size.height;
            view.view.frame = f;
        }
    } completion:^(BOOL finished) {
        for (ORNudgeView *view in nudges) {
            [view willMoveToParentViewController:nil];
            [view.view removeFromSuperview];
            [view removeFromParentViewController];
        }
    }];
}

- (void)showNudges
{
    if (self.nudgeViews.count == 0) return;
    
    [UIView animateWithDuration:0.2f animations:^{
        NSUInteger viewCount = 0;
        CGFloat nudgePosition = TOP_PADDING;
        if (CurrentUser.accountType == 3) nudgePosition += 60.0f;
        
        if (self.pendingVideosVisible) {
            viewCount = 1;
            nudgePosition += self.pendingVideos.view.frame.size.height + 5.0f;
        }
        
        for (ORNudgeView *view in self.nudgeViews) {
            CGRect f = view.view.frame;

            if (viewCount >= NUDGE_CELLS_TO_SHOW) {
                f.origin.y = -f.size.height;
            } else {
                f.origin.y = nudgePosition;
                nudgePosition += f.size.height + 5.0f;
            }
            
            view.view.frame = f;
            viewCount++;
        }
    }];
}

- (void)prepareNudges
{
    if (!self.nudgeViews) self.nudgeViews = [NSMutableArray arrayWithCapacity:0];
    
    [self verifyShootVideo];
    [self verifyFacebook];
    [self verifyPush];
//    [self verifyABConnection];
    [self verifyTwitter];
    [self verifyInviteFriends];
    
    [self showNudges];
}

- (void)verifyABConnection
{
    if (CurrentUser.accountType == 3) return;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"dontShowConnectAB"]) {
        return;
    }
    
    if (ABAddressBookGetAuthorizationStatus != NULL) {
        ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
        
        if (status != kABAuthorizationStatusAuthorized) {
            ORAddressBookNudgeView *nudge = [ORAddressBookNudgeView new];
            [self addChildViewController:nudge];
            nudge.view.frame = CGRectMake(10.0f, -60.0f, 300.0f, 60.0f);
            [self.contentView insertSubview:nudge.view belowSubview:self.pendingVideos.view];
            [nudge didMoveToParentViewController:self];
            
            [self.nudgeViews addObject:nudge];
		}
    }
}

- (void)verifyShootVideo
{
    // Always detect rotation lock
    [self startMotionDetect];
    
//    if (CurrentUser.totalVideoCount == 0 || CurrentUser.totalVideoCount == 1) {
//        [self startMotionDetect];
//    } else {
//        [self stopMotionDetect];
//    }
}

- (void)startMotionDetect
{
    [self stopMotionDetect];
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.startTime = 0;
    
    CGFloat updateInterval = 30/60.0;
    CMAttitudeReferenceFrame frame = CMAttitudeReferenceFrameXArbitraryCorrectedZVertical;
    
    [self.motionManager setDeviceMotionUpdateInterval:updateInterval];
    [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:frame toQueue:[NSOperationQueue new] withHandler:^(CMDeviceMotion* motion, NSError* error){
        CGFloat x = motion.gravity.x;
        CGFloat y = motion.gravity.y;
        CGFloat z = motion.gravity.z;
        CGFloat angle = (atan2(x, y) * 180/M_PI);
        CGFloat r = sqrtf(x*x + y*y + z*z);
        CGFloat tilt = acosf(z/r) * 180.0f / M_PI - 90.0f;
        
        if (((angle >= 70.0f && angle <= 110.0f) || (angle >= -110.0f && angle <= -70.0f)) && (tilt >= -45.0f && tilt <= 45.0f)) {
            if (self.startTime == 0) self.startTime = CACurrentMediaTime();
            CFTimeInterval elapsedTime = CACurrentMediaTime() - self.startTime;
            
            if (elapsedTime > 1 && !self.alerted) {
                self.alerted = YES;
                [self stopMotionDetect];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
                        [[[UIAlertView alloc] initWithTitle:@"Disable Rotation Lock"
                                                    message:@"It seems that you currently have rotation lock enabled.\n\nYou need to disable it to be able to shoot a video.\n\nSwipe up from the bottom of the screen to reveal the lock switch."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil] show];
                    }
                });
            } else if (elapsedTime > 1 && self.alerted) {
                [self stopMotionDetect];
            }
        } else {
            self.startTime = 0;
        }
    }];
    
    NSLog(@"Started motion detector");
}

- (void)stopMotionDetect
{
    if (self.motionManager) {
        [self.motionManager stopDeviceMotionUpdates];
        self.motionManager = nil;
        
        NSLog(@"Stopped motion detector");
    }
}

- (void)pauseMotionDetect
{
    if (self.motionManager) {
        [self.motionManager stopDeviceMotionUpdates];
        NSLog(@"Paused motion detector");
    }
}

- (void)unpauseMotionDetect
{
    if (self.motionManager) [self startMotionDetect];
}

- (void)verifyPush
{
    if (!AppDelegate.pushNotificationsEnabled) {
        ORPushNudgeView *nudge = [ORPushNudgeView new];
        [self addChildViewController:nudge];
        nudge.view.frame = CGRectMake(10.0f, -60.0f, 300.0f, 60.0f);
        [self.contentView insertSubview:nudge.view belowSubview:self.pendingVideos.view];
        [nudge didMoveToParentViewController:self];
        
        [self.nudgeViews addObject:nudge];
    }
}

- (void)verifyFacebook
{
    if (FBSession.activeSession.state != FBSessionStateCreatedTokenLoaded && FBSession.activeSession.state != FBSessionStateOpen && FBSession.activeSession.state != FBSessionStateOpenTokenExtended && CurrentUser.accountType != 3) {
        ORFacebookNudgeView *nudge = [ORFacebookNudgeView new];
        [self addChildViewController:nudge];
        nudge.view.frame = CGRectMake(10.0f, -60.0f, 300.0f, 60.0f);
        [self.contentView insertSubview:nudge.view belowSubview:self.pendingVideos.view];
        [nudge didMoveToParentViewController:self];
        
        [self.nudgeViews addObject:nudge];
    }
}

- (void)verifyTwitter
{
    if (!CurrentUser.isTwitterAuthenticated && CurrentUser.accountType != 3) {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        if ([prefs boolForKey:@"twitterDisabled"]) return;

        ORTwitterNudgeView *nudge = [ORTwitterNudgeView new];
        [self addChildViewController:nudge];
        nudge.view.frame = CGRectMake(10.0f, -60.0f, 300.0f, 60.0f);
        [self.contentView insertSubview:nudge.view belowSubview:self.pendingVideos.view];
        [nudge didMoveToParentViewController:self];
        
        [self.nudgeViews addObject:nudge];
    }
}

- (void)verifyInviteFriends
{
    if (CurrentUser.accountType == 3) return;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"displayedInviteNudge"]) {
        return;
    }
    
    ORInviteFriendsNudgeView *nudge = [ORInviteFriendsNudgeView new];
    [self addChildViewController:nudge];
    nudge.view.frame = CGRectMake(10.0f, -60.0f, 300.0f, 60.0f);
    [self.contentView insertSubview:nudge.view belowSubview:self.pendingVideos.view];
    [nudge didMoveToParentViewController:self];
    
    [self.nudgeViews addObject:nudge];
}

@end
