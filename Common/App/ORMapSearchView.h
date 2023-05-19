//
//  ORMapSearchView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 1/25/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORMapSearchView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *txtSearch;
@property (weak, nonatomic) IBOutlet UIButton *btnDone;

- (IBAction)btnDone_TouchUpInside:(id)sender;
- (IBAction)view_TouchUpInside:(id)sender;

@end
