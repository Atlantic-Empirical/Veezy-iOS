//
//  ORTwitterTrend.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 29/04/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORTwitterTrend : NSObject

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *query;
@property (copy, nonatomic) NSString *url;

+ (id)instanceWithJSON:(NSDictionary *)json;
+ (id)arrayWithJSON:(NSArray *)json;
- (id)initWithJSON:(NSDictionary *)json;

@end
