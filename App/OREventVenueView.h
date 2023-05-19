//
//  ORFifaStadiumViewViewController.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/4/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OREpicEventVenue;

@interface OREventVenueView : UIViewController

- (id)initWithVenue:(OREpicEventVenue*)stadium;

@property (weak, nonatomic) IBOutlet UIView *videoListParent;
@property (weak, nonatomic) IBOutlet UILabel *lblNoVideos;

@end
