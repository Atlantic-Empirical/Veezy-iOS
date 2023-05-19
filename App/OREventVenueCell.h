//
//  ORFifaStadiumCell.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/4/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OREpicEventVenue;

@interface OREventVenueCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgVenue;
@property (weak, nonatomic) IBOutlet UILabel *lblDescription;
@property (weak, nonatomic) IBOutlet UILabel *lblVenueName;
@property (weak, nonatomic) IBOutlet UILabel *lblStats;

@property (strong, nonatomic) OREpicEventVenue *venue;
@property (nonatomic, strong) UINavigationController *navigationController;

@end
