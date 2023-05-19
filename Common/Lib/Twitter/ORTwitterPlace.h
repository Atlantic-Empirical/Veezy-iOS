//
//  ORTwitterPlace.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 29/04/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORTwitterPlace : NSObject

@property (copy, nonatomic) NSString *country;
@property (copy, nonatomic) NSString *countryCode;
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *type;
@property (copy, nonatomic) NSString *url;
@property (assign, nonatomic) NSUInteger parentId;
@property (assign, nonatomic) NSUInteger woeId;

+ (id)instanceWithJSON:(NSDictionary *)json;
+ (id)arrayWithJSON:(NSArray *)json;
- (id)initWithJSON:(NSDictionary *)json;

@end
