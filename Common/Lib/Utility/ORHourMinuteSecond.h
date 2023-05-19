//
//  ORHourMinuteSecond.h
//  Orooso
//
//  Created by Thomas Purnell-Fisher on 10/10/12.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORHourMinuteSecond : NSObject

- (ORHourMinuteSecond*)initWithSeconds:(int)seconds;
- (ORHourMinuteSecond*)initWithMilliseconds:(int)milliseconds;

- (NSString*)friendlyString_HMMSS;
- (NSString*)friendlyString_HMS;

@property (assign, nonatomic) int hours;
@property (assign, nonatomic) int minutes;
@property (assign, nonatomic) int seconds;

@property (assign, nonatomic) int totalMillis;
@property (assign, nonatomic) int totalSeconds;
@property (assign, nonatomic) float totalMinutes;
@property (assign, nonatomic) float totalHours;

@end
