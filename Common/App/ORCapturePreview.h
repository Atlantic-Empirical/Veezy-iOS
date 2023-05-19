//
//  ORCapturePreview.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 27/02/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession;

@interface ORCapturePreview : UIView

@property (nonatomic) AVCaptureSession *session;

@end
