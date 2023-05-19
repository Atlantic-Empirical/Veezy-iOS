//
//  ORAVFileProcessor.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 28/05/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORAVProcessor.h"

@interface ORAVURLProcessor : ORAVProcessor

-(void)transcodeURL:(NSURL *)url start:(ORAVProcessorCompletion)start progress:(ORAVProcessorProgress)progress completion:(ORAVProcessorCompletion)completion;

@end
