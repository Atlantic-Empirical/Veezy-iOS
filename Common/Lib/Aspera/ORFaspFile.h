//
//  ORFaspFile.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 22/08/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORFaspFile : NSObject

@property (nonatomic, copy) NSString *source;
@property (nonatomic, copy) NSString *destination;

+ (id)fileWithSource:(NSString *)source destination:(NSString *)destination;
- (id)initWithSource:(NSString *)source destination:(NSString *)destination;

@end
