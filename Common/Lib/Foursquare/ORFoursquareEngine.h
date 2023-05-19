//
//  ORPlacesEngine.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 12/27/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "MKNetworkEngine.h"

@class ORFoursquarePlacesResult, ORFoursquareVenue, CLLocation;

typedef void (^ORFoursquareArrayCompletionBlock)(NSError *error, NSArray *items);

@interface ORFoursquareEngine : MKNetworkEngine

+ (ORFoursquareEngine *)sharedInstance;
- (void)getPlacesForLocation:(CLLocation *)location andRadiusMeters:(int)radius completion:(ORFoursquareArrayCompletionBlock)completion;
- (void)addCustomPlace:(ORFoursquareVenue *)place;

@end
