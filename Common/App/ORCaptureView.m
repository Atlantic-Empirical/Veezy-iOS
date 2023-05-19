
//  ORCapture.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 10/23/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>
#import "ORCaptureView.h"
#import "ORAVLiveProcessor.h"
#import "ORAVURLProcessor.h"
#import "ORFaspPersistentEngine.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import "ORFoursquareVenue.h"
#import "ORViewerCell.h"
#import "ORCapturePreview.h"
#import "ORBroadcastBehaviorView.h"
#import "OREpicVideo.h"
#import "ORHourMinuteSecond.h"
#import "ORTwitterPlace.h"
#import "ORGoProSourceView.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "ORFoursquareVenueLocation.h"
#import "ORGoProEngine.h"
#import "ORGoProPreview.h"
#import "ORMapView.h"
#import "ORMicrophonePermissionView.h"
#import "ORPopDownView.h"
#import "OREpicUserSettings.h"
#import "ORNavigationController.h"
#import "ORPermissionsEngine.h"

#define HEADER_FOOTER_TIMEOUT 5.0f
#define PORTRAIT_STOP_RECORDING_DELAY 0.5f

@interface ORCaptureView () <CLLocationManagerDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, ORGoProEngineDelegate, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate>

@property (nonatomic, strong) ORAVLiveProcessor *videoProcessor;
@property (nonatomic, strong) NSTimer *animationTimer;
@property (nonatomic, strong) NSTimer *vuTimer;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSOrderedSet *viewers;
@property (nonatomic, strong) NSTimer *liveTimer;
@property (nonatomic, assign, readonly) BOOL headerOrFooterIsOpen;
@property (nonatomic, strong) UIAlertView *rotateToStopRecordingAlert;

@property (nonatomic, readonly) BOOL wereLive;
@property (nonatomic, assign) BOOL isZooming;
@property (nonatomic, assign) CGFloat startZoomFactor;
@property (nonatomic, assign) CGFloat currentZoomFactor;
@property (nonatomic, assign) CGFloat lastZoomScale;
@property (nonatomic, assign) CGFloat lastZoomPercent;
@property (nonatomic, assign) CGFloat minZoomFactor;
@property (nonatomic, assign) CGFloat maxZoomFactor;

@property (nonatomic, assign) BOOL isInitialized;
@property (nonatomic, assign) BOOL isPreviewing;
@property (nonatomic, assign) BOOL isWaitingForLive;

@property (nonatomic, strong) ORBroadcastBehaviorView *broadcastOverlay;
@property (nonatomic, strong) ORMicrophonePermissionView *micPermissionOverlay;

@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) UIAlertView *alertRotateNotification;

// GoPro
@property (nonatomic, assign) ORCaptureMode captureMode;
@property (nonatomic, strong) ORGoProEngine *gpe;
@property (nonatomic, strong) ORGoProPreview *viewGoPro;

@property (nonatomic, strong) UIColor *viewStartBackground;
@property (nonatomic, assign) CGPoint lockedPoint;
@property (nonatomic, assign) BOOL focusIsLocked;

@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) UIInterfaceOrientation estimatedOrientation;

@end


@implementation ORCaptureView

static NSString *viewerCell = @"viewerCell";

static void * const MyAdjustingFocusObservationContext = (void*)&MyAdjustingFocusObservationContext;
static void * const MyAdjustingExposureObservationContext = (void*)&MyAdjustingExposureObservationContext;

- (void)dealloc
{
    self.alertView.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopAnimationTimer];
    [self stopVUTimer];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Capture";
	self.screenName = @"Capture";
        
	[self registerForNotifications];

    self.videoProcessor = [[ORAVLiveProcessor alloc] init];
    self.videoProcessor.lastKnownOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (CAPTURE_ENABLED) {
        [self.videoProcessor prepareCaptureSession];
        self.viewVideoPreview.session = self.videoProcessor.captureSession;
        [(AVCaptureVideoPreviewLayer *)self.viewVideoPreview.layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    }

	// Setup View Visibility
	self.viewDuringCapture.alpha = 0.0f;
	self.btnStart.layer.cornerRadius = self.btnStart.frame.size.height / 2;
    self.btnStop.layer.cornerRadius = self.btnStop.frame.size.height / 2;
	
	// Focus Ring
	self.viewFocusRing.layer.borderColor = [UIColor colorWithRed:235.0/255.0 green:195.0/255.0 blue:0.0f alpha:1.0f].CGColor;
	self.viewFocusRing.layer.borderWidth = 0.5f;
	self.viewFocusRing.layer.cornerRadius = 4.0f;
	self.viewFocusRing.alpha = 0.0f;
    
    self.lblFocus.backgroundColor = [UIColor colorWithRed:235.0/255.0 green:195.0/255.0 blue:0.0f alpha:1.0f];
    self.lblFocus.layer.cornerRadius = 2.0f;
    
	// Corners
	self.viewStart.layer.cornerRadius = 14.0f;
	self.viewLiveIndicator.layer.cornerRadius = self.viewLiveIndicator.frame.size.height / 2;
	self.btnTorch.layer.cornerRadius = 6.0f;
	self.btnSwapCameras.layer.cornerRadius = 6.0f;
	self.btnStopAux.layer.cornerRadius = 6.0f;
	self.viewLiveIndicator.layer.cornerRadius = 6.0f;

	self.viewStartBackground = self.viewStart.backgroundColor;
	
    self.captureMode = ORCaptureModeCamera;
	self.isInitialized = YES;
    
	// Viewers list
	[self collapseViewerAvatarTable];
	[self.tblViewers registerNib:[UINib nibWithNibName:@"ORViewerCell" bundle:nil] forCellReuseIdentifier:viewerCell];
		
	// Rule of thirds
    self.viewRotParent.hidden = YES;
	
	[self setLiveIndicatorVisible:NO];
	
    if (!CAPTURE_ENABLED) {
        self.viewStart.hidden = YES;
        self.btnTorch.hidden = YES;
        self.btnSwapCameras.hidden = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"Capture: Will Appear");
    
    if (self.captureMode == ORCaptureModeCamera && RVC.currentState == ORUIStateCamera) {
        if (CurrentUser) [self startPreview];
    }
    
    [self configureForOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0.0f];
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"Capture: Did Disappear");
    
    if (self.captureMode == ORCaptureModeCamera && RVC.currentState == ORUIStateCamera) {
        [self performSelector:@selector(stopPreview) withObject:nil afterDelay:60.0f];
    }
}

#pragma mark - Orientation

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self configureForOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
}

- (void)configureForOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    self.videoProcessor.lastKnownOrientation = orientation;
    [[(AVCaptureVideoPreviewLayer *)self.viewVideoPreview.layer connection] setVideoOrientation:(AVCaptureVideoOrientation)orientation];
    
	if (UIInterfaceOrientationIsLandscape(orientation)) {
        if (AppDelegate.isRecording) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopRecording) object:nil];
        } else {
            [self stopAnimationTimer];
            [self stopVUTimer];
            
            self.btnTorch.alpha = 1.0f;
            self.btnSwapCameras.alpha = 1.0;
            
//            CGRect f = self.btnSwapCameras.frame;
//            f.origin.y -= (f.size.height + 8.0f);
//            self.btnTorch.frame = f;
//            self.btnTorch.autoresizingMask = self.btnSwapCameras.autoresizingMask;
        }

		if (self.alertRotateNotification) {
			[self.alertRotateNotification dismissWithClickedButtonIndex:0 animated:YES];
		}
		
		self.imgRotateRecord.image = [UIImage imageNamed:@"start-recording-icon-white-wire-glow-170x"];
		self.imgRotateC2A.hidden = YES;
		self.imgRotateRecord.alpha = 0.8f;
		self.viewStart.backgroundColor = [UIColor clearColor];
		self.lblActionPrompt.text = @"RECORD";

		CGRect f = self.lblActionPrompt.frame;
		f.origin.y = self.imgRotateRecord.frame.origin.y + ((self.imgRotateRecord.frame.size.height / 2) - (self.lblActionPrompt.frame.size.height/2));
		self.lblActionPrompt.frame = f;
	} else {
        if (self.broadcastOverlay) {
            [self hideBroadcastOverlayAndMarkAsSent:NO];
        }
		
        if (self.rotateToStopRecordingAlert) {
			[self.rotateToStopRecordingAlert dismissWithClickedButtonIndex:0 animated:YES];
		}

        self.btnTorch.alpha = 0.0f;
        self.btnSwapCameras.alpha = 0.0;
		self.viewDuringCapture.alpha = 0.0f;
        
        if (AppDelegate.isRecording) {
            if (self.captureMode == ORCaptureModeCamera) {
                // Don't stop on rotate for GoPro
                [self performSelector:@selector(stopRecording) withObject:nil afterDelay:PORTRAIT_STOP_RECORDING_DELAY];
            }
        }
		
		self.imgRotateRecord.image = [UIImage imageNamed:@"start-recording-icon-white-wire-glow-170x"];
		self.imgRotateC2A.hidden = NO;
		self.imgRotateRecord.alpha = 0.8f;
//		self.imgRotateRecord.image = nil; // [UIImage imageNamed:@"home-rotate-170x"];
//		self.imgRotateRecord.alpha = 1.0f;
		self.viewStart.backgroundColor = self.viewStartBackground;
		self.lblActionPrompt.text = @""; // @"Turn & Record";
		
		CGRect f = self.lblActionPrompt.frame;
		f.origin.y = 144;
		self.lblActionPrompt.frame = f;

	}
	
	// Rule-of-thirds
    [self configureRuleOfThirds];
    
    [UIView animateWithDuration:duration delay:0.0f
						options:UIViewAnimationOptionAllowUserInteraction
					 animations:^{
						 self.btnStart.alpha = (!AppDelegate.isRecording) ? 0.5f : 0.0f;
						 self.viewStart.alpha = (!AppDelegate.isRecording) ? 1.0f : 0.0f;
					 } completion:nil];
}

- (void)startMotionDetect
{
    [self stopMotionDetect];
    self.motionManager = [[CMMotionManager alloc] init];
    
    __weak ORCaptureView *weakSelf = self;
    
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
            weakSelf.estimatedOrientation = UIInterfaceOrientationLandscapeLeft;
            if (weakSelf.startTime == 0) weakSelf.startTime = CACurrentMediaTime();
            CFTimeInterval elapsedTime = CACurrentMediaTime() - weakSelf.startTime;
            
            if (elapsedTime > 0.2f) {
                NSLog(@"Landscape detected, stopping motion detector");

                if (weakSelf.alertRotateNotification) {
                    [weakSelf.alertRotateNotification dismissWithClickedButtonIndex:0 animated:YES];
                }

                [weakSelf stopMotionDetect];
            }
        } else {
            weakSelf.estimatedOrientation = UIInterfaceOrientationPortrait;
            weakSelf.startTime = 0;
        }
    }];
}

- (void)stopMotionDetect
{
    if (self.motionManager) {
        [self.motionManager stopDeviceMotionUpdates];
        self.motionManager = nil;
    }
}

#pragma mark - Preview & Recording Control

- (void)startPreview
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopPreview) object:nil];

    if (!CAPTURE_ENABLED) return;
    if (!self.isInitialized) return;
    if (self.isPreviewing) return;
    if (self.micPermissionOverlay) return;
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) return;
    
    // Camera Permission
    ORPermissionState camera = [[ORPermissionsEngine sharedInstance] currentCameraPermissionState];
    if (camera == ORPermissionStateNotDetermined) {
        [[ORPermissionsEngine sharedInstance] requestCameraPermissionWithCompletion:^(BOOL granted) {
            [self startPreview];
        }];
        
        return;
    } else if (camera != ORPermissionStateAuthorized) {
        [AppDelegate forcePortrait];
        if (self.micPermissionOverlay) [self.micPermissionOverlay.view removeFromSuperview];
        self.micPermissionOverlay = [ORMicrophonePermissionView new];
        self.micPermissionOverlay.view.frame = self.view.bounds;
        self.micPermissionOverlay.parent = self;
        [self.micPermissionOverlay configureForCamera];
        [self.view addSubview:self.micPermissionOverlay.view];
        self.isPreviewing = NO;
        return;
    }

    // Microphone Permission
    ORPermissionState microphone = [[ORPermissionsEngine sharedInstance] currentMicrophonePermissionState];
    if (microphone == ORPermissionStateNotDetermined) {
        [[ORPermissionsEngine sharedInstance] requestMicrophonePermissionWithCompletion:^(BOOL granted) {
            [self startPreview];
        }];
        
        return;
    } else if (microphone != ORPermissionStateAuthorized) {
        [AppDelegate forcePortrait];
        if (self.micPermissionOverlay) [self.micPermissionOverlay.view removeFromSuperview];
        self.micPermissionOverlay = [ORMicrophonePermissionView new];
        self.micPermissionOverlay.view.frame = self.view.bounds;
        self.micPermissionOverlay.parent = self;
        [self.micPermissionOverlay configureForMicrophone];
        [self.view addSubview:self.micPermissionOverlay.view];
        self.isPreviewing = NO;
        return;
    }

    self.isPreviewing = YES;
    self.viewViewerCount.hidden = YES;
    
    // TODO: Add a viewfinder opening animation here
    [self.videoProcessor.captureSession startRunning];
    NSLog(@"Camera Preview Started");
    
    if ([self.videoProcessor.videoCaptureDevice respondsToSelector:@selector(isAutoFocusRangeRestrictionSupported)] && self.videoProcessor.videoCaptureDevice.autoFocusRangeRestrictionSupported) {
        if ([self.videoProcessor.videoCaptureDevice lockForConfiguration:nil]) {
            self.videoProcessor.videoCaptureDevice.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionFar;
            [self.videoProcessor.videoCaptureDevice unlockForConfiguration];
        }
    }
}

- (void)stopPreview
{
    if (!self.isPreviewing) return;
    if (self.videoProcessor.isInConfiguration) return;
    
    // TODO: Add a viewfinder closing animation here
    [self.videoProcessor.captureSession stopRunning];
    NSLog(@"Camera Preview Stopped");
    
    self.isPreviewing = NO;
}

- (void)startRecording
{
    if (self.captureMode == ORCaptureModeGoPro) {
        [self.gpe startRecording];
    } else {
        if (self.videoProcessor.isRecording) {
            NSLog(@"Already recording, can't start right now.");
            return;
        }
        
        [AppDelegate AudioSession_Capture];
        
        [self.videoProcessor startRecording];
        self.currentVideo = self.videoProcessor.currentVideo;
        [self recordingDidStart];
    }
}

- (void)recordingDidStart
{
    AppDelegate.isRecording = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORRecordingStarted" object:@(self.videoProcessor.lastKnownOrientation)];

	[self collapseViewerAvatarTable];
	[self startLiveMonitor];
	self.viewers = nil;
    
    self.viewStart.alpha = 0.0f;
	self.btnBroadcast.enabled = YES;

    NetworkStatus status = ApiEngine.currentNetworkStatus;
    if (status == NotReachable || (status == ReachableViaWWAN && CurrentUser.settings.wifiTransferOnly)) {
        self.btnBroadcast.hidden = YES;
		self.imgLiveIcon.hidden = YES;
    } else {
        self.btnBroadcast.hidden = NO;
		self.imgLiveIcon.hidden = NO;
		self.lblLiveStatus.hidden = YES;
    }
    
	self.viewDuringCapture.alpha = 1.0f;
	self.lblTimer.text = @"0:00";
    
    // Disable the idle timer while we are recording
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    if (AppDelegate.lastKnownLocation) {
        self.currentVideo.latitude = AppDelegate.lastKnownLocation.coordinate.latitude;
        self.currentVideo.longitude = AppDelegate.lastKnownLocation.coordinate.longitude;
    }
    
    if (self.selectedPlace) {
        self.currentVideo.locationFriendlyName = self.selectedPlace.name;
        self.currentVideo.locationIsCity = self.selectedPlace.isCity;
    }
    
    // Pre-capture
    if (RVC.tempVideo.isAvailable) {
        self.currentVideo.name = RVC.tempVideo.name;
        self.currentVideo.locationFriendlyName = RVC.tempVideo.locationFriendlyName;
        self.currentVideo.locationIsCity = RVC.tempVideo.locationIsCity;
        self.currentVideo.taggedUsers = RVC.tempVideo.taggedUsers;
    }
    
    if (AppDelegate.isAllowedToUseLocationManager) {
        [AppDelegate updateLocation];
    }

    [self startAnimationTimer];
    [self startVUTimer];
}

- (void)stopRecording
{
    if (!AppDelegate.isRecording) return;
    
    if (self.presentedViewController) {
        // Delay until the presented view is dismissed
        [self performSelector:@selector(stopRecording) withObject:nil afterDelay:1.0f];
        
        return;
    }

    [self stopRecordingAndDelayPCV:NO];
}

- (void)stopRecordingAndDelayPCV:(BOOL)delayPCV
{
    if (self.captureMode == ORCaptureModeGoPro) {
        [self.gpe stopRecording];
    } else {
        if (!self.videoProcessor.isRecording) {
            NSLog(@"We're not recording, can't stop right now.");
            return;
        }
        
        [AppDelegate AudioSession_Default];
        [self.videoProcessor stopRecording];
        [self.videoProcessor turnTorchOff];
        [self recordingDidStopShouldDelayPCV:delayPCV];
    }
}

- (void)recordingDidStopShouldDelayPCV:(BOOL)delayPCV
{
	AppDelegate.isRecording = NO;

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORRecordingStopped" object:@(self.videoProcessor.lastKnownOrientation)];
	[AppDelegate.mixpanel track:@"Video Recorded" properties:@{
															   @"VideoId": self.currentVideo.videoId,
                                                               @"Duration": [NSString stringWithFormat:@"%f", self.currentVideo.duration],
                                                               @"Latitude": [NSString stringWithFormat:@"%f", self.currentVideo.latitude],
                                                               @"Longitude": [NSString stringWithFormat:@"%f", self.currentVideo.longitude]
                                                               }];
    [self collapseViewerAvatarTable];
    [self stopLiveMonitor];

	self.viewers = nil;
    self.btnStart.alpha = 0.5f;
	
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        [RVC configureForOrientation:self.interfaceOrientation duration:0.0f];
        [self configureForOrientation:self.interfaceOrientation duration:0.0f];
    }
    
    [self stopAnimationTimer];
    [self stopVUTimer];
	
	self.btnBroadcast.hidden = YES;
	self.imgLiveIcon.hidden = YES;
    self.btnBroadcast.enabled = NO;
	self.viewDuringCapture.alpha = 0.0f;
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    if (!delayPCV) [self presentPCV];
}

- (void)presentPCV
{
    if (!self.currentVideo) return;

    [RVC presentPCVWithVideo:self.currentVideo andPlaces:[ORDataController sharedInstance].places force:NO];
    self.currentVideo = nil;
}

#pragma mark - UI

- (void)btnStart_TouchUpInside:(id)sender
{
	if (UIInterfaceOrientationIsPortrait(self.videoProcessor.lastKnownOrientation)) {
        #if !(TARGET_IPHONE_SIMULATOR)
        [self startMotionDetect];
        #endif
        
        [AppDelegate forceLandscape];
        [AppDelegate performSelector:@selector(unlockOrientation) withObject:nil afterDelay:1.0f];
	} else {
        if (self.motionManager && !UIInterfaceOrientationIsLandscape(self.estimatedOrientation)) {
            // Device auto-rotated but user didn't rotate to LS
            [self showRotateAlert];
            return;
        }
        
        [RVC requestMicrophonePermissionFromOSWithCompletion:^(BOOL granted) {
            if (granted) {
                [self startRecording];
            } else {
                [AppDelegate forcePortrait];
                if (self.micPermissionOverlay) [self.micPermissionOverlay.view removeFromSuperview];
                self.micPermissionOverlay = [ORMicrophonePermissionView new];
                self.micPermissionOverlay.view.frame = self.view.bounds;
                self.micPermissionOverlay.parent = self;
                [self.view addSubview:self.micPermissionOverlay.view];
            }
        }];
	}
}

- (IBAction)btnOverClock_TouchUpInside:(id)sender
{
	self.rotateToStopRecordingAlert = [[UIAlertView alloc] initWithTitle:@""
													message:@"Rotate phone to stop recording."
												   delegate:nil
										  cancelButtonTitle:@"Got it"
										  otherButtonTitles:nil];
	[self.rotateToStopRecordingAlert show];
}

- (void)dismissMicPermissionView
{
    [self.micPermissionOverlay.view removeFromSuperview];
    self.micPermissionOverlay = nil;
    
    [AppDelegate unlockOrientation];
    [self startPreview];
}

- (void)btnStop_TouchUpInside:(id)sender
{
    [self stopRecordingAndDelayPCV:NO];
}

- (IBAction)tgrTapCatcher_Action:(UITapGestureRecognizer *)recognizer
{
	UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
	if (UIInterfaceOrientationIsLandscape(interfaceOrientation) && !self.headerOrFooterIsOpen) {
        [self setFocusAndExposurePoint:[recognizer locationInView:self.viewVideoPreview]];
	}
}

- (IBAction)tgrLongCatcher_Action:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation) && !self.headerOrFooterIsOpen) {
            [self lockFocusAndExposurePoint:[recognizer locationInView:self.viewVideoPreview]];
            [self performSelector:@selector(completeLockFocusAndExposure) withObject:nil afterDelay:1.0f];
        }
    } else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(completeLockFocusAndExposure) object:nil];

        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation) && !self.headerOrFooterIsOpen && !self.focusIsLocked) {
            [self setFocusAndExposurePoint:[recognizer locationInView:self.viewVideoPreview]];
        }
    }
}

- (IBAction)btnBroadcast_TouchUpInside:(id)sender
{
    if (self.isWaitingForLive) {
        self.currentVideo.needsLiveNotification = NO;
        
        self.lblLiveStatus.hidden = YES;
        self.imgLiveIcon.hidden = NO;
        self.isWaitingForLive = NO;
        
        return;
    }
    
    NetworkStatus status = ApiEngine.currentNetworkStatus;
    
    if (status == NotReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't Send Alerts"
                                                        message:@"No internet connection."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    } else if (status == ReachableViaWWAN && CurrentUser.settings.wifiTransferOnly) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't Send Alerts"
                                                        message:@"Phone is on a mobile network and \"Wifi Transfer Only\" option is enabled."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    } else if (CurrentUser.accountType == 3) {
        self.alertView = [[UIAlertView alloc] initWithTitle:@"Can't Send Alerts"
                                                        message:@"You'll need to stop recording and sign-in before you're able to broadcast. Want to do it now?"
                                                       delegate:self
                                              cancelButtonTitle:@"Later"
                                              otherButtonTitles:@"Sign-In", nil];
        self.alertView.tag = 2;
        [self.alertView show];
        return;
    }

    self.btnBroadcast.enabled = NO;
    [self showBroadcastOverlay];
}

- (IBAction)btnSwapCameras_TouchUpInside:(id)sender
{
    [self.videoProcessor swapCameras];
    self.btnSwapCameras.hidden = YES;
    self.btnTorch.hidden = YES;
}

- (IBAction)btnTorch_TouchUpInside:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORToggleTorch" object:nil];
}

- (IBAction)btnGuides_TouchUpInside:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORToggleGuides" object:nil];
}

#pragma mark - Broadcast Overlay

- (void)showBroadcastOverlay
{
    if (self.broadcastOverlay) {
        [self.broadcastOverlay.view removeFromSuperview];
        self.broadcastOverlay = nil;
    }
    
    self.broadcastOverlay = [[ORBroadcastBehaviorView alloc] initWithVideo:self.currentVideo];
    self.broadcastOverlay.parent = self;
    self.broadcastOverlay.view.frame = self.view.bounds;
    self.broadcastOverlay.view.alpha = 0.0f;

    [self.view addSubview:self.broadcastOverlay.view];
    
    [UIView animateWithDuration:0.2f animations:^{
        self.broadcastOverlay.view.alpha = 1.0f;
    }];
}

- (void)hideBroadcastOverlayAndMarkAsSent:(BOOL)sent
{
    [UIView animateWithDuration:0.2f animations:^{
        self.broadcastOverlay.view.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.btnBroadcast.enabled = YES;
        [self.broadcastOverlay.view removeFromSuperview];
        self.broadcastOverlay = nil;
    }];

    if (sent) {
        [self sendLiveNotification];
        
		self.imgLiveIcon.hidden = YES;
		self.lblLiveStatus.hidden = NO;
		self.lblLiveStatus.text = @"•••";

        self.isWaitingForLive = YES;
        [self runBlueDotAnimation];
    }
}

- (void)sendLiveNotification
{
    if (self.currentVideo && AppDelegate.isRecording) {
        [ORLoggingEngine logEvent:@"ORCaptureView" video:self.currentVideo.videoId msg:@"User started live broadcast"];
        
        [self.currentVideo sendLiveNotification];
        [AppDelegate.mixpanel track:@"Video Broadcast" properties:@{
                                                                    @"VideoId": self.currentVideo.videoId,
                                                                    @"NotifyFollowers": ORStringFromBOOL(self.currentVideo.liveNotificationToFollowers),
                                                                    @"NotifyFacebook": ORStringFromBOOL(self.currentVideo.liveNotificationToFacebook),
                                                                    @"NotifyTwitter": ORStringFromBOOL(self.currentVideo.liveNotificationToTwitter)
                                                                    }];
    }
}

#pragma mark - Focus & Exposure

- (void)setFocusAndExposurePoint:(CGPoint)point
{
    self.lblFocus.hidden = YES;
    
    CGRect f = CGRectMake(point.x - 66.0f, point.y - 66.0f, 132.0f, 132.0f);
    self.viewFocusRing.frame = f;
	self.viewFocusRing.alpha = 1.0f;
    
    f = CGRectMake(point.x - 33.0f, point.y - 33.0f, 66.0f, 66.0f);
    
    [UIView animateWithDuration:0.3f animations:^{
        self.viewFocusRing.frame = f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3f delay:2.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.viewFocusRing.alpha = 0.0f;
        } completion:nil];
    }];
    
    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)self.viewVideoPreview.layer captureDevicePointOfInterestForPoint:point];
	
	// CAMERA SETTINGS
	NSError *error = nil;

	// Lock for configuration
	if ([self.videoProcessor.videoCaptureDevice lockForConfiguration:&error]) {
        // Unlock the autofocus restriction
        if ([self.videoProcessor.videoCaptureDevice respondsToSelector:@selector(isAutoFocusRangeRestrictionSupported)] && self.videoProcessor.videoCaptureDevice.autoFocusRangeRestrictionSupported) {
            self.videoProcessor.videoCaptureDevice.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNone;
        }
        
        // Focus point
		if (self.videoProcessor.videoCaptureDevice.focusPointOfInterestSupported && [self.videoProcessor.videoCaptureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.videoProcessor.videoCaptureDevice setFocusPointOfInterest:devicePoint];
            [self.videoProcessor.videoCaptureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
		}

        // Exposure point
        if (self.videoProcessor.videoCaptureDevice.exposurePointOfInterestSupported && [self.videoProcessor.videoCaptureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            [self.videoProcessor.videoCaptureDevice setExposurePointOfInterest:devicePoint];
            [self.videoProcessor.videoCaptureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }

        [self.videoProcessor.videoCaptureDevice setSubjectAreaChangeMonitoringEnabled:YES];
        [self.videoProcessor.videoCaptureDevice unlockForConfiguration];
        self.focusIsLocked = NO;
    } else {
        NSLog(@"Error getting lock for device config: %@", error);
    }
}

- (void)lockFocusAndExposurePoint:(CGPoint)point
{
    self.lblFocus.hidden = YES;
    self.lockedPoint = point;
    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)self.viewVideoPreview.layer captureDevicePointOfInterestForPoint:point];
    
    // CAMERA SETTINGS
    NSError *error = nil;
    
    // Lock for configuration
    if ([self.videoProcessor.videoCaptureDevice lockForConfiguration:&error]) {
        // Unlock the autofocus restriction
        if ([self.videoProcessor.videoCaptureDevice respondsToSelector:@selector(isAutoFocusRangeRestrictionSupported)] && self.videoProcessor.videoCaptureDevice.autoFocusRangeRestrictionSupported) {
            self.videoProcessor.videoCaptureDevice.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNone;
        }
        
        // Focus point
        if (self.videoProcessor.videoCaptureDevice.focusPointOfInterestSupported && [self.videoProcessor.videoCaptureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.videoProcessor.videoCaptureDevice setFocusPointOfInterest:devicePoint];
            [self.videoProcessor.videoCaptureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        
        // Exposure point
        if (self.videoProcessor.videoCaptureDevice.exposurePointOfInterestSupported && [self.videoProcessor.videoCaptureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            [self.videoProcessor.videoCaptureDevice setExposurePointOfInterest:devicePoint];
            [self.videoProcessor.videoCaptureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        
        [self.videoProcessor.videoCaptureDevice setSubjectAreaChangeMonitoringEnabled:NO];
        [self.videoProcessor.videoCaptureDevice unlockForConfiguration];
        self.focusIsLocked = NO;
    } else {
        NSLog(@"Error getting lock for device config: %@", error);
    }
}

- (void)completeLockFocusAndExposure
{
    CGRect f1 = CGRectMake(self.lockedPoint.x - 66.0f, self.lockedPoint.y - 66.0f, 132.0f, 132.0f);
    CGRect f2 = CGRectMake(self.lockedPoint.x - 33.0f, self.lockedPoint.y - 33.0f, 66.0f, 66.0f);
    
    self.viewFocusRing.frame = f1;
    self.viewFocusRing.alpha = 1.0f;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.viewFocusRing.frame = f2;
    } completion:^(BOOL finished) {
        self.viewFocusRing.frame = f1;
        
        [UIView animateWithDuration:0.3f animations:^{
            self.viewFocusRing.frame = f2;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3f delay:2.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
                self.viewFocusRing.alpha = 0.5f;
            } completion:nil];
        }];
    }];

    // CAMERA SETTINGS
    NSError *error = nil;
    
    // Lock for configuration
    if ([self.videoProcessor.videoCaptureDevice lockForConfiguration:&error]) {
        // Focus point
        if ([self.videoProcessor.videoCaptureDevice isFocusModeSupported:AVCaptureFocusModeLocked]) {
            [self.videoProcessor.videoCaptureDevice setFocusMode:AVCaptureFocusModeLocked];
        }
        
        // Exposure point
        if ([self.videoProcessor.videoCaptureDevice isExposureModeSupported:AVCaptureExposureModeLocked]) {
            [self.videoProcessor.videoCaptureDevice setExposureMode:AVCaptureExposureModeLocked];
        }
        
        [self.videoProcessor.videoCaptureDevice setSubjectAreaChangeMonitoringEnabled:NO];
        [self.videoProcessor.videoCaptureDevice unlockForConfiguration];
        
        self.lblFocus.hidden = NO;
        self.focusIsLocked = YES;
    } else {
        NSLog(@"Error getting lock for device config: %@", error);
    }
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    self.lblFocus.hidden = YES;
	CGPoint devicePoint = CGPointMake(.5, .5);
	
	// CAMERA SETTINGS
	NSError *error = nil;
    
	// Lock for configuration
	if ([self.videoProcessor.videoCaptureDevice lockForConfiguration:&error]) {
		// Focus point
		if (self.videoProcessor.videoCaptureDevice.focusPointOfInterestSupported && [self.videoProcessor.videoCaptureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [self.videoProcessor.videoCaptureDevice setFocusPointOfInterest:devicePoint];
			[self.videoProcessor.videoCaptureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
		}
        
        // Exposure point
		if (self.videoProcessor.videoCaptureDevice.exposurePointOfInterestSupported && [self.videoProcessor.videoCaptureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            [self.videoProcessor.videoCaptureDevice setExposurePointOfInterest:devicePoint];
			[self.videoProcessor.videoCaptureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
		}
        
        [self.videoProcessor.videoCaptureDevice setSubjectAreaChangeMonitoringEnabled:NO];
        [self.videoProcessor.videoCaptureDevice unlockForConfiguration];
        self.focusIsLocked = NO;
    } else {
        NSLog(@"Error getting lock for device config: %@", error);
    }
}

#pragma mark - Zoom

- (IBAction)pgrZoom_Action:(UIPinchGestureRecognizer *)sender
{
	if (sender.state == UIGestureRecognizerStateBegan) {
        NSError *error = nil;
		self.isZooming = [self.videoProcessor.videoCaptureDevice lockForConfiguration:&error];
		if (error) NSLog(@"Error getting lock for device config: %@", error);
        self.minZoomFactor = 1.0f;
        self.maxZoomFactor = MIN(4.0f, self.videoProcessor.videoCaptureDevice.activeFormat.videoMaxZoomFactor);
        self.startZoomFactor = self.videoProcessor.videoCaptureDevice.videoZoomFactor;
        self.lastZoomPercent = ((self.startZoomFactor - self.minZoomFactor) / (self.maxZoomFactor - self.minZoomFactor));
	} else if (sender.state == UIGestureRecognizerStateChanged) {
        if (self.maxZoomFactor == 1.0f || !self.isZooming) return;
        if (fabs(self.lastZoomScale - sender.scale) > 0.01) {
            self.currentZoomFactor = self.startZoomFactor * sender.scale;
            self.lastZoomScale = sender.scale;
            if (self.currentZoomFactor < self.minZoomFactor) self.currentZoomFactor = self.minZoomFactor;
            if (self.currentZoomFactor > self.maxZoomFactor) self.currentZoomFactor = self.maxZoomFactor;
            
            [self.videoProcessor.videoCaptureDevice setVideoZoomFactor:self.currentZoomFactor];
            
            CGFloat zoomPercent = ((self.currentZoomFactor - self.minZoomFactor) / (self.maxZoomFactor - self.minZoomFactor));
            if (fabs(zoomPercent - self.lastZoomPercent) > 0.001) {
                self.lastZoomPercent = zoomPercent;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ORZoomChanged" object:self userInfo:@{@"percent": @(zoomPercent), @"factor": @(self.currentZoomFactor)}];
				
				// Display Zoom
				DLog(@"zoomPercent %f", zoomPercent);
				DLog(@"currentZoomFactor %f", self.currentZoomFactor);

				[UIView animateWithDuration:0.1f delay:0.0f
									options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
								 animations:^{
									 self.viewZoomHost.alpha = 1.0f;
									 float offset = zoomPercent * self.viewZoomBar.frame.size.width;
									 if (offset < 0 ) offset = 0; // lower limit
									 if (offset > self.viewZoomBar.frame.size.width) offset = self.viewZoomBar.frame.size.width; // upper limit
									 self.viewZoomIndicator.center = CGPointMake(self.viewZoomBar.frame.origin.x + offset, self.viewZoomIndicator.center.y);
								 } completion:^(BOOL finished) {
									 if (finished) {
										 [UIView animateWithDuration:0.3f delay:1.0f
															 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
														  animations:^{
															  self.viewZoomHost.alpha = 0.0f;
														  } completion:^(BOOL finished) {
															  //
														  }];
									 }
								 }];
            }
        }
	} else if (sender.state == UIGestureRecognizerStateEnded) {
		if (self.isZooming) [self.videoProcessor.videoCaptureDevice unlockForConfiguration];
        self.isZooming = NO;
	}
}

#pragma mark - Rule-of-Thirds

- (void)configureRuleOfThirds
{
	int lineThickness = 1;
	UIColor *lineColor = [UIColor colorWithRed:1 green:212.0/255.0 blue:0 alpha:1];
	
	self.rotLeft.frame = CGRectMake(roundf(self.view.frame.size.width/3), 0, lineThickness, self.view.frame.size.height);
	self.rotLeft.backgroundColor = lineColor;
	
	self.rotRight.frame = CGRectMake(roundf(self.view.frame.size.width/3) * 2, 0, lineThickness, self.view.frame.size.height);
	self.rotRight.backgroundColor = lineColor;
	
	self.rotTop.frame = CGRectMake(0, roundf(self.view.frame.size.height/3), self.view.frame.size.width, lineThickness);
	self.rotTop.backgroundColor = lineColor;
	
	self.rotBottom.frame = CGRectMake(0, roundf(self.view.frame.size.height/3) * 2, self.view.frame.size.width, lineThickness);
	self.rotBottom.backgroundColor = lineColor;
}

#pragma mark - Current Viewers

- (void)updateUsersWatching
{
    [ApiEngine usersWatchingVideo:self.currentVideo.videoId completion:^(NSError *error, NSArray *result) {
        NSMutableOrderedSet *usersWatching = [NSMutableOrderedSet orderedSetWithCapacity:result.count];
        
        for (OREpicFriend *user in result) {
            if (![self.viewers containsObject:user] && user.name) {
                NSString *msg = [NSString stringWithFormat:@"%@ is watching!", user.name];
                NSDictionary *notification = @{@"aps": @{@"alert": msg}};
                [AppDelegate.viewController presentNotification:notification];
            }
            
            [usersWatching addObject:user];
        }
        
        self.viewers = usersWatching;
		if (self.viewers.count > 0) {
			[self.tblViewers reloadData];
			[self expandViewerAvatarTable];
		}
		
        self.currentVideo.watched = MAX(self.currentVideo.watched, self.viewers.count);
		self.lblViewerCount.text = [NSString stringWithFormat:@"%d", self.viewers.count];
		self.viewViewerCount.hidden = NO;

        if (AppDelegate.isRecording) {
            [self performSelector:@selector(updateUsersWatching) withObject:nil afterDelay:1.0f];
        }
    }];
}

- (void)expandViewerAvatarTable
{
	CGRect f = self.tblViewers.frame;
	f.origin.x = 0;
	[UIView animateWithDuration:0.3f delay:0.0f
						options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
					 animations:^{
						 self.tblViewers.frame = f;
					 } completion:^(BOOL finished) {
						 //
					 }];
}

- (void)collapseViewerAvatarTable
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateUsersWatching) object:nil];
	
	CGRect f = self.tblViewers.frame;
	f.origin.x = self.tblViewers.frame.size.width;
	[UIView animateWithDuration:0.3f delay:0.0f
						options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseIn
					 animations:^{
						 self.tblViewers.frame = f;
						 self.viewViewerCount.alpha = 0.0f;
					 } completion:^(BOOL finished) {
						 self.viewers = [NSOrderedSet orderedSet];
						 [self.tblViewers reloadData];
						 self.viewViewerCount.alpha = 1.0f;
						 self.viewViewerCount.hidden = YES;
					 }];
}

#pragma mark - Timers

- (void)startAnimationTimer
{
    if (self.animationTimer) [self stopAnimationTimer];

    self.startDate = [NSDate date];
    self.lblTimer.text = @"0:00";
    
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateAnimationTimer:) userInfo:nil repeats:YES];
	
	[self runRedDotAnimation];
}

- (void)stopAnimationTimer
{
    [self.animationTimer invalidate];
    self.animationTimer = nil;
    self.lblTimer.text = @"0:00";
	self.lblRecordingDot.textColor = [UIColor whiteColor];
}

- (void)updateAnimationTimer:(NSTimer *)timer
{
    NSTimeInterval secondsElapsed = [[NSDate date] timeIntervalSinceDate:self.startDate];
	
	ORHourMinuteSecond *hms = [[ORHourMinuteSecond alloc] initWithSeconds:secondsElapsed];
	self.lblTimer.text = hms.friendlyString_HMMSS;
}

- (void)runRedDotAnimation
{
	if (AppDelegate.isRecording) {
		self.lblRecordingDot.textColor = [UIColor redColor];
		[UIView animateWithDuration:0.5f delay:0.0f
							options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
						 animations:^{
							 self.lblRecordingDot.alpha = (self.lblRecordingDot.alpha == 1.0f) ? 0.0f : 1.0f;
						 } completion:^(BOOL finished) {
                             [self runRedDotAnimation];
						 }];
	} else {
		self.lblRecordingDot.alpha = 1.0f;
		self.lblRecordingDot.textColor = [UIColor whiteColor];
	}
}

- (void)runBlueDotAnimation
{
	if (AppDelegate.isRecording && !self.viewLiveIndicator.hidden) {
        if (self.isWaitingForLive) {
            [UIView animateWithDuration:0.5f delay:0.0f
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 self.viewLiveIndicator.alpha = (self.viewLiveIndicator.alpha == 1.0f) ? 0.0f : 1.0f;
                             } completion:^(BOOL finished) {
                                 [self runBlueDotAnimation];
                             }];
        } else {
            self.viewLiveIndicator.alpha = 1.0f;
			self.lblLiveStatus.text = @"LIVE";
        }
	}
}

- (void)startVUTimer
{
    if (self.vuTimer) [self stopVUTimer];
    self.vuTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateVUTimer:) userInfo:nil repeats:YES];
}

- (void)stopVUTimer
{
    [self.vuTimer invalidate];
    self.vuTimer = nil;
}

- (void)updateVUTimer:(NSTimer *)timer
{
    if (self.videoProcessor.isRecording) {
        NSArray *audioChannels = self.videoProcessor.audioConnection.audioChannels;

        if (audioChannels.count > 0) {
            float avg = ((AVCaptureAudioChannel *)audioChannels[0]).averagePowerLevel;
            float lowerLimit = -60;
            if (avg < lowerLimit) avg = lowerLimit;
            double volumePercentage = ((avg + (lowerLimit*-1)) * (100/(lowerLimit * -1))) / 100;
            
            NSUInteger limit = roundf((float)self.vuMeterViews.count * volumePercentage);
            NSUInteger idx = 0;
            
            for (UIView *v in self.vuMeterViews) {
                v.alpha = (idx < limit) ? 1.0f : 0.3f;
                idx++;
            }
        }
    }
}

#pragma mark - UIGestureRecognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	if ([touch.view isKindOfClass:[UIControl class]]) {
		// we touched a button, slider, or other UIControl
		return NO; // ignore the touch
	}
    
    return YES; // handle the touch
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (otherGestureRecognizer == self.pgrZoom) return NO;
    return YES;
}

#pragma mark - Live Monitor

- (void)startLiveMonitor
{
	[self setLiveIndicatorVisible:NO];
    if (self.liveTimer) [self stopLiveMonitor];
    self.liveTimer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(updateLiveMonitorTimer:) userInfo:nil repeats:YES];
}

- (void)stopLiveMonitor
{
    [self.liveTimer invalidate];
    self.liveTimer = nil;
	[self setLiveIndicatorVisible:NO];
}

- (void)updateLiveMonitorTimer:(NSTimer *)timer
{
	DLog(@"IS LIVE = %@", self.wereLive ? @"YES" : @"NO");
	[self setLiveIndicatorVisible:self.wereLive];
}

- (void)setLiveIndicatorVisible:(BOOL)visible
{
//	self.viewLive.hidden = !visible;
//	self.btnBroadcast.hidden = (!visible || !self.btnBroadcast.enabled || CurrentUser.totalVideoCount == 0);
//	self.viewDuringCapture.layer.borderColor = APP_COLOR_PRIMARY.CGColor;
//	if (visible)
//		self.viewDuringCapture.layer.borderWidth = 2.0f;
//	else
//		self.viewDuringCapture.layer.borderWidth = 0.0f;
}

- (BOOL)wereLive
{
	return self.currentVideo.isLive;
}

#pragma mark - Custom

- (void)showRotateAlert
{
	self.alertRotateNotification = [[UIAlertView alloc] initWithTitle:@""
															  message:@"Rotate your phone to landscape (sideways) in order to record."
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
	[self.alertRotateNotification show];
}

- (void)presentFindInviteFriends
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORPresentFindFriends" object:nil];
}

- (void)presentGoProView
{
	[AppDelegate.mixpanel track:@"BTN - Cloudcamify GoPro" properties:nil];
	[AppDelegate nativeBarAppearance_default];
	ORGoProSourceView *gp = [ORGoProSourceView new];
	ORNavigationController *nc = [[ORNavigationController alloc] initWithRootViewController:gp];
	[RVC presentViewController:nc animated:YES completion:nil];
}

#pragma mark - UITableViewDelegate

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.tblViewers)
		return self.viewers.count;
	else
		return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ORViewerCell *cell = [tableView dequeueReusableCellWithIdentifier:viewerCell forIndexPath:indexPath];
	
	if (tableView == self.tblViewers) {
		cell.eFriend = self.viewers[indexPath.row];
	}
	cell.backgroundColor = [UIColor clearColor];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//	DLog(@"%d", indexPath.row);
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return self.tblViewers.frame.size.width;
}

#pragma mark - NSNotifications

- (void)registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORVideoSegmentUploaded:) name:@"ORVideoSegmentUploaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORToggleGuides:) name:@"ORToggleGuides" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORLocationUpdated:) name:@"ORLocationUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORToggleTorch:) name:@"ORToggleTorch" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORNetworkStatusChanged:) name:@"ORNetworkStatusChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORLiveNotificationSent:) name:@"ORLiveNotificationSent" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORStartGoProRecording:) name:@"ORStartGoProRecording" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORPlacesListLoaded:) name:@"ORPlacesListLoaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORCamerasSwapped:) name:@"ORCamerasSwapped" object:nil];
}

- (void)handleORToggleTorch:(NSNotification*)n
{
    BOOL on = [self.videoProcessor toggleTorch];
	self.btnTorch.selected = on;
}

- (void)handleORToggleGuides:(NSNotification*)n
{
	self.viewRotParent.hidden = !self.viewRotParent.hidden;
}

- (void)handleWillEnterForeground:(NSNotification*)n
{
    if (RVC.currentState == ORUIStateCamera && AppDelegate.isSignedIn) [self startPreview];
}

- (void)handleDidEnterBackground:(NSNotification *)notification
{
    if (self.videoProcessor.isRecording) {
        NSLog(@"App will go to background, will stop recording.");
        [self stopRecordingAndDelayPCV:NO];
	}
    
    [self stopPreview];
}

- (void)handleORVideoSegmentUploaded:(NSNotification*)n
{
	if (!n.object) return;
    
	OREpicVideo *v = (OREpicVideo*)n.object;
	if ([v.videoId isEqualToString:self.currentVideo.videoId]) {
        [self updateLiveMonitorTimer:nil];
    }
}

- (void)handleORVideoModified:(NSNotification *)n
{
//    [self setupThumbnailButton];
}

- (void)handleORLocationUpdated:(NSNotification *)n
{
    if (!n.object) return;
    
    if (AppDelegate.isRecording) {
        self.currentVideo.latitude = AppDelegate.lastKnownLocation.coordinate.latitude;
        self.currentVideo.longitude = AppDelegate.lastKnownLocation.coordinate.longitude;
        [[ORDataController sharedInstance] saveVideo:self.currentVideo];
    }
}

- (void)handleORNetworkStatusChanged:(NSNotification *)n
{
    if (AppDelegate.isRecording && self.btnBroadcast.enabled) {
        NetworkStatus status = ApiEngine.currentNetworkStatus;
        
        if (status == NotReachable || (status == ReachableViaWWAN && CurrentUser.settings.wifiTransferOnly)) {
            self.btnBroadcast.hidden = YES;
			self.imgLiveIcon.hidden = YES;
        } else {
            self.btnBroadcast.hidden = NO;
			self.imgLiveIcon.hidden = NO;
        }
    }
    
    if (![[ORFaspPersistentEngine sharedInstance] canUploadNow]) {
        self.currentVideo.isLive = NO;
        [self updateLiveMonitorTimer:nil];
    }
}

- (void)handleORLiveNotificationSent:(NSNotification *)n
{
	if (!n.object) return;
    
	OREpicVideo *v = (OREpicVideo*)n.object;
	if ([v.videoId isEqualToString:self.currentVideo.videoId]) {
        self.lblViewerCount.text = @"0";
		self.viewViewerCount.hidden = NO;

        [self performSelector:@selector(updateUsersWatching) withObject:nil afterDelay:1.0f];
        
        self.isWaitingForLive = NO;
        self.viewLiveIndicator.alpha = 1.0f;
        
        NSString *msg = @"";
        if (self.currentVideo.liveNotificationToFollowers && CurrentUser.followers.count > 0) {
            msg = [msg stringByAppendingString:[NSString stringWithFormat:@"Notified your %d follower%@", CurrentUser.followers.count, CurrentUser.followers.count == 1 ? @"" : @"s"]];
        }
        
        if (self.currentVideo.liveNotificationToTwitter && CurrentUser.twitterId && self.currentVideo.liveNotificationToFacebook && CurrentUser.facebookId) {
            msg = [msg stringByAppendingString:@", Twitter and Facebook"];
        } else if (self.currentVideo.liveNotificationToTwitter && CurrentUser.twitterId) {
            msg = [msg stringByAppendingString:@" and Twitter"];
        } else if (self.currentVideo.liveNotificationToFacebook && CurrentUser.facebookId) {
            msg = [msg stringByAppendingString:@" and Facebook"];
        }
        
        ORPopDownView *pop = [[ORPopDownView alloc] initWithTitle:@"Live Alert Sent"
                                                         subtitle:msg];
        
        [pop displayInView:self.view hideAfter:4.0f];
    }
}

- (void)handleORStartGoProRecording:(NSNotification *)n
{
    self.gpe = [ORGoProEngine sharedInstance];
    self.gpe.delegate = self;

    self.viewGoPro = [[ORGoProPreview alloc] initWithFrame:self.viewVideoPreview.bounds];
    self.viewGoPro.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.viewGoPro.backgroundColor = [UIColor blackColor];
    [self.viewVideoPreview addSubview:self.viewGoPro];
    
    UIActivityIndicatorView *aiLoading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    aiLoading.hidesWhenStopped = YES;
    aiLoading.center = self.viewGoPro.center;
    aiLoading.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.viewGoPro addSubview:aiLoading];
    
    [aiLoading startAnimating];
    [self stopPreview];
    
    [AppDelegate forceLandscape];
    [self.gpe startRecording];
}

- (void)handleORPlacesListLoaded:(NSNotification *)n
{
    ORFoursquareVenue *pl = [[ORDataController sharedInstance].places firstObject];
    if (!pl) return;
    
    if (AppDelegate.isRecording) {
        self.currentVideo.locationFriendlyName = pl.name;
        self.currentVideo.locationIsCity = pl.isCity;
        
        if (self.currentVideo.latitude == 0 && self.currentVideo.longitude == 0) {
            self.currentVideo.latitude = [pl.location.lat doubleValue];
            self.currentVideo.longitude = [pl.location.lng doubleValue];
        }
    }
    
    self.selectedPlace = pl;
}

- (void)handleORCamerasSwapped:(NSNotification *)n
{
    self.btnSwapCameras.hidden = NO;
    self.btnTorch.hidden = self.videoProcessor.isUsingFrontCamera;
}

#pragma mark - ORGoProEngineDelegate

- (void)goproDidStartPreview
{
    [self.viewGoPro setPlayer:self.gpe.previewPlayer];
    [self.viewGoPro.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)goproDidFailPreviewWithError:(NSError *)error
{
    NSLog(@"GoPro Preview Failed: %@", error);
    [self.viewGoPro setPlayer:nil];
    
    __weak ORCaptureView *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [weakSelf.gpe startPreview];
    });
}

- (void)goproDidStopPreview
{
    [self.viewGoPro setPlayer:nil];
}

- (void)goproWillStartRecording
{
}

- (void)goproDidStartRecording
{
    NSLog(@"GoPro Recording started");
    
    self.captureMode = ORCaptureModeGoPro;
    self.currentVideo = self.gpe.currentVideo;
    self.btnTorch.hidden = YES;
    self.btnStop.hidden = NO;
    
    [self recordingDidStart];
    
    if (self.gpe.shouldAutoShare) {
        self.currentVideo.name = self.gpe.videoCaption;
        self.currentVideo.liveNotificationMessage = self.gpe.videoCaption;
        self.currentVideo.liveNotificationToFollowers = NO;
        self.currentVideo.liveNotificationToFacebook = self.gpe.shouldPostToFacebook;
        self.currentVideo.liveNotificationToTwitter = self.gpe.shouldPostToTwitter;
        self.currentVideo.privacy = OREpicVideoPrivacyPublic;

        [self hideBroadcastOverlayAndMarkAsSent:YES];
    }
}

- (void)goproWillStopRecording
{
    [AppDelegate forcePortrait];
    
    [self startPreview];
    [self.viewGoPro setPlayer:nil];
    [self.viewGoPro removeFromSuperview];
    self.viewGoPro = nil;
}

- (void)goproDidStopRecording
{
    NSLog(@"GoPro Recording stopped");
    
    [self.gpe stopPreview];
    [self.gpe stopEngine];
    self.gpe = nil;
    
    self.captureMode = ORCaptureModeCamera;
    self.btnTorch.hidden = NO;
    self.btnStop.hidden = YES;

    [self recordingDidStopShouldDelayPCV:NO];
}

- (void)goproDidFailRecordingWithError:(NSError *)error
{
    NSLog(@"GoPro Recording failed: %@", error);
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    
	switch (alertView.tag) {
		case 1: { // unused
			break;
        }
            
        case 2: { // Trial Account
            if (buttonIndex == alertView.cancelButtonIndex) return;
            
            [self stopRecordingAndDelayPCV:YES];
            [RVC presentSignInWithMessage:@"Sign-in so you can send live alerts." completion:^(BOOL success) {
                if (success) {
                    if (![self.currentVideo.userId isEqualToString:CurrentUser.userId]) self.currentVideo.userId = CurrentUser.userId;
                }
                
                [self presentPCV];
            }];
            break;
        }
            
		default:
			break;
	}
}

#pragma mark - Video From Camera Roll

- (void)presentCameraRollSelectorView {
	[AppDelegate.mixpanel track:@"BTN - Cloudcamify Cameraroll" properties:nil];
	[AppDelegate nativeBarAppearance_nativeShare];
	
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
//	imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum; // filters to just videos nicely
    imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];

	[self presentViewController:imagePicker animated:YES completion:^{

	}];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	[viewController.navigationItem setTitle:@"I  M  P  O  R  T"];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [AppDelegate nativeBarAppearance_default];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [AppDelegate nativeBarAppearance_default];

    [self dismissViewControllerAnimated:YES completion:^{
        NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
        
        if ([mediaType isEqualToString:(__bridge NSString *)kUTTypeMovie]) {
            NSURL *videoURL = (NSURL *)[info objectForKey:UIImagePickerControllerMediaURL];
            NSLog(@"Source Path: %@", videoURL);
            
            ORAVURLProcessor *fp = [[ORAVURLProcessor alloc] init];
            
            [fp transcodeURL:videoURL start:^(OREpicVideo *video, NSError *error) {
                if (error) NSLog(@"Error: %@", error);
                
                if (video) {
                    self.currentVideo = video;
                    [[ORDataController sharedInstance] clearPlaces];
                    
                    [self presentPCV];
                }
            } progress:^(OREpicVideo *video, double progress) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ORTranscodeProgress" object:@(progress) userInfo:@{@"video": video}];
            } completion:^(OREpicVideo *video, NSError *error) {
                if (video && !error) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORTranscodeComplete" object:video];
                } else if (error && error.code == 987) {
                    [[[UIAlertView alloc] initWithTitle:@"Unsupported Video"
                                                message:@"Sorry, portrait videos are currently not supported."
                                               delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil] show];
                    return;
                } else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORTranscodeError" object:error];
                }
            }];
        }
    }];
}

@end
