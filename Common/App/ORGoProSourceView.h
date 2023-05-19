//
//  ORGoProSourceView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 5/17/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@class ORGoProPreview;

@interface ORGoProSourceView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet ORGoProPreview *viewPreview;
@property (weak, nonatomic) IBOutlet UIButton *btnList;
@property (weak, nonatomic) IBOutlet UIButton *btnRecord;
@property (weak, nonatomic) IBOutlet UILabel *lblCameraInfo;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiLoading;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiPreview;
@property (weak, nonatomic) IBOutlet UIButton *btnRetryConnectToCamera;

- (IBAction)btnList_TouchUpInside:(id)sender;
- (IBAction)btnRecord_TouchUpInside:(id)sender;
- (IBAction)btnRetryConnectToCamera_TouchUpInside:(id)sender;

@end
