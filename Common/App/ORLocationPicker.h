//
//  ORLocationPicker.h
//  Session
//
//  Created by Thomas Purnell-Fisher on 11/13/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ORFoursquareVenue;

@interface ORLocationPicker : GAITrackedViewController <UITableViewDataSource, UITableViewDelegate>

- (id)initWithPlaces:(NSArray *)places selectedPlace:(ORFoursquareVenue *)place location:(CLLocation *)location;

@property (weak, nonatomic) IBOutlet UITextField *txtSearch;
@property (weak, nonatomic) IBOutlet UITableView *tbMain;
@property (strong, nonatomic) ORFoursquareVenue *selectedPlace;

- (IBAction)txtSearch_EditingChanged:(id)sender;
- (IBAction)btnCancelSearch_TouchUpInside:(id)sender;

@end
