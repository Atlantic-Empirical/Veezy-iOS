//
//  OREpicUserCounts.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 01/08/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OREpicUserCounts : NSObject

@property (assign, nonatomic) NSUInteger likes;
@property (assign, nonatomic) NSUInteger views;
@property (assign, nonatomic) NSUInteger totalVideos;
@property (assign, nonatomic) NSUInteger videos;
@property (assign, nonatomic) NSUInteger reposts;
@property (assign, nonatomic) NSUInteger feed;
@property (assign, nonatomic) NSUInteger notifications;
@property (assign, nonatomic) NSUInteger following;
@property (assign, nonatomic) NSUInteger followers;

+ (id)instanceWithJSON:(NSDictionary *)json;
- (id)initWithJSON:(NSDictionary *)json;

@end
