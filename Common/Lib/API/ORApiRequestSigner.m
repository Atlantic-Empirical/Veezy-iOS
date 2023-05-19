//
//  ORApiRequestSigner.m
//  OroosoLib
//
//  Created by Thomas Purnell-Fisher on 12/4/12.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import "ORApiRequestSigner.h"
#import "NSString+MKNetworkKitAdditions.h"

#define SECRET_PART_1 @"XyrBeFh8Fb8VZX"
#define SECRET_PART_2 @"9TiF7cFzGLYnJL"

@implementation ORApiRequestSigner

+ (NSString*)generateSignatureForUrl:(NSString *)finalUrl withTimestamp:(NSString*)timestamp
{
    finalUrl = [finalUrl stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    finalUrl = [finalUrl stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    NSString *baseString = [NSString stringWithFormat:@"%@%@%@%@", SECRET_PART_1, timestamp, finalUrl, SECRET_PART_2];
	return [baseString mk_md5];
}

@end
