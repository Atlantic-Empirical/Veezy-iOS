//
//  ORABTestAdmin.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/2/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORABTestAdmin : UIViewController

@property (weak, nonatomic) IBOutlet UISwitch *swFIFA;

- (IBAction)swFIFA_ValueChanged:(id)sender;

@end
