//
//  ORFFBitstreamFilter.h
//  Epic
//
//  Created by Rodrigo Sieiro on 12/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "libavcodec/avcodec.h"

@interface ORFFBitstreamFilter : NSObject

@property (nonatomic, copy) NSString *filterName;
@property (nonatomic, assign) AVBitStreamFilterContext *bsfc;

- (id) initWithFilterName:(NSString*)filterName;

@end
