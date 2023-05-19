//
//  ORGoProListView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 5/18/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ORGoProEngine;

@interface ORGoProListView : UIViewController

- (id)initWithGoProEngine:(ORGoProEngine*)gpe;

@property (weak, nonatomic) IBOutlet UIButton *btnClose;
@property (weak, nonatomic) IBOutlet UITableView *tblMain;

- (IBAction)btnClose_TouchUpInside:(id)sender;

@end
