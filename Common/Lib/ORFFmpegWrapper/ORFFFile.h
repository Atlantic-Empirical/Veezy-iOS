//
//  ORFFFile.h
//  Epic
//
//  Created by Rodrigo Sieiro on 11/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "libavformat/avformat.h"
#import "libavutil/opt.h"

@interface ORFFFile : NSObject

@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *format;
@property (nonatomic, strong) NSArray *streams;

@property (nonatomic, assign) BOOL eofReached;
@property (nonatomic, assign) int64_t start_time;
@property (nonatomic, assign) int64_t recording_time;
@property (nonatomic, assign) NSUInteger videoSamples;
@property (nonatomic, assign) NSUInteger audioSamples;

@property (nonatomic, assign) AVFormatContext *context;

- (id)initWithFileName:(NSString *)fileName format:(NSString *)format;

@end
