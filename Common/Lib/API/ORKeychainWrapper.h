//
//  ORKeychainWrapper.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 17/09/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORKeychainWrapper : NSObject

+ (id)objectForService:(NSString *)service group:(NSString *)group;
+ (BOOL)setObject:(id)object forService:(NSString *)service group:(NSString *)group;
+ (BOOL)removeObjectForService:(NSString *)service group:(NSString *)group;

@end
