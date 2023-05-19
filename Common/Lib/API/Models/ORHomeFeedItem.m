//
//  ORHomeFeedItem.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 25/03/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORHomeFeedItem.h"

@implementation ORHomeFeedItem

+ (ORHomeFeedItem *)itemWithType:(ORHomeFeedItemType)type
{
    ORHomeFeedItem *item = [ORHomeFeedItem new];
    item.type = type;
    
    return item;
}

@end
