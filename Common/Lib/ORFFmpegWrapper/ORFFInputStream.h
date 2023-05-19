//
//  ORFFInputStream.h
//  Epic
//
//  Created by Rodrigo Sieiro on 11/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORFFStream.h"

@interface ORFFInputStream : ORFFStream

@property (nonatomic, assign) int64_t start;
@property (nonatomic, assign) int64_t nextDTS;
@property (nonatomic, assign) int64_t dts;

@property (nonatomic, assign) int64_t nextPTS;
@property (nonatomic, assign) int64_t pts;
@property (nonatomic, assign) double tsScale;
@property (nonatomic, assign) int64_t filterInRescaleDeltaLast;

@property (nonatomic, assign) BOOL wrapCorrectionDone;
@property (nonatomic, assign) BOOL isStart;
@property (nonatomic, assign) BOOL sawFirstTS;
@property (nonatomic, assign) BOOL guessLayoutMax;

- (id)initWithParentFile:(ORFFFile *)parentFile stream:(AVStream *)stream;

@end
