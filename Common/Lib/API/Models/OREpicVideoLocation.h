//
//  OREpicVideoLocation.h
//  OneCent
//
//  Created by Thomas Purnell-Fisher on 12/17/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OREpicVideoLocation : NSObject

@property (strong, nonatomic) NSString *videoId;
@property (assign, nonatomic) double latitude;
@property (assign, nonatomic) double longitude;
@property (strong, nonatomic) NSDate *created;

+ (id)instanceWithJSON:(NSDictionary *)json;
+ (id)arrayWithJSON:(NSArray *)json;
- (id)initWithJSON:(NSDictionary *)json;
- (NSMutableDictionary *)proxyForJson;

@property (nonatomic, strong, readonly) NSString* friendlyDateString;

@end
