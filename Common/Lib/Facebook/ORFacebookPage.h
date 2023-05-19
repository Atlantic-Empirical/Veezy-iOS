//
//  ORFacebookPage.h
//  Veezy
//
//  Created by Rodrigo Sieiro on 28/10/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORFacebookPage : NSObject <NSCoding>

@property (nonatomic, copy) NSString *pageId;
@property (nonatomic, copy) NSString *pageName;
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, readonly) NSString *profilePicture;

+ (id)instanceWithJSON:(NSDictionary *)json;
+ (id)arrayWithJSON:(NSArray *)jsonArray;
- (id)initWithJSON:(NSDictionary *)json;

@end
