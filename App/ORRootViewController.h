//
//  ORRootViewController.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 12/24/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ORUIStateCamera = 0,
    ORUIStateMainInterface = 1
} ORUIState;

@class ORNudgeView, ORCaptureView;

@interface ORRootViewController : GAITrackedViewController

@property (nonatomic, readonly) BOOL isAlreadyVisible;
@property (assign) NSUInteger currentSupportedOrientations;
@property (readonly) ORUIState currentState;
@property (nonatomic, strong) ORCaptureView *captureView;
@property (nonatomic, strong) OREpicVideo *tempVideo;

- (void)loadCurrentUser;
- (void)presentNotification:(NSDictionary *)notification;
- (void)handleNotification:(NSDictionary *)notification;
- (BOOL)handleURL:(NSURL *)url;

- (void)resetMainViewWith:(UIViewController *)vc completion:(void (^)())completion;
- (void)pushToMainViewController:(UIViewController *)vc completion:(void (^)())completion;
- (void)presentVCModally:(UIViewController *)vc;
- (void)dismissModalVC;

- (void)removeFacebookPairing;
- (void)updateFacebookPairing;
- (void)handleFacebookSignIn;
- (void)handleFacebookSignOut;

- (void)setOfflineBannerVisible:(BOOL)visible;
- (void)showCamera;
- (void)showMenu;

- (void)presentSignInWithMessage:(NSString *)msg completion:(void (^)(BOOL success))completion;
- (void)presentSignInWithMessage:(NSString *)msg cancelTitle:(NSString *)cancelTitle completion:(void (^)(BOOL success))completion;
- (void)presentSignInWithMessage:(NSString *)msg accountType:(NSUInteger)accountType completion:(void (^)(BOOL success))completion;
- (void)presentSignInWithMessage:(NSString *)msg accountType:(NSUInteger)accountType cancelTitle:(NSString *)cancelTitle completion:(void (^)(BOOL success))completion;

- (void)presentSignInDialog;
- (void)presentModalVC:(UIViewController *)vc;
- (void)configureForOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration;

- (void)requestMicrophonePermissionFromOSWithCompletion:(void(^)(BOOL granted))completion;
- (void)requestLocationPermissionFromUser;
- (void)startPreview;
- (void)stopPreview;

- (void)presentPCVWithVideo:(OREpicVideo *)video andPlaces:(NSArray *)places force:(BOOL)force;
- (void)dismissPCVWithCompletion:(void (^)())completion;

- (void)showPendingVideos;
- (void)hidePendingVideos;
- (void)hideNudge:(ORNudgeView *)nudge;

- (CGFloat)bottomMargin;

@end
