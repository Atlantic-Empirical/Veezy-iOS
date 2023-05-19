//
//  ORGoProStaticVideo.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 5/18/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORGoProStaticVideo : NSObject

@property (nonatomic, strong) NSString *fullUrlOnCam;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *fileSize;
@property (nonatomic, strong) NSString *duration;
@property (nonatomic, strong) NSString *resolution;

@end
