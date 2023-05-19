//
//  ORFFStream.h
//  Epic
//
//  Created by Rodrigo Sieiro on 11/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "libavformat/avformat.h"

@class ORFFFile;

@interface ORFFStream : NSObject

@property (nonatomic, assign) NSUInteger originalIndex;
@property (nonatomic, weak) ORFFFile *parentFile;
@property (nonatomic, assign) AVStream *stream;
@property (nonatomic, assign) AVRational framerate;

- (id)initWithParentFile:(ORFFFile *)parentFile;

@end
