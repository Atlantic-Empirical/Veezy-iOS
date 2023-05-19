//
//  ORSubscriptionManager_plus.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 1/17/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORAccountManagerView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UILabel *lblText;
@property (weak, nonatomic) IBOutlet UIButton *btnManageSubscription;
@property (weak, nonatomic) IBOutlet UIButton *btnStats;

- (IBAction)btnManageSubscription_TouchUpInside:(id)sender;
- (IBAction)btnStats_TouchUpInside:(id)sender;

@end
