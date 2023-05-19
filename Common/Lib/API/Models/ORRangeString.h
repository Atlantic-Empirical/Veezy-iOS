//
//  ORTaggedUser.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 12/09/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORRangeString : NSObject

@property (nonatomic, assign) NSRange range;
@property (nonatomic, copy) NSString *string;

+ (id)instanceWithJSONString:(NSString *)jsonString;
+ (id)arrayWithJSONArray:(NSArray *)jsonArray;
- (id)initWithJSONString:(NSString *)jsonString;
- (id)initWithString:(NSString *)string range:(NSRange)range;
- (NSString *)proxyForJson;
+ (NSArray *)proxyForJsonWithArray:(NSArray *)items;


@end
