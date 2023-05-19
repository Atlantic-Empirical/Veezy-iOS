//
//  OREpicGroup.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 13/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OREpicGroup : NSObject <NSCoding>

@property (nonatomic, copy) NSString *groupId;
@property (nonatomic, copy) NSString *ownerId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSDate *created;
@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, strong) NSMutableArray *userIds;
@property (nonatomic, copy) NSDate *lastActivity;

+ (id)instanceWithJSON:(NSDictionary *)json;
+ (id)arrayWithJSON:(NSArray *)json;
- (id)initWithJSON:(NSDictionary *)json;
- (NSMutableDictionary *)proxyForJson;

@end
