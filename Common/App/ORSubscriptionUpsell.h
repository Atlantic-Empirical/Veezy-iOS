//
//  ORPostCaptureUpsell.h
//  Veezy
//
//  Created by Thomas Purnell-Fisher on 10/20/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORSubscriptionUpsell : GAITrackedViewController

@property (nonatomic, weak) IBOutlet UIView *viewContent;
@property (nonatomic, weak) IBOutlet UIView *viewLoading;
@property (nonatomic, weak) IBOutlet UIView *viewPurchase;
@property (nonatomic, weak) IBOutlet UIView *viewTrial;
@property (nonatomic, weak) IBOutlet UILabel *lblDescription;
@property (nonatomic, weak) IBOutlet UIButton *btnPurchase_monthly;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *aiPurchasing;
@property (weak, nonatomic) IBOutlet UIImageView *imgLogo;
@property (weak, nonatomic) IBOutlet UILabel *lblPrice_monthly;
@property (weak, nonatomic) IBOutlet UILabel *lblPrice_annual;
@property (weak, nonatomic) IBOutlet UIButton *btnPurchase_annual;
@property (weak, nonatomic) IBOutlet UIButton *btnRestore;
@property (weak, nonatomic) IBOutlet UIButton *btnTrial;

- (IBAction)view_TouchUpInside:(id)sender;
- (IBAction)btnPurchase_TouchUpInside:(id)sender;
- (IBAction)btnPurchase_annual_TouchUpInside:(id)sender;
- (IBAction)btnRestore_TouchUpInside:(id)sender;
- (IBAction)btnTrial_TouchUpInside:(id)sender;

@end
