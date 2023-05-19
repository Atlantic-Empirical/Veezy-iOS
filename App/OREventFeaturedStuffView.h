//
//  OREventFeaturedStuffView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/28/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OREventFeaturedStuffView : UIViewController

- (id)initWithEvent:(OREpicEvent*)event;

@property (weak, nonatomic) IBOutlet UIView *viewHost;
@property (weak, nonatomic) IBOutlet UIButton *btnVideos;
@property (weak, nonatomic) IBOutlet UIButton *btnPeople;
@property (weak, nonatomic) IBOutlet UITableView *tblMain;

- (IBAction)btnVideos_TouchUpInside:(id)sender;
- (IBAction)btnPeople_TouchUpInside:(id)sender;

@end
