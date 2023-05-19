//
//  ORGroup.h
//  OroosoLib
//
//  Created by Rodrigo Sieiro on 20/07/12.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORGroup : NSObject

@property (nonatomic, copy) NSString *id;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *systemName;

- (id)initWithGoogleData:(NSDictionary *)data;

@end
