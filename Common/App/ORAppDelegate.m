//
//  ORAppDelegate.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 10/5/12.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <sys/utsname.h>
#import "ORAppDelegate.h"
#import "ORFaspPersistentEngine.h"
#import "ACTReporter.h"
#import "GCDWebServer.h"

//	[[Crashlytics sharedInstance] crash];

#define SESSION_INACTIVE_TIMEOUT 300

@interface ORAppDelegate () <UIAlertViewDelegate>

@property (nonatomic, readwrite, assign) BOOL isUpdatingLocation;
@property (assign, nonatomic) BOOL varIsOnline;
@property (strong, nonatomic) NSDate *lastClosed;
@property (nonatomic, strong) UIAlertView *alertView;

@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic, copy) NSString *webServerVideoId;

@property (nonatomic, assign) BOOL needsBuild288VideoRecover;

@property (nonatomic, assign) BOOL isPerformingFetch;
@property (nonatomic, assign) BOOL isUpdatingFollowers;
@property (nonatomic, assign) BOOL isUpdatingFeed;
@property (nonatomic, assign) BOOL isUpdatingNotifications;

@property (nonatomic, copy) void (^currentBGCompletion)(UIBackgroundFetchResult);

@end

@implementation ORAppDelegate

- (void)dealloc
{
    self.alertView.delegate = nil;
    self.locationManager.delegate = nil;
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.isAllowedToUseLocationManager = ([CLLocationManager locationServicesEnabled] &&
                                          ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized ||
                                           [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse ||
                                           [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways));
    
	DLog(@"%@", [self machineName]);
    NSLog(@"FB SDK Version: %@", [FBSettings sdkVersion]);
    
    if (![APP_CODE isEqualToString:@"V"]) {
        [FBSettings enablePlatformCompatibility:YES];
    }
    
	// Google Analytics
    [GAI sharedInstance].trackUncaughtExceptions = NO;
    [GAI sharedInstance].dispatchInterval = 20;
//	[[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];	// Optional: set Logger to VERBOSE for debug information.
	self.ga = [[GAI sharedInstance] trackerWithTrackingId:GA_TRACKING_ID];
    [self.ga setAllowIDFACollection:YES];
		
	// Crashlytics
//	[[Crashlytics sharedInstance] setDebugMode:YES];
	[Crashlytics startWithAPIKey:CRASHLYTICS_KEY];
    
    // Mixpanel
    self.mixpanel = [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];

    // Get Current/Stored Versions
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"]; // example: 1.0.0
    NSNumber *buildNumber = [infoDict objectForKey:@"CFBundleVersion"]; // example: 42
    NSString *currentVersion = [NSString stringWithFormat:@"v%@.%@", appVersion, buildNumber];
    NSString *lastUpdatedVersion = [prefs stringForKey:@"lastUpdatedVersion"];
    
    if ([prefs boolForKey:@"hasLaunchedOnce"]) {
        self.firstAppRun = NO;
    } else {
        self.firstAppRun = YES;
    }
    
    // Check if an update is needed
    if (!lastUpdatedVersion || ![currentVersion isEqualToString:lastUpdatedVersion]) {
        [self updateToVersion:currentVersion fromVersion:lastUpdatedVersion];
    }

	// Google iOS Download tracking snippet
    if (GA_CONVERSION_ID) {
        // Learn more: https://developers.google.com/app-conversion-tracking/?hl=en_US.
        [ACTConversionReporter reportWithConversionID:GA_CONVERSION_ID label:GA_CONVERSION_LABEL value:@"1.000000" isRepeatable:NO];
    }
	
	// Configure our logging engine
    [ORLoggingEngine sharedInstance].company = APP_NAME;
    [ORLoggingEngine sharedInstance].device = @"iPhone";
		
	// Audio Session Category
    [self AudioSession_Default];
    
	// Orooso API Engine
#if DEBUG
    NSLog(@"API Engine - Using Test Server");
    self.apiEngine = [OREpicApiEngine sharedInstanceWithHostname:TEST_ENDPOINT portNumber:TEST_PORT useSSL:TEST_USE_SSL];

//	NSLog(@"API Engine - Using Local Server");
//    self.apiEngine = [OREpicApiEngine sharedInstanceWithHostname:LOCAL_ENDPOINT portNumber:LOCAL_PORT useSSL:LOCAL_USE_SSL];
#else
    NSLog(@"API Engine - Using Production Server");
    self.apiEngine = [OREpicApiEngine sharedInstanceWithHostname:PROD_ENDPOINT portNumber:PROD_PORT useSSL:PROD_USE_SSL];
#endif
	   
    self.apiEngine.currentAppCode = APP_CODE;
    self.isFASPInitialized = NO;
    
    __weak ORAppDelegate *weakSelf = self;
    
    [self.apiEngine setReachabilityChangedHandler:^(NetworkStatus status) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORNetworkStatusChanged" object:@(status)];

        if (status == NotReachable) {
            [weakSelf setOffline:YES];
        } else {
            [weakSelf setOffline:NO];
        }
    }];
    
    // Reload current user (if available)
    self.currentUser = [OREpicUser instanceFromLocallyStoredUser];
    if (!self.currentUser.userId) self.currentUser = nil;
    if (self.currentUser) self.apiEngine.currentUserID = self.currentUser.userId;
    
    // Aspera Engine
    [ORFaspPersistentEngine sharedInstance];

	// Google Maps
    if (GOOGLE_MAPS_KEY) {
        [GMSServices provideAPIKey:GOOGLE_MAPS_KEY];
        [GMSServices sharedServices];
    }

	// Google Engine (for url shortener)
	self.ge = [ORGoogleEngine sharedInstance];
    
    if ([prefs stringForKey:@"googleToken"] && [prefs stringForKey:@"googleTokenSecret"]) {
        [self.ge setAccessToken:[prefs stringForKey:@"googleToken"] secret:[prefs stringForKey:@"googleTokenSecret"]];
        self.ge.userID = [prefs stringForKey:@"googleUserID"];
        self.ge.userName = [prefs stringForKey:@"googleUserName"];
        self.ge.userEmail = [prefs stringForKey:@"googleUserEmail"];
        self.ge.profilePicture = [prefs stringForKey:@"googleProfilePicture"];
    }
    
    if (self.ge.isAuthenticated) {
        NSLog(@"Google Engine Initiated with Account: %@", self.ge.userEmail);
    } else {
        NSLog(@"Google Engine Initiated (not authenticated)");
    }
	
	// Foursquare
	self.places = [ORFoursquareEngine sharedInstance];
	
	// Location Manager
	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.distanceFilter = kCLDistanceFilterNone;
	self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
	self.locationManager.delegate = self;
    
    // Configure Appearance
    [self nativeBarAppearance_default];
    
	// TWITTER
    self.twitterEngine = [ORTwitterEngine sharedInstanceWithConsumerKey:TWITTER_KEY andSecret:TWITTER_SECRET];
	
    if ([prefs stringForKey:@"twitterToken"] && [prefs stringForKey:@"twitterTokenSecret"]) {
        [self.twitterEngine setAccessToken:[prefs stringForKey:@"twitterToken"] secret:[prefs stringForKey:@"twitterTokenSecret"]];
        self.twitterEngine.userId = [prefs stringForKey:@"twitterUserId"];
        self.twitterEngine.screenName = [prefs stringForKey:@"twitterScreenName"];
        self.twitterEngine.userName = [prefs stringForKey:@"twitterUserName"];
    }
    
    if (self.twitterEngine.isAuthenticated) {
        NSLog(@"Twitter Engine Initiated with Account: @%@", self.twitterEngine.screenName);
    } else {
        NSLog(@"Twitter Engine Initiated (not authenticated)");
    }
    
    if (PUSH_ENABLED) {
        // Push Notifications
        [self checkCurrentNotificationPermissions];
    }

    // Init the Root Controller
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [ORRootViewController new];
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];

    // Disable URL Cache
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:0];
    [NSURLCache setSharedURLCache:sharedCache];
    
    // Cached Engine Maintenance
    [[ORCachedEngine sharedInstance] cacheCleanup];

    // Caches path
    NSString *path = [[ORUtility cachesDirectory] stringByAppendingPathComponent:@"user_cache"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // Build 288 video recover
    if (self.needsBuild288VideoRecover) {
        [[ORFaspPersistentEngine sharedInstance] build288VideoRecover];
    }

    // Check if the app was started with a Push notification and handle it
    id notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (notification) {
        [self application:[UIApplication sharedApplication] didReceiveRemoteNotification:notification fetchCompletionHandler:nil];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    self.lastClosed = [NSDate date];
    
    if (self.isFASPInitialized) [[ORFaspPersistentEngine sharedInstance] sendToBackground];

    if (CurrentUser) {
        [ORLoggingEngine logEvent:@"Application" msg:@"Application entered background"];
        [[ORLoggingEngine sharedInstance] flushLogs];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	[[NSNotificationCenter defaultCenter] postNotificationName:@"applicationWillEnterForeground" object:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[FBSession activeSession] handleDidBecomeActive];
    
    if (([APP_NAME isEqualToString:@"Cloudcam"] || [APP_NAME isEqualToString:@"Veezy"]) && CurrentUser && self.viewController.isAlreadyVisible) {
        // Update local contacts
        [[ORDataController sharedInstance] checkAndRefreshABContacts];

        if (self.lastClosed && [[NSDate date] timeIntervalSinceDate:self.lastClosed] > SESSION_INACTIVE_TIMEOUT) {
            // After specified seconds in background, start a new session
            ApiEngine.currentSessionID = [ORUtility newGuidString];
            [self.viewController loadCurrentUser];
        } else if (self.lastClosed && [[NSDate date] timeIntervalSinceDate:self.lastClosed] > 60) {
            [self application:[UIApplication sharedApplication] performFetchWithCompletionHandler:nil];
        }

        if (self.isFASPInitialized) [[ORFaspPersistentEngine sharedInstance] resumeFromBackground];
        [ORLoggingEngine logEvent:@"Application" msg:@"Application became active"];
        
        self.lastClosed = nil;
    }
    
    [self checkFacebookState];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

    if (CurrentUser) {
        [ORLoggingEngine logEvent:@"Application" msg:@"Application will terminate"];
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([url.scheme isEqualToString:APP_URL_SCHEME]) {
        return [self.viewController handleURL:url];
    } else {
        [FBSession.activeSession setStateChangeHandler:^(FBSession *session, FBSessionState state, NSError *error) {
            [AppDelegate sessionStateChanged:session state:state error:error];
        }];

        return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    }
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if (self.isPerformingFetch) {
        if (completionHandler) completionHandler(UIBackgroundFetchResultFailed);
        return;
    }
    
    self.isPerformingFetch = YES;
    if (completionHandler) self.currentBGCompletion = completionHandler;
    
    if (([APP_NAME isEqualToString:@"Cloudcam"] || [APP_NAME isEqualToString:@"Veezy"]) && CurrentUser) {
        if (application.applicationState == UIApplicationStateBackground) NSLog(@"Started Cloudcam background fetch");
        
        [ApiEngine userCountsWithCompletion:^(NSError *error, OREpicUserCounts *counts) {
            if (error) NSLog(@"Error: %@", error);
            if (counts) {
                if (CurrentUser.notificationCount != counts.notifications && !self.isUpdatingNotifications) {
                    self.isUpdatingNotifications = YES;
                    NSLog(@"Fetching User Notifications (%d -> %d)", CurrentUser.notificationCount, counts.notifications);
                    
                    [[ORDataController sharedInstance] userNotificationsForceReload:YES cacheOnly:NO completion:^(NSError *error, BOOL final, NSArray *feed) {
                        if (error) NSLog(@"Error: %@", error);
                        if (final) {
                            self.isUpdatingNotifications = NO;
                            
                            if (application.applicationState == UIApplicationStateActive) {
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"ORActivityReload" object:nil];
                            }
                            
                            [self backgroundFetchDoneWithData:YES];
                        }
                    }];
                }

                if (CurrentUser.feedCount != counts.feed && !self.isUpdatingFeed) {
                    self.isUpdatingFeed = YES;
                    NSLog(@"Fetching User Feed (%d -> %d)", CurrentUser.feedCount, counts.feed);
                    
                    [[ORDataController sharedInstance] userFeedForceReload:YES cacheOnly:NO completion:^(NSError *error, BOOL final, NSArray *feed) {
                        if (error) NSLog(@"Error: %@", error);
                        if (final) {
                            self.isUpdatingFeed = NO;

                            if (application.applicationState == UIApplicationStateActive) {
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"ORHomeReload" object:nil];
                            }

                            [self backgroundFetchDoneWithData:YES];
                        }
                    }];
                }
                
                if (CurrentUser.followersCount != counts.followers && !self.isUpdatingFollowers) {
                    self.isUpdatingFollowers = YES;
                    NSLog(@"Fetching User Followers (%d -> %d)", CurrentUser.followersCount, counts.followers);
                    
                    [CurrentUser reloadFollowersForceReload:YES completion:^(NSError *error) {
                        if (error) NSLog(@"Error: %@", error);
                        self.isUpdatingFollowers = NO;
                        [self backgroundFetchDoneWithData:YES];
                    }];
                }
                
                [CurrentUser updateCounts:counts];
                [CurrentUser saveLocalUser];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ORUpdateBadge" object:nil];
            }
            
            [self backgroundFetchDoneWithData:NO];
        }];
    } else {
        [self backgroundFetchDoneWithData:NO];
    }
}

- (void)backgroundFetchDoneWithData:(BOOL)data
{
    if (self.isUpdatingFeed || self.isUpdatingNotifications || self.isUpdatingFollowers) return;
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) NSLog(@"Background fetch is done. Data: %d", data);
    
    if (self.currentBGCompletion) {
        if (data) {
            self.currentBGCompletion(UIBackgroundFetchResultNewData);
        } else {
            self.currentBGCompletion(UIBackgroundFetchResultNoData);
        }

        self.currentBGCompletion = nil;
        self.isPerformingFetch = NO;
    }
}

#pragma mark - Navigation Bar Appearance

- (void)nativeBarAppearance_default
{
	[[UINavigationBar appearance] setBarTintColor:APP_COLOR_PRIMARY];
    [[UIToolbar appearance] setBarTintColor:APP_COLOR_PRIMARY];
    
    if ([APP_NAME isEqualToString:@"Veezy"]) {
        NSShadow *shadow = [NSShadow new];
        [shadow setShadowColor: [UIColor clearColor]];
        [shadow setShadowOffset: CGSizeMake(0.0f, 0.0f)];
        
        NSDictionary *textTitleOptions = @{
                                           NSForegroundColorAttributeName: [UIColor blackColor],
                                           NSShadowAttributeName: shadow,
                                           NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:30.0f],
                                           };
        
        [[UINavigationBar appearance] setTitleTextAttributes:textTitleOptions];
        [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
        [[UITabBar appearance] setBarTintColor:[UIColor blackColor]];
        [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"solid-header-yellow"] forBarMetrics:UIBarMetricsDefault];
//		[[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"hex-header-yellow"] forBarMetrics:UIBarMetricsDefault];
		
    } else if ([APP_NAME isEqualToString:@"Cloudcam"]) {
        NSShadow *shadow = [NSShadow new];
        [shadow setShadowColor: [UIColor clearColor]];
        [shadow setShadowOffset: CGSizeMake(0.0f, 0.0f)];
        
        NSDictionary *textTitleOptions = @{
                                           NSForegroundColorAttributeName: [UIColor whiteColor],
                                           NSShadowAttributeName: shadow,
                                           NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:30.0f],
                                           };
        
        [[UINavigationBar appearance] setTitleTextAttributes:textTitleOptions];
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
        [[UINavigationBar appearance] setBarTintColor:APP_COLOR_PRIMARY];
        [[UITabBar appearance] setBarTintColor:APP_COLOR_PRIMARY];
    } else {
        NSShadow *shadow = [NSShadow new];
        [shadow setShadowColor: [UIColor clearColor]];
        [shadow setShadowOffset: CGSizeMake(0.0f, 0.0f)];
        
        NSDictionary *textTitleOptions = @{
                                           NSForegroundColorAttributeName: [UIColor whiteColor],
                                           NSShadowAttributeName: shadow,
                                           NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:30.0f],
                                           };
        
        [[UINavigationBar appearance] setTitleTextAttributes:textTitleOptions];
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    }
}

- (void)nativeBarAppearance_nativeShare
{
	// Set to system Defaults
	[[UINavigationBar appearance] setTitleTextAttributes:nil];
	[[UINavigationBar appearance] setBarTintColor:nil];
	[[UINavigationBar appearance] setTintColor:nil];
	[[UINavigationBar appearance] setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
	

	
//	NSShadow *shadow = [NSShadow new];
//	[shadow setShadowColor: [UIColor clearColor]];
//	[shadow setShadowOffset: CGSizeMake(0.0f, 0.0f)];
//	
//    NSDictionary *textTitleOptions = @{
//									   NSForegroundColorAttributeName: [UIColor darkGrayColor],
//									   NSShadowAttributeName: shadow,
//									   NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:30.0f],
//									   };
//	
//    [[UINavigationBar appearance] setTitleTextAttributes:textTitleOptions];
//	[[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
//	[[UITabBar appearance] setBarTintColor:[UIColor blackColor]];
//	[[UIToolbar appearance] setBarTintColor:[UIColor blackColor]];
//	[[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
}

#pragma mark - Interface Orientation

- (UIInterfaceOrientation)interfaceOrientation
{
    return self.viewController.interfaceOrientation;
}

- (void)lockOrientation
{
    switch (self.viewController.interfaceOrientation) {
        case UIInterfaceOrientationUnknown:
        case UIInterfaceOrientationPortrait:
            self.viewController.currentSupportedOrientations = UIInterfaceOrientationMaskPortrait;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            self.viewController.currentSupportedOrientations = UIInterfaceOrientationMaskLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            self.viewController.currentSupportedOrientations = UIInterfaceOrientationMaskLandscapeRight;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            self.viewController.currentSupportedOrientations = UIInterfaceOrientationMaskPortraitUpsideDown;
            break;
    }
}

- (void)unlockOrientation
{
    self.viewController.currentSupportedOrientations = UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)forcePortraitWithCompletion:(void (^)())completion
{
    self.viewController.currentSupportedOrientations = UIInterfaceOrientationMaskPortrait;
    
    UIViewController *vc = [[UIViewController alloc] init];
    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
    
    if (self.viewController.presentedViewController) {
        [self.viewController.presentedViewController presentViewController:nc animated:NO completion:nil];
        [self.viewController.presentedViewController dismissViewControllerAnimated:NO completion:completion];
    } else {
        [self.viewController presentViewController:nc animated:NO completion:nil];
        [self.viewController dismissViewControllerAnimated:NO completion:completion];
    }
}

- (void)forcePortrait
{
    self.viewController.currentSupportedOrientations = UIInterfaceOrientationMaskPortrait;
    
    UIViewController *vc = [[UIViewController alloc] init];
    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
    
    if (self.viewController.presentedViewController) {
        [self.viewController.presentedViewController presentViewController:nc animated:NO completion:nil];
        [self.viewController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    } else {
        [self.viewController presentViewController:nc animated:NO completion:nil];
        [self.viewController dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)forceLandscape
{
    self.viewController.currentSupportedOrientations = UIInterfaceOrientationMaskLandscapeRight;
    
    UIViewController *vc = [[UIViewController alloc] init];
    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];

    if (self.viewController.presentedViewController) {
        [self.viewController.presentedViewController presentViewController:nc animated:NO completion:nil];
        [self.viewController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    } else {
        [self.viewController presentViewController:nc animated:NO completion:nil];
        [self.viewController dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)forceLandscapeWithCompletion:(void (^)())completion
{
    self.viewController.currentSupportedOrientations = UIInterfaceOrientationMaskLandscapeRight;
    
    UIViewController *vc = [[UIViewController alloc] init];
    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
    
    if (self.viewController.presentedViewController) {
        [self.viewController.presentedViewController presentViewController:nc animated:NO completion:nil];
        [self.viewController.presentedViewController dismissViewControllerAnimated:NO completion:completion];
    } else {
        [self.viewController presentViewController:nc animated:NO completion:nil];
        [self.viewController dismissViewControllerAnimated:NO completion:completion];
    }
}

#pragma mark - Push Notifications

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSUInteger dataLength = [deviceToken length];
    NSMutableString *deviceID = [NSMutableString stringWithCapacity:dataLength*2];
    const unsigned char *dataBytes = [deviceToken bytes];
    for (NSInteger idx = 0; idx < dataLength; ++idx) {
        [deviceID appendFormat:@"%02x", dataBytes[idx]];
    }
    
    ApiEngine.currentDeviceId = deviceID;
    
    if (CurrentUser && ![CurrentUser.deviceID isEqualToString:deviceID]) {
        CurrentUser.deviceID = deviceID;
        [ApiEngine updateDeviceId:CurrentUser.deviceID forUser:CurrentUser.userId cb:nil];
    }
    
    self.pushNotificationsEnabled = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORPushEnabled" object:nil];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    #if !(TARGET_IPHONE_SIMULATOR)
    NSLog(@"Failed to register for Push: %@", error);
    #endif
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORPushRegistrationFailed" object:nil];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if ([userInfo[@"type"] isEqualToString:@"epic_usertyping"]) {
        if (completionHandler) completionHandler(UIBackgroundFetchResultNoData);
    } else {
        [self application:application performFetchWithCompletionHandler:completionHandler];
    }
    
    [self application:application didReceiveRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if (application.applicationState == UIApplicationStateInactive) {
        // For now we'll always clear the badge when the user taps a notification
        int badge = 0;
        
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badge];

        [self.viewController handleNotification:userInfo];
    } else if (application.applicationState == UIApplicationStateActive) {
        [self application:application performFetchWithCompletionHandler:nil];
        [self.viewController presentNotification:userInfo];
    }
}

- (void)checkCurrentNotificationPermissions
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        if (![[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
            self.pushNotificationsEnabled = NO;
        } else {
            self.pushNotificationsEnabled = YES;
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge) categories:nil]];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
    } else {
        UIRemoteNotificationType notificationTypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        
        if (notificationTypes == UIRemoteNotificationTypeNone) {
            self.pushNotificationsEnabled = NO;
        } else {
            self.pushNotificationsEnabled = YES;
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];
        }
    }
#else
    UIRemoteNotificationType notificationTypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    
    if (notificationTypes == UIRemoteNotificationTypeNone) {
        self.pushNotificationsEnabled = NO;
    } else {
        self.pushNotificationsEnabled = YES;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];
    }
#endif
}

- (void)registerForPushNotifications
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge)];
    }
#else
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge)];
#endif
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    self.isAllowedToUseLocationManager = (status == kCLAuthorizationStatusAuthorized || status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways);
	if (self.isAllowedToUseLocationManager) {
		[self updateLocation];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ORLocationPermissionGranted" object:nil];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ORLocationPermissionNotGranted" object:nil];
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	DLog(@"LocationManager failed: %@", error);
    
    if (error.code == kCLErrorDenied) {
        [manager stopUpdatingLocation];
        self.isUpdatingLocation = NO;
        self.isAllowedToUseLocationManager = NO;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORLocationUpdated" object:nil];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (!locations || locations.count == 0) return;
	self.lastKnownLocation = [locations lastObject];
   
    // Only stop and notify if the location is recent
    if ([[NSDate date] timeIntervalSinceDate:self.lastKnownLocation.timestamp] < 300) {
        [manager stopUpdatingLocation];
        self.isUpdatingLocation = NO;

        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORLocationUpdated" object:self.lastKnownLocation];
        NSLog(@"Location Updated: %@", self.lastKnownLocation);
    }
}

- (void)requestLocationPermission
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        self.isAllowedToUseLocationManager = NO;
    } else {
        self.isAllowedToUseLocationManager = YES;
        [self updateLocation];
    }
#else
    self.isAllowedToUseLocationManager = YES;
    [self updateLocation];
#endif
}

- (void)updateLocation
{
    if (self.isUpdatingLocation) {
        NSLog(@"Warn: Already updating location, can't update now");
        return;
    }
    
    self.isUpdatingLocation = YES;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
}

#pragma mark - View Styling

- (void)styleView:(UIView*)view {
	
	UIColor *targetColor;

	if ([view isKindOfClass:[UIButton class]]) {
		targetColor = ((UIButton*)view).titleLabel.textColor;
	} else {
		targetColor = APP_COLOR_PRIMARY;
	}
	
	view.layer.borderColor = targetColor.CGColor;
	view.layer.borderWidth = 0.7f;
}

- (BOOL)hasInternetConnection
{
	return _varIsOnline;
}

- (void)setOffline:(BOOL)offline
{
    [self.viewController setOfflineBannerVisible:offline];

    if (offline) {
        if (_varIsOnline != NO) {
            _varIsOnline = NO;
            DLog(@"NETWORK STATE: **** OFFLINE ****")
        }
    } else {
        if (_varIsOnline != YES) {
            _varIsOnline = YES;
            DLog(@"NETWORK STATE: $$$$ ONLINE $$$$")
        }

        if (CurrentUser && ApiEngine.needsSessionStart) {
            ApiEngine.needsSessionStart = NO;
            [ApiEngine startSessionWithCB:^(NSError *error, NSString *result) {
                ApiEngine.needsSessionStart = (error != nil);
            }];
        }
    }
}

#pragma mark - Audio Session Configuration

- (void)AudioSession_Default
{
	NSError *error = nil;
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:&error];
	if (error) NSLog(@"Failed to set audio category: %@", error.localizedDescription);
    
    error = nil;
	[[AVAudioSession sharedInstance] setMode:AVAudioSessionModeDefault error:&error];
	if (error) NSLog(@"Failed to set audio mode: %@", error.localizedDescription);
}

- (void)AudioSession_Capture
{
	NSError *error = nil;
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:&error];
	if (error) NSLog(@"Failed to set audio category: %@", error.localizedDescription);
    
    error = nil;
	[[AVAudioSession sharedInstance] setMode:AVAudioSessionModeVideoRecording error:&error];
	if (error) NSLog(@"Failed to set audio mode: %@", error.localizedDescription);
}

- (void)AudioSession_AudioMonitor
{
	NSError *error = nil;
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
	if (error) NSLog(@"Failed to set audio category: %@", error.localizedDescription);
	
	error = nil;
	[[AVAudioSession sharedInstance] setMode:AVAudioSessionModeMeasurement error:&error];
	if (error) NSLog(@"Failed to set audio mode: %@", error.localizedDescription);
}

#pragma mark - Facebook

- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    if (!error && state == FBSessionStateOpen) {
        if (self.isLinkingFacebook) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORFacebookSignedIn" object:self];
        } else {
            [self.viewController handleFacebookSignIn];
        }
        
        return;
    }
    
    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed) {
        if (self.isLinkingFacebook) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORFacebookSignedOut" object:self];
        } else {
            [self.viewController handleFacebookSignOut];
        }
    }
    
    // Handle errors
    if (error) {
        NSString *alertText;
        NSString *alertTitle;

        // If the error requires people using an app to make an action outside of the app in order to recover
        if ([FBErrorUtility shouldNotifyUserForError:error] == YES) {
            alertTitle = @"Permission Needed";
            alertText = [FBErrorUtility userMessageForError:error];
            
            self.alertView = [[UIAlertView alloc] initWithTitle:alertTitle message:alertText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            self.alertView.tag = 99;
            [self.alertView show];
        } else {
            
            // If the user cancelled login, do nothing
            if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
                NSLog(@"User cancelled login");
            } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
                alertTitle = @"Session Error";
                alertText = @"Your current Facebook session is no longer valid. Please connect Facebook again.";

                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            } else {
                //Get more error information from the error
                NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
                
                // Show the user an error message
                alertTitle = @"Something went wrong";
                NSString *msg = ([errorInformation objectForKey:@"message"]) ?: @"5530";
                alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", msg];

                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }
        
        // Remove FB token data from user
        CurrentUser.facebookToken = nil;
        CurrentUser.facebookTokenData = nil;
        [CurrentUser saveLocalUser];
        
        // Clear this token
        [FBSession.activeSession closeAndClearTokenInformation];
        
        if (self.isLinkingFacebook) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORFacebookSignedOut" object:self];
        } else {
            [self.viewController handleFacebookSignOut];
        }
    }
}

- (void)checkFacebookState
{
    if (self.alertView && self.alertView.tag == 99) {
        [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:NO];
        [self facebookSignInAllowLoginUI:YES];
    }
}

- (void)facebookSignInAllowLoginUI:(BOOL)allowLoginUI
{
    FBSessionStateHandler completionHandler = ^(FBSession *session, FBSessionState status, NSError *error) {
        [self sessionStateChanged:session state:status error:error];
    };
    
    NSArray *permissions = @[@"public_profile", @"user_friends", @"email"];
    
    if ([FBSession activeSession].state == FBSessionStateCreatedTokenLoaded) {
        [FBSession openActiveSessionWithReadPermissions:permissions allowLoginUI:allowLoginUI completionHandler:completionHandler];
    } else {
        [FBSession.activeSession closeAndClearTokenInformation];
        
        [FBSession renewSystemCredentials:^(ACAccountCredentialRenewResult result, NSError *error) {
            if (error) NSLog(@"%@", error);
        }];
        
        [FBSession setActiveSession:nil];
        
        if (CurrentUser.facebookTokenData) {
            NSData *data = [NSData dataFromBase64String:CurrentUser.facebookTokenData];
            if (data) {
                NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                FBAccessTokenData *accessToken = [FBAccessTokenData createTokenFromDictionary:dict];
                
                FBSession *fbSession = [[FBSession alloc] initWithPermissions:permissions];
                [FBSession setActiveSession:fbSession];
                [fbSession openFromAccessTokenData:accessToken completionHandler:completionHandler];
                return;
            }
        }
        
        if (allowLoginUI) {
            FBSession *fbSession = [[FBSession alloc] initWithPermissions:permissions];
            [FBSession setActiveSession:fbSession];
            [fbSession openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent completionHandler:completionHandler];
        } else {
            [FBSession openActiveSessionWithReadPermissions:permissions allowLoginUI:NO completionHandler:completionHandler];
        }
    }
}

#pragma mark - Version Update

- (void)updateToVersion:(NSString *)currentVersion fromVersion:(NSString *)lastUpdatedVersion
{
    NSLog(@"Updating the app from version %@ to version %@...", lastUpdatedVersion, currentVersion);
    
    if (!lastUpdatedVersion) {
        // First update, let's do the Core Data nuke (Aspera issue)
        [ORFaspPersistentEngine removeCoreDataFiles];
    }

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    if (([APP_NAME isEqualToString:@"Cloudcam"] || [APP_NAME isEqualToString:@"Veezy"])) {
        BOOL didRunRecover = [prefs boolForKey:@"Build288VideoRecover"];
        
        if (!didRunRecover) {
            self.needsBuild288VideoRecover = YES;
            [prefs setBool:YES forKey:@"Build288VideoRecover"];
        }
    }

    // Store the current version as last updated version
    [prefs setObject:currentVersion forKey:@"lastUpdatedVersion"];
    [prefs synchronize];
}

#pragma mark - Handle Status Bar Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    CGPoint location = [[[event allTouches] anyObject] locationInView:[self window]];
    if(location.y > 0 && location.y < 20) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORStatusBarTapped" object:nil];
    }
}

#pragma mark - Logging

- (void)gaLogWithCategory:(NSString*)cat andAction:(NSString*)act andLabel:(NSString*)lab andValue:(NSNumber*)num
{
	[self.ga send:[[GAIDictionaryBuilder createEventWithCategory:cat				// Event category (required)
														  action:act				// Event action (required)
														   label:lab				// Event label
														   value:num] build]];		// Event value
}

#pragma mark - Device Info

- (NSString*)machineName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

- (NSString*)platformString
{
    NSString *platform = [self machineName];
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5c (GSM)";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5c (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5s (GSM)";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5s (GSM+CDMA)";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    if ([platform isEqualToString:@"iPad4,2"])      return @"iPad Air (Cellular)";
    if ([platform isEqualToString:@"iPad4,4"])      return @"iPad mini 2G (WiFi)";
    if ([platform isEqualToString:@"iPad4,5"])      return @"iPad mini 2G (Cellular)";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    return platform;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == alertView.cancelButtonIndex) return;
    
	switch (alertView.tag) {
		case 1: {
			[self.viewController presentSignInWithMessage:@"Sign-in Now" completion:nil];
			break;
        }
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView == self.alertView) {
        self.alertView.delegate = nil;
        self.alertView = nil;
    }
}

#pragma mark - GCDWebServer

- (NSString *)currentServerVideoId
{
    return self.webServerVideoId;
}

- (BOOL)startServerForVideo:(NSString *)videoId
{
    // Already running local web server for this video
    if (self.webServer && [self.webServerVideoId isEqualToString:videoId]) return NO;
    
    if (self.webServer) {
        [self.webServer stop];
        self.webServer = nil;
    }
    
    [GCDWebServer setLogLevel:kGCDWebServerLogLevel_Warning];
    
    self.webServerVideoId = videoId;
    self.webServer = [[GCDWebServer alloc] init];
    
    NSString *path = [[ORUtility documentsDirectory] stringByAppendingPathComponent:videoId];
    [self.webServer addGETHandlerForBasePath:@"/" directoryPath:path indexFilename:nil cacheAge:3600 allowRangeRequests:YES];
    [self.webServer startWithPort:8080 bonjourName:nil];
    
    return YES;
}

- (BOOL)stopServerForVideo:(NSString *)videoId
{
    if (!videoId) return NO;
    
    if ([self.webServerVideoId isEqualToString:videoId] && self.webServer) {
        [self.webServer stop];
        
        self.webServer = nil;
        self.webServerVideoId = nil;
        
        return YES;
    } else {
        return NO;
    }
}

@end
