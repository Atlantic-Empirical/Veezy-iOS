//
//  ORLogItem.h
//  Orooso
//
//  Created by Thomas Purnell-Fisher on 8/9/12.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORLogItem : NSObject <NSCoding>

- (ORLogItem*)initWithTrackId:(NSString *)trackId andParameters:(NSArray *)parameters;

@property (strong, nonatomic) NSString *trackId;
@property (strong, nonatomic) NSString *timestamp;
@property (strong, nonatomic) NSArray *parameters;

- (NSMutableDictionary *) proxyForJson;
+ (NSArray *)proxyForJsonWithArray:(NSArray *)items;

@end
