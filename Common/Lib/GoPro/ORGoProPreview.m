//
//  ORGoProPreview.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 20/05/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORGoProPreview.h"

@implementation ORGoProPreview

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayer *)player
{
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player
{
    [(AVPlayerLayer *)[self layer] setPlayer:player];
    [(AVPlayerLayer *)[self layer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

@end
