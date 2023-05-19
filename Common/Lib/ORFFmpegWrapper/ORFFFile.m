//
//  ORFFFile.m
//  Epic
//
//  Created by Rodrigo Sieiro on 11/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORFFFile.h"

@implementation ORFFFile

- (id)initWithFileName:(NSString *)fileName format:(NSString *)format
{
    self = [super init];
    if (!self) return nil;
    
    self.fileName = fileName;
    self.format = format;
        
    return self;
}

@end
