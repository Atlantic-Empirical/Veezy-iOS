//
//  ORAppDelegate.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 10/5/12.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "GAI.h"

@class ORRootViewController, OREpicUser, OREpicApiEngine, ORTwitterEngine, ORGoogleEngine, ORFoursquareEngine, OREpicEvent, RESideMenu, Mixpanel;

@interface ORAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ORRootViewController *viewController;

@property (strong, nonatomic) OREpicUser *currentUser;
@property (strong, nonatomic) OREpicApiEngine *apiEngine;
@property (strong, nonatomic) ORTwitterEngine *twitterEngine;
@property (strong, nonatomic) ORGoogleEngine *ge;
@property (strong, nonatomic) id<GAITracker> ga;
@property (strong, nonatomic) ORFoursquareEngine *places;
@property (strong, nonatomic) OREpicEvent *leadEvent;
@property (strong, nonatomic) Mixpanel *mixpanel;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *lastKnownLocation;
@property (nonatomic, assign, readonly) BOOL hasInternetConnection;
@property (nonatomic, assign) BOOL isSignedIn;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, assign) BOOL isFASPInitialized;
@property (nonatomic, assign) BOOL isLinkingFacebook;
@property (nonatomic, assign) BOOL pushNotificationsEnabled;
@property (nonatomic, assign) BOOL isAllowedToUseLocationManager;
@property (nonatomic, readonly) BOOL isUpdatingLocation;
@property (nonatomic, assign) BOOL firstAppRun;

- (UIInterfaceOrientation)interfaceOrientation;
- (void)requestLocationPermission;
- (void)updateLocation;
- (void)lockOrientation;
- (void)unlockOrientation;
- (void)forcePortraitWithCompletion:(void (^)())completion;
- (void)forcePortrait;
- (void)forceLandscape;
- (void)forceLandscapeWithCompletion:(void (^)())completion;
- (void)styleView:(UIView*)view;
- (void)gaLogWithCategory:(NSString*)cat andAction:(NSString*)act andLabel:(NSString*)lab andValue:(NSNumber*)num;
- (void)setOffline:(BOOL)offline;
- (void)facebookSignInAllowLoginUI:(BOOL)allowLoginUI;
- (void)registerForPushNotifications;

- (void)AudioSession_Default;
- (void)AudioSession_Capture;
- (void)AudioSession_AudioMonitor;

- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error;

- (NSString*)machineName;
- (NSString*)platformString;

- (void)nativeBarAppearance_nativeShare;
- (void)nativeBarAppearance_default;

- (NSString *)currentServerVideoId;
- (BOOL)startServerForVideo:(NSString *)videoId;
- (BOOL)stopServerForVideo:(NSString *)videoId;

@end
