//
//  ORCapture.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 10/23/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ORCapturePreview, ORFoursquareVenue;

typedef enum {
    ORCaptureModeCamera = 0,
    ORCaptureModeGoPro = 1
} ORCaptureMode;


@interface ORCaptureView : GAITrackedViewController <UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet ORCapturePreview *viewVideoPreview;
@property (nonatomic, strong) OREpicVideo *currentVideo;
@property (weak, nonatomic) IBOutlet UIView *viewDuringCapture;

@property (weak, nonatomic) IBOutlet UIImageView *imgRotateRecord;

@property (weak, nonatomic) IBOutlet UIButton *btnBroadcast;
@property (strong, nonatomic) ORFoursquareVenue *selectedPlace;
@property (weak, nonatomic) IBOutlet UILabel *lblRecordingDot;
@property (weak, nonatomic) IBOutlet UIView *viewTimerHost;
@property (weak, nonatomic) IBOutlet UILabel *lblActionPrompt;
@property (weak, nonatomic) IBOutlet UIView *viewLiveIndicator;
@property (weak, nonatomic) IBOutlet UILabel *lblLiveC2A;
@property (weak, nonatomic) IBOutlet UILabel *lblLiveStatus;
@property (weak, nonatomic) IBOutlet UIImageView *imgLiveIcon;
@property (weak, nonatomic) IBOutlet UIButton *btnOverClock;

// FOOTER
@property (weak, nonatomic) IBOutlet UIButton *btnSwapCameras;
@property (weak, nonatomic) IBOutlet UIButton *btnTorch;
@property (weak, nonatomic) IBOutlet UIButton *btnGuides;
@property (weak, nonatomic) IBOutlet UIView *viewViewerCount;

// VU METER
@property (weak, nonatomic) IBOutlet UIView *viewVUMeterHost;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *vuMeterViews;

// START/STOP
@property (nonatomic, weak) IBOutlet UIButton *btnStart;
@property (nonatomic, weak) IBOutlet UIButton *btnStop;
@property (nonatomic, weak) IBOutlet UIButton *btnStopAux;
@property (nonatomic, weak) IBOutlet UILabel *lblTimer;
@property (weak, nonatomic) IBOutlet UIView *viewStart;
@property (weak, nonatomic) IBOutlet UIImageView *imgRotateC2A;

// TOUCH TO EXPOSE & FOCUS
@property (weak, nonatomic) IBOutlet UILabel *lblFocus;
@property (weak, nonatomic) IBOutlet UIView *viewFocusRing;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tgrTapCatcher;
@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *tgrLongCatcher;

// VIEWERS
@property (weak, nonatomic) IBOutlet UITableView *tblViewers;
@property (weak, nonatomic) IBOutlet UILabel *lblViewerCount;

// ZOOM
@property (strong, nonatomic) IBOutlet UIPinchGestureRecognizer *pgrZoom;
@property (weak, nonatomic) IBOutlet UILabel *lblZoomFactor;
@property (weak, nonatomic) IBOutlet UIView *viewZoom;
@property (weak, nonatomic) IBOutlet UIView *viewZoomHost;
@property (weak, nonatomic) IBOutlet UIView *viewZoomBar;
@property (weak, nonatomic) IBOutlet UIView *viewZoomIndicator;

// GUIDES
@property (weak, nonatomic) IBOutlet UIView *viewRotParent;
@property (weak, nonatomic) IBOutlet UIView *rotLeft;
@property (weak, nonatomic) IBOutlet UIView *rotRight;
@property (weak, nonatomic) IBOutlet UIView *rotTop;
@property (weak, nonatomic) IBOutlet UIView *rotBottom;

- (IBAction)btnStop_TouchUpInside:(id)sender;
- (IBAction)btnBroadcast_TouchUpInside:(id)sender;
- (IBAction)tgrTapCatcher_Action:(id)sender;
- (IBAction)tgrLongCatcher_Action:(id)sender;
- (IBAction)pgrZoom_Action:(UIPinchGestureRecognizer *)sender;
- (IBAction)btnSwapCameras_TouchUpInside:(id)sender;
- (IBAction)btnTorch_TouchUpInside:(id)sender;
- (IBAction)btnGuides_TouchUpInside:(id)sender;
- (IBAction)btnStart_TouchUpInside:(id)sender;
- (IBAction)btnOverClock_TouchUpInside:(id)sender;

- (void)startPreview;
- (void)stopPreview;
- (void)dismissMicPermissionView;
- (void)hideBroadcastOverlayAndMarkAsSent:(BOOL)sent;
- (void)presentCameraRollSelectorView;
- (void)presentGoProView;
- (void)showRotateAlert;

@end
