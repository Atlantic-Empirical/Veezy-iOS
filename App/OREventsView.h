//
//  OREventsView.h
//  OneCent
//
//  Created by Thomas Purnell-Fisher on 12/15/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OREventsView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UITableView *tblEvents;
@property (weak, nonatomic) IBOutlet UIView *viewTableParent;
@property (weak, nonatomic) IBOutlet UIView *viewLeadEvent;
@property (weak, nonatomic) IBOutlet UIView *viewSponsorViewHost;

@end
