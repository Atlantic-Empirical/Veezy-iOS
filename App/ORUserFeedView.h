//
//  ORHomeView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 28/03/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORUserFeedView : GAITrackedViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIView *viewNoItems;
@property (nonatomic, weak) IBOutlet UILabel *lblReason;
@property (nonatomic, weak) IBOutlet UIButton *btnAction;

- (IBAction)btnAction_TouchUpInside:(id)sender;

@end
