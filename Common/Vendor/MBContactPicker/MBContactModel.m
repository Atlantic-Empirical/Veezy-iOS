//
//  MBContactModel.m
//  MBContactPicker
//
//  Created by Matt Bowman on 12/13/13.
//  Copyright (c) 2013 Citrrus, LLC. All rights reserved.
//

#import "MBContactModel.h"

@implementation MBContactModel

- (NSUInteger)hash
{
    return [self.contactTitle hash];
}

- (BOOL)isEqual:(id)object
{
    if (self == object) return YES;
    if (![object isKindOfClass:[self class]]) return NO;
    
    MBContactModel *other = (MBContactModel *)object;
    return [self.contactTitle isEqual:other.contactTitle];
}

@end
