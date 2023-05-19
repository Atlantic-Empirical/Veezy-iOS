//
//  ORFacebookEngine.h
//  OroosoLib
//
//  Created by Rodrigo Sieiro on 06/15/12.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.

typedef void (^ORFBArrayCompletion)(NSError *error, NSArray *items);

@interface ORFacebookEngine : NSObject

+ (void)pagesWithCompletion:(ORFBArrayCompletion)completion;
+ (void)likedPagesWithCompletion:(ORFBArrayCompletion)completion;

@end
