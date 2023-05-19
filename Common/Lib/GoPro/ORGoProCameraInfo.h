//
//  ORGoProCameraInfo.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 21/05/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORGoProCameraInfo : NSObject

@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, assign) BOOL isPreviewOn;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, assign) NSUInteger mode;
@property (nonatomic, strong) NSString *cameraName;
@property (nonatomic, strong) NSString *cameraType;
@property (nonatomic, strong) NSString *firmwareVersion;
@property (nonatomic, strong) NSString *wifiVersion;
@property (nonatomic, strong) NSString *wifiPassword;

@end
