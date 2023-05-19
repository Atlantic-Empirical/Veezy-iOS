//
//  ORAVProcessor.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 28/05/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ORAVProcessorCompletion)(OREpicVideo *video, NSError *error);
typedef void(^ORAVProcessorProgress)(OREpicVideo *video, double progress);

@class ORAVEncoder;

@interface ORAVProcessor : NSObject

@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, strong) OREpicVideo *currentVideo;

- (BOOL)isPortraitVideo;
- (void)encoderIsDone:(ORAVEncoder *)encoder;

@end
