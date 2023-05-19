//
//  ORPermissionsView.m
//  Veezy
//
//  Created by Thomas Purnell-Fisher on 11/19/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORPermissionsView.h"
#import "ORVUMeterView.h"
#import "ORPermissionsEngine.h"
#import "ORMessageOverlayView.h"
#import "ORCapturePreview.h"

@interface ORPermissionsView () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong, nonatomic) ORVUMeterView *vu;
@property (strong, nonatomic) AVCaptureSession *captureSession;

@end

@implementation ORPermissionsView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
	
    [super viewDidLoad];

	[self registerForNotifications];
	
	self.viewCameraEnable.layer.cornerRadius = 2.0f;
	self.viewMicEnable.layer.cornerRadius = 2.0f;
	self.viewLocationEnable.layer.cornerRadius = 2.0f;
	self.viewNotificationsEnable.layer.cornerRadius = 2.0f;
	self.btnFinished.layer.cornerRadius = 2.0f;
    
    self.viewMicrophone.hidden = YES;
    self.viewLocation.hidden = YES;
    self.viewPush.hidden = YES;
    self.btnFinished.hidden = YES;
    self.imgCheck_Camera.hidden = YES;
    self.imgCheck_Mic.hidden = YES;
    self.imgCheck_Location.hidden = YES;
    self.imgCheck_Notifications.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
	[self layoutForStart];
}

#pragma mark - UI

- (IBAction)btnFinished_TouchUpInside:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"permissionsViewCompleted"];
    [defaults synchronize];
    
    if (self.captureSession) {
        [self.captureSession stopRunning];
        self.captureSession = nil;
    }
    
    if (self.vu) {
        [self.vu stopMetering];
        self.vu = nil;
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORPermissionsViewDismissed" object:nil];
    }];
}

#pragma mark - Custom

- (void)layoutForStart
{
	CGRect f;
	float bottom = [[UIScreen mainScreen] bounds].size.height; // self.view.frame.size.height;
	
	f = self.viewMicrophone.frame;
	f.origin.y = bottom;
	self.viewMicrophone.frame = f;

	f = self.viewLocation.frame;
	f.origin.y = bottom;
	self.viewLocation.frame = f;

	f = self.viewPush.frame;
	f.origin.y = bottom;
	self.viewPush.frame = f;

	f = self.btnFinished.frame;
	f.origin.y = bottom;
	self.btnFinished.frame = f;
    
    self.viewMicrophone.hidden = NO;
    self.viewLocation.hidden = NO;
    self.viewPush.hidden = NO;
    self.btnFinished.hidden = NO;
    
    [self checkCameraState];
}

#pragma mark - Camera

- (IBAction)btnCameraEnable_TouchUpInside:(id)sender
{
    self.btnCameraEnable.hidden = YES;
    self.imgCameraIcon.hidden = YES;
    [self.aiCamera startAnimating];
    
    [[ORPermissionsEngine sharedInstance] requestCameraPermissionWithCompletion:^(BOOL granted) {
        if (granted) {
            [self cameraPermissionGranted];
        } else {
            [self cameraPermissionDenied];
        }
    }];
}

- (void)checkCameraState
{
    ORPermissionState state = [[ORPermissionsEngine sharedInstance] currentCameraPermissionState];
    
    switch (state) {
        case ORPermissionStateAuthorized:
            [self cameraPermissionGranted];
            break;
        case ORPermissionStateDenied:
        case ORPermissionStateRestricted:
            [self cameraPermissionDenied];
            break;
        default:
            break;
    }
}

- (void)cameraPermissionGranted
{
    [self.aiCamera stopAnimating];
    self.btnCameraEnable.hidden = YES;
    self.imgCameraIcon.hidden = YES;
    self.imgCheck_Camera.hidden = NO;
    self.imgCheck_Camera.image = [UIImage imageNamed:@"check-green-circle-icon-44x"];

    [self startVideoPreview];
    [self addMicrophoneView];
}

- (void)cameraPermissionDenied
{
    [self.aiCamera stopAnimating];
    self.btnCameraEnable.hidden = YES;
    self.imgCameraIcon.hidden = YES;
    self.imgCheck_Camera.hidden = NO;
    self.imgCheck_Camera.image = [UIImage imageNamed:@"x-red-circle-icon-44x"];
    
    ORMessageOverlayView *vc = [[ORMessageOverlayView alloc] initWithTitle:@"Uh-oh..."
                                                                   message:@"You've denied access to the camera! Please go to the iOS Settings App > Privacy > Camera and grant permission to Veezy."
                                                               buttonTitle:@"OK"];
    
    vc.enableButtonBlock = ^BOOL() {
        ORPermissionState state = [[ORPermissionsEngine sharedInstance] currentCameraPermissionState];
        return (state == ORPermissionStateAuthorized);
    };
    
    [vc presentInViewController:self completion:^{
        [self checkCameraState];
    }];
}

#pragma mark - Microphone

- (IBAction)btnMicEnable_TouchUpInside:(id)sender
{
    self.btnMicEnable.hidden = YES;
    self.micIcon.hidden = YES;
    [self.aiMic startAnimating];
    
    [[ORPermissionsEngine sharedInstance] requestMicrophonePermissionWithCompletion:^(BOOL granted) {
        if (granted) {
            [self microphonePermissionGranted];
        } else {
            [self microphonePermissionDenied];
        }
    }];
}

- (void)addMicrophoneView
{
	[UIView animateWithDuration:0.3f delay:0.0f
						options:UIViewAnimationOptionCurveEaseOut
					 animations:^{
						 CGRect f = self.viewMicrophone.frame;
						 f.origin.y = self.viewCamera.frame.origin.y + self.viewCamera.frame.size.height + 1;
						 self.viewMicrophone.frame = f;
					 } completion:^(BOOL finished) {
                         [self checkMicrophoneState];
					 }];
}

- (void)checkMicrophoneState
{
    ORPermissionState state = [[ORPermissionsEngine sharedInstance] currentMicrophonePermissionState];
    
    switch (state) {
        case ORPermissionStateAuthorized:
            [self microphonePermissionGranted];
            break;
        case ORPermissionStateDenied:
        case ORPermissionStateRestricted:
            [self microphonePermissionDenied];
            break;
        default:
            break;
    }
}

- (void)microphonePermissionGranted
{
    [self.aiMic stopAnimating];
    self.btnMicEnable.hidden = YES;
    self.micIcon.hidden = YES;
    self.imgCheck_Mic.hidden = NO;
    self.imgCheck_Mic.image = [UIImage imageNamed:@"check-green-circle-icon-44x"];
    
    self.vu = [ORVUMeterView new];
    [self addChildViewController:self.vu];
    [self.viewMicEnable addSubview:self.vu.view];
    [self.vu didMoveToParentViewController:self];
    
    [self addLocationView];
}

- (void)microphonePermissionDenied
{
    [self.aiMic stopAnimating];
    self.btnMicEnable.hidden = YES;
    self.micIcon.hidden = YES;
    self.imgCheck_Mic.hidden = NO;
    self.imgCheck_Mic.image = [UIImage imageNamed:@"x-red-circle-icon-44x"];
    
    ORMessageOverlayView *vc = [[ORMessageOverlayView alloc] initWithTitle:@"Uh-oh..."
                                                                   message:@"You've denied access to the microphone! Please go to the iOS Settings App > Privacy > Microphone and grant permission to Veezy."
                                                               buttonTitle:@"OK"];
    
    vc.enableButtonBlock = ^BOOL() {
        ORPermissionState state = [[ORPermissionsEngine sharedInstance] currentMicrophonePermissionState];
        return (state == ORPermissionStateAuthorized);
    };
    
    [vc presentInViewController:self completion:^{
        [self checkMicrophoneState];
    }];
}

#pragma mark - Location

- (IBAction)btnLocationEnable_TouchUpInside:(id)sender
{
    self.btnLocationEnable.hidden = YES;
    self.imgLocationIcon.hidden = YES;
    [self.aiLocation startAnimating];
    
    [[ORPermissionsEngine sharedInstance] requestLocationPermissionWithCompletion:^(BOOL granted) {
        if (granted) {
            [self locationPermissionGranted];
        } else {
            [self locationPermissionDenied];
        }
    }];
}

- (IBAction)btnLocationNotNow_TouchUpInside:(id)sender
{
    self.btnLocationNotNow.hidden = YES;
    [self addPushView];
}

- (void)addLocationView
{
	[UIView animateWithDuration:0.3f delay:0.0f
						options:UIViewAnimationOptionCurveEaseOut
					 animations:^{
						 CGRect f = self.viewLocation.frame;
						 f.origin.y = self.viewMicrophone.frame.origin.y + self.viewMicrophone.frame.size.height + 1;
						 self.viewLocation.frame = f;
					 } completion:^(BOOL finished) {
                         [self checkLocationState];
					 }];
}

- (void)checkLocationState
{
    ORPermissionState state = [[ORPermissionsEngine sharedInstance] currentLocationPermissionState];
    
    switch (state) {
        case ORPermissionStateAuthorized:
            [self locationPermissionGranted];
            break;
        case ORPermissionStateDenied:
        case ORPermissionStateRestricted:
            [self locationPermissionDenied];
            break;
        default:
            break;
    }
}

- (void)locationPermissionGranted
{
    [self.aiLocation stopAnimating];
    self.btnLocationNotNow.hidden = YES;
    self.btnLocationEnable.hidden = YES;
    self.imgLocationIcon.hidden = YES;
    self.imgCheck_Location.hidden = NO;
    self.imgCheck_Location.image = [UIImage imageNamed:@"check-green-circle-icon-44x"];
    
    if (AppDelegate.lastKnownLocation) {
        [self handleORLocationUpdated:nil];
    } else {
        [AppDelegate updateLocation];
    }
    
    [self addPushView];
}

- (void)locationPermissionDenied
{
    [self.aiLocation stopAnimating];
    self.btnLocationNotNow.hidden = YES;
    self.btnLocationEnable.hidden = YES;
    self.imgLocationIcon.hidden = YES;
    self.imgCheck_Location.hidden = NO;
    self.imgCheck_Location.image = [UIImage imageNamed:@"x-red-circle-icon-44x"];
    
    [self addPushView];
}

#pragma mark - Push

- (IBAction)btnNotifications_TouchUpInside:(id)sender
{
    self.imgPushIcon.hidden = YES;
    self.btnNotificationsEnable.hidden = YES;
    [self.aiPush startAnimating];
    
    [[ORPermissionsEngine sharedInstance] requestPushPermissionWithCompletion:^(BOOL granted) {
        if (granted) {
            [self pushPermissionGranted];
        } else {
            [self pushPermissionDenied];
        }
    }];
}

- (IBAction)btnPushNotNow_TouchUpInside:(id)sender
{
    self.btnPushNotNow.hidden = YES;
    [self addFinishButton];
}

- (void)addPushView
{
	[UIView animateWithDuration:0.3f delay:0.0f
						options:UIViewAnimationOptionCurveEaseOut
					 animations:^{
						 CGRect f = self.viewPush.frame;
						 f.origin.y = self.viewLocation.frame.origin.y + self.viewLocation.frame.size.height + 1;
						 self.viewPush.frame = f;
					 } completion:^(BOOL finished) {
                         [self checkPushState];
					 }];
}

- (void)checkPushState
{
    ORPermissionState state = [[ORPermissionsEngine sharedInstance] currentPushPermissionState];
    
    switch (state) {
        case ORPermissionStateAuthorized:
            [self pushPermissionGranted];
            break;
        case ORPermissionStateDenied:
        case ORPermissionStateRestricted:
            [self pushPermissionDenied];
            break;
        default:
            break;
    }
}

- (void)pushPermissionGranted
{
    [self.aiPush stopAnimating];
    self.imgPushIcon.hidden = YES;
    self.btnPushNotNow.hidden = YES;
    self.btnNotificationsEnable.hidden = YES;
    self.imgCheck_Notifications.hidden = NO;
    self.imgCheck_Notifications.image = [UIImage imageNamed:@"check-green-circle-icon-44x"];
    
    [self addFinishButton];
}

- (void)pushPermissionDenied
{
    [self.aiPush stopAnimating];
    self.imgPushIcon.hidden = YES;
    self.btnPushNotNow.hidden = YES;
    self.btnNotificationsEnable.hidden = YES;
    self.imgCheck_Notifications.hidden = NO;
    self.imgCheck_Notifications.image = [UIImage imageNamed:@"x-red-circle-icon-44x"];
    
    [self addFinishButton];
}

#pragma mark - Finish

- (void)addFinishButton
{
	[UIView animateWithDuration:0.3f delay:0.0f
						options:UIViewAnimationOptionCurveEaseOut
					 animations:^{
						 CGRect f = self.btnFinished.frame;
						 f.origin.y = self.viewPush.frame.origin.y + self.viewPush.frame.size.height + 8;
						 self.btnFinished.frame = f;
					 } completion:^(BOOL finished) {
						 //
					 }];
}

#pragma mark - Video Preview

- (void)startVideoPreview
{
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    AVCaptureDevice *device = [self backCamera];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:NULL];
    if (!input) return;
    [self.captureSession addInput:input];
    
    self.viewVideoPreview.session = self.captureSession;
    [(AVCaptureVideoPreviewLayer *)self.viewVideoPreview.layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    [self.captureSession startRunning];
}

- (AVCaptureDevice *)backCamera
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            return device;
        }
    }
    
    return nil;
}

#pragma mark - NSNotifications

- (void)registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORLocationUpdated:) name:@"ORLocationUpdated" object:nil];
}

- (void)handleORLocationUpdated:(NSNotification *)n
{
	NSString *gms = [GoogleEngine staticMapImageUrlForLatitude:AppDelegate.lastKnownLocation.coordinate.latitude andLongitude:AppDelegate.lastKnownLocation.coordinate.longitude andWidth:self.viewLocationEnable.frame.size.width andHeight:self.viewLocationEnable.frame.size.height adjustMapForMarkerBy:0.00001f];
	
	__weak ORPermissionsView *weakSelf = self;
	
	[[ORCachedEngine sharedInstance] imageAtURL:[NSURL URLWithString:gms] completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
		if (error) {
			NSLog(@"Error: %@", error);
		} else {
			weakSelf.imgMap.image = image;
		}
	}];
}

@end
