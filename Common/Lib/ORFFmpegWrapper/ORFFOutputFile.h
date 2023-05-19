//
//  ORFFOutputFile.h
//  Epic
//
//  Created by Rodrigo Sieiro on 11/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORFFFile.h"

@class ORFFInputFile, ORFFOutputStream, ORFFInputStream;

@interface ORFFOutputFile : ORFFFile

@property (nonatomic, weak) ORFFInputFile *inputFile;
@property (nonatomic, strong) NSMutableSet *bitstreamFilters;
@property (nonatomic, assign) int64_t offsetPTS;
@property (nonatomic, assign) int64_t lastPTS;

@property (nonatomic, assign) NSUInteger skipVideoSamples;
@property (nonatomic, assign) NSUInteger skipAudioSamples;
@property (nonatomic, assign) BOOL firstSample;

- (id)initWithFileName:(NSString *)fileName inputFile:(ORFFInputFile *)inputFile format:(NSString *)format;
- (BOOL)writeHeaderWithError:(NSError **)error;
- (BOOL)writeTrailerWithError:(NSError **)error;
- (ORFFOutputStream *)outputStreamForInputStream:(ORFFInputStream *)inputStream;

@end
