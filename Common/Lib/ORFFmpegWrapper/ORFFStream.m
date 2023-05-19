//
//  ORFFStream.m
//  Epic
//
//  Created by Rodrigo Sieiro on 11/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORFFStream.h"

@implementation ORFFStream

- (id)initWithParentFile:(ORFFFile *)parentFile
{
    self = [super init];
    if (!self) return nil;
    
    self.parentFile = parentFile;
    
    return self;
}

@end
