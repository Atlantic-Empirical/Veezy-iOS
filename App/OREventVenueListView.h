//
//  ORFifaStadiumParentViewController.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/4/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OREventVenueListView : UIViewController

- (id)initWithEvent:(OREpicEvent*)event;

@property (weak, nonatomic) IBOutlet UITableView *tblMain;

@end
