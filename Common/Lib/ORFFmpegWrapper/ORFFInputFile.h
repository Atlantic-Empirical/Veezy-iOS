//
//  ORFFInputFile.h
//  Epic
//
//  Created by Rodrigo Sieiro on 11/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORFFFile.h"

@interface ORFFInputFile : ORFFFile

@property (nonatomic, assign) int64_t tsOffset;
@property (nonatomic, assign) int64_t lastTS;

- (BOOL)readFrameIntoPacket:(AVPacket *)packet error:(NSError **)error;

@end
