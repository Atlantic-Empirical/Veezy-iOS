//
//  ORGroup.m
//  OroosoLib
//
//  Created by Rodrigo Sieiro on 20/07/12.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import "ORGroup.h"

@implementation ORGroup

@synthesize id = _id;
@synthesize name = _name;
@synthesize systemName = _systemName;

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (ID: %@)\n\tSystem: %@", _name, _id, _systemName];
}

- (id)initWithGoogleData:(NSDictionary *)data
{
    self = [super init];

    if (self && data) {
        self.id = [[data objectForKey:@"id"] objectForKey:@"$t"];
        self.name = [[data objectForKey:@"title"] objectForKey:@"$t"];
        self.systemName = [[data objectForKey:@"gContact$systemGroup"] objectForKey:@"id"];
    }

    return self;
}

@end
