//
//  ORGeneralSettingsView.h
//  OneCent
//
//  Created by Thomas Purnell-Fisher on 12/18/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORTransferSettingsView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UISwitch *swWifiTransferOnly;
@property (weak, nonatomic) IBOutlet UIButton *btnStats;
@property (weak, nonatomic) IBOutlet UILabel *lblVideoQuality;
@property (weak, nonatomic) IBOutlet UILabel *lblDataUsageMessage;

- (IBAction)swWifiTransferOnly_ValueChanged:(id)sender;
- (IBAction)btnStats_TouchUpInside:(id)sender;
- (IBAction)btnVideoQuality_TouchUpInside:(id)sender;

@end
