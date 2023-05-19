//
//  ORMicrophonePermissionView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 6/10/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ORCaptureView;

@interface ORMicrophonePermissionView : GAITrackedViewController

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;
@property (nonatomic, weak) IBOutlet UILabel *lblSubtitle;
@property (nonatomic, weak) ORCaptureView *parent;

- (void)configureForCamera;
- (void)configureForMicrophone;

@end
