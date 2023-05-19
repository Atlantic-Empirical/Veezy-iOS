//
//  ORFFBitstreamFilter.m
//  Epic
//
//  Created by Rodrigo Sieiro on 12/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORFFBitstreamFilter.h"

@implementation ORFFBitstreamFilter

- (void)dealloc
{
    av_bitstream_filter_close(self.bsfc);
}

- (id)initWithFilterName:(NSString *)filterName
{
    self = [super init];
    if (!self) return nil;
    
    self.filterName = filterName;
    self.bsfc = av_bitstream_filter_init([filterName UTF8String]);

    return self;
}

@end
