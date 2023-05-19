//
//  ORTwitterHashtag.h
//  OroosoLib
//
//  Created by Rodrigo Sieiro on 03/11/2012.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORTwitterHashtag : NSObject <NSCoding>

@property (copy, nonatomic) NSString *text;
@property (strong, nonatomic) NSMutableArray *indices;

+ (id)instanceWithJSON:(NSDictionary *)json;
+ (id)arrayWithJSON:(NSArray *)json;
- (id)initWithJSON:(NSDictionary *)json;
- (NSMutableDictionary *)proxyForJson;
+ (NSMutableArray *)proxyForJsonWithArray:(NSArray *)array;

- (id)initWithTwitterJSON:(NSDictionary *)jsonData;
- (void)parseTwitterJSON:(NSDictionary *)jsonData;

@end
