//
//  ORBitlyEngine.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/28/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "MKNetworkEngine.h"

@class ORBitlyResponse;

typedef void (^ORBitlyCompletionBlock)(NSError *error, ORBitlyResponse *response);

@interface ORBitlyEngine : MKNetworkEngine

+ (ORBitlyEngine *)sharedInstance;
- (void)shortenURL:(NSString *)url completion:(ORBitlyCompletionBlock)completion;

@end
