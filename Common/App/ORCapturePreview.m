//
//  ORCapturePreview.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 27/02/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORCapturePreview.h"
#import <AVFoundation/AVFoundation.h>

@implementation ORCapturePreview

+ (Class)layerClass
{
	return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
	return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

- (void)setSession:(AVCaptureSession *)session
{
	[(AVCaptureVideoPreviewLayer *)[self layer] setSession:session];
}

@end
