//
//  ORFaspFile.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 22/08/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORFaspFile.h"

@implementation ORFaspFile

+ (id)fileWithSource:(NSString *)source destination:(NSString *)destination
{
    return [[self alloc] initWithSource:source destination:destination];
}

- (id)initWithSource:(NSString *)source destination:(NSString *)destination
{
    self = [super init];
    if (!self) return nil;
    
    self.source = source;
    self.destination = destination;
    
    return self;
}

- (NSUInteger)hash
{
    return [self.source hash];
}

- (BOOL)isEqual:(id)object
{
    if (self == object) return YES;
    if (![object isKindOfClass:[self class]]) return NO;
    
    ORFaspFile *other = (ORFaspFile *)object;
    return [self.source isEqual:other.source];
}

@end
