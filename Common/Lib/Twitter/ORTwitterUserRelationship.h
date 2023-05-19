//
//  ORTwitterUserRelationships.h
//  OroosoLib
//
//  Created by Thomas Purnell-Fisher on 2/7/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORTwitterUserRelationship : NSObject <NSCoding>

@property (strong, nonatomic) NSString *name;
@property (assign, nonatomic) u_int64_t userId;
@property (strong, nonatomic) NSString *screenName;
@property (assign, nonatomic) BOOL isFollowing;
@property (assign, nonatomic) BOOL isFollowedBy;
@property (assign, nonatomic) BOOL followingRequested;

+ (id)instanceWithJSON:(NSDictionary *)json;
+ (id)arrayWithJSON:(NSArray *)json;
- (id)initWithJSON:(NSDictionary *)json;
- (NSMutableDictionary *)proxyForJson;

- (id)initWithTwitterJSON:(NSDictionary *)jsonData;
- (void)parseTwitterJSON:(NSDictionary *)jsonData;

@end
