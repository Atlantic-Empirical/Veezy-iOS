//
//  ORMicrophonePermissionView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 6/10/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORMicrophonePermissionView.h"
#import "ORCaptureView.h"
#import "ORPermissionsEngine.h"

@interface ORMicrophonePermissionView ()

@property (nonatomic, assign) BOOL isCamera;

@end

@implementation ORMicrophonePermissionView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.screenName = @"MicrophonePermission";
    [self configureForMicrophone];
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)handleDidBecomeActive:(NSNotification *)n
{
    if (self.isCamera) {
        ORPermissionState state = [[ORPermissionsEngine sharedInstance] currentCameraPermissionState];
        if (state == ORPermissionStateAuthorized) [self.parent dismissMicPermissionView];
    } else {
        ORPermissionState state = [[ORPermissionsEngine sharedInstance] currentMicrophonePermissionState];
        if (state == ORPermissionStateAuthorized) [self.parent dismissMicPermissionView];
    }
}

- (void)configureForCamera
{
    self.isCamera = YES;
    self.lblTitle.text = [NSString stringWithFormat:@"%@ does not have access to the camera.", APP_NAME];
    self.lblSubtitle.text = [NSString stringWithFormat:@"Please enable access to the camera in iOS Settings > Privacy > Camera > %@.", APP_NAME];
}

- (void)configureForMicrophone
{
    self.isCamera = NO;
    self.lblTitle.text = [NSString stringWithFormat:@"%@ does not have access to the microphone.", APP_NAME];
    self.lblSubtitle.text = [NSString stringWithFormat:@"Please enable access to the microphone in iOS Settings > Privacy > Microphone > %@.", APP_NAME];
}

@end
