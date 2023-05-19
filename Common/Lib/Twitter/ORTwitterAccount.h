//
//  ORTwitterAccount.h
//  Veezy
//
//  Created by Rodrigo Sieiro on 30/10/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORTwitterAccount : NSObject <NSCoding>

@property (nonatomic, copy) NSString *screenName;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *tokenSecret;

- (id)initWithResponseBody:(NSString *)responseBody;

@end
