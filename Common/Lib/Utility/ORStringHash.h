//
//  ORStringHash.h
//  Orooso
//
//  Created by Thomas Purnell-Fisher on 8/8/12.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORStringHash : NSObject

+ (NSString*) computeHash_HMACSHA256:(NSString*)stringToHash withKey:(NSString*)key;
+ (NSString *) createSHA512:(NSString *)source;

@end
