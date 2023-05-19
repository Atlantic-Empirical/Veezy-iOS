//
//  ORApiRequestSigner.h
//  OroosoLib
//
//  Created by Thomas Purnell-Fisher on 12/4/12.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORApiRequestSigner : NSObject

+ (NSString*)generateSignatureForUrl:(NSString*)finalUrl withTimestamp:(NSString*)timestamp;

@end
