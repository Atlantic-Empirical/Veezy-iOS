//
//  ORPermissionsView.h
//  Veezy
//
//  Created by Thomas Purnell-Fisher on 11/19/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ORCapturePreview;

@interface ORPermissionsView : UIViewController

@property (nonatomic, weak) IBOutlet ORCapturePreview *viewVideoPreview;
@property (weak, nonatomic) IBOutlet UIView *viewCameraEnable;
@property (weak, nonatomic) IBOutlet UIView *viewMicEnable;
@property (weak, nonatomic) IBOutlet UIView *viewLocationEnable;
@property (weak, nonatomic) IBOutlet UIView *viewNotificationsEnable;
@property (weak, nonatomic) IBOutlet UIButton *btnCameraEnable;
@property (weak, nonatomic) IBOutlet UIButton *btnMicEnable;
@property (weak, nonatomic) IBOutlet UIButton *btnLocationEnable;
@property (weak, nonatomic) IBOutlet UIButton *btnLocationNotNow;
@property (weak, nonatomic) IBOutlet UIButton *btnNotificationsEnable;
@property (weak, nonatomic) IBOutlet UIButton *btnPushNotNow;
@property (weak, nonatomic) IBOutlet UIImageView *imgCheck_Camera;
@property (weak, nonatomic) IBOutlet UIImageView *imgCheck_Mic;
@property (weak, nonatomic) IBOutlet UIImageView *imgCheck_Location;
@property (weak, nonatomic) IBOutlet UIImageView *imgCheck_Notifications;
@property (weak, nonatomic) IBOutlet UIImageView *imgMap;
@property (weak, nonatomic) IBOutlet UIImageView *imgCameraIcon;
@property (weak, nonatomic) IBOutlet UIImageView *imgCameraImage;
@property (weak, nonatomic) IBOutlet UIImageView *micIcon;
@property (weak, nonatomic) IBOutlet UIImageView *imgPushIcon;
@property (weak, nonatomic) IBOutlet UIImageView *imgLocationIcon;
@property (weak, nonatomic) IBOutlet UIButton *btnFinished;
@property (weak, nonatomic) IBOutlet UIView *viewHeader;
@property (weak, nonatomic) IBOutlet UIView *viewCamera;
@property (weak, nonatomic) IBOutlet UIView *viewMicrophone;
@property (weak, nonatomic) IBOutlet UIView *viewLocation;
@property (weak, nonatomic) IBOutlet UIView *viewPush;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiPush;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiLocation;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiMic;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiCamera;

- (IBAction)btnCameraEnable_TouchUpInside:(id)sender;
- (IBAction)btnMicEnable_TouchUpInside:(id)sender;
- (IBAction)btnLocationEnable_TouchUpInside:(id)sender;
- (IBAction)btnNotifications_TouchUpInside:(id)sender;
- (IBAction)btnFinished_TouchUpInside:(id)sender;
- (IBAction)btnLocationNotNow_TouchUpInside:(id)sender;
- (IBAction)btnPushNotNow_TouchUpInside:(id)sender;

@end
