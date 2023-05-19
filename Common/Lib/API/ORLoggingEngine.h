//
//  ORLoggingEngine.h
//  OroosoLib
//
//  Created by Thomas Purnell-Fisher on 3/25/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORLoggingEngine : NSObject

+ (ORLoggingEngine *)sharedInstance;
- (void)addLogItemAtLocation:(NSString *)location andEvent:(NSString *)event withParams:(NSMutableArray *)params;
- (void)addLogItemAtLocation:(NSString *)location tappedItemName:(NSString *)btnName;

+ (void)logEvent:(NSString *)event params:(NSMutableArray *)params;
+ (void)logEvent:(NSString *)event video:(NSString *)video msg:(NSString *)message, ...;
+ (void)logEvent:(NSString *)event msg:(NSString *)message, ...;

@property (nonatomic, copy) NSString *company;
@property (nonatomic, copy) NSString *serviceContext;
@property (nonatomic, copy) NSString *environment;
@property (nonatomic, copy) NSString *device;

- (void)flushLogs;

@end
