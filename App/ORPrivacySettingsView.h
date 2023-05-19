//
//  ORPrivacySettingsView.h
//  OneCent
//
//  Created by Thomas Purnell-Fisher on 12/18/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORPrivacySettingsView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UISwitch *swEnhancedPrivacyIsOn;

- (IBAction)swAccountIsPublic_ValueChanged:(id)sender;
- (IBAction)btnPrivacyZones_TouchUpInside:(id)sender;

@end
