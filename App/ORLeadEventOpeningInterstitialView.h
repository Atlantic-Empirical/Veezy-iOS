//
//  OROpeningInterstitial_FIFA.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/2/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORLeadEventOpeningInterstitialView : UIViewController

- (id)initWithEvent:(OREpicEvent*)event;

@property (weak, nonatomic) IBOutlet UIButton *btnGoToEvent;
@property (weak, nonatomic) IBOutlet UIButton *btnContinue;
@property (weak, nonatomic) IBOutlet UILabel *lblEventName;
@property (weak, nonatomic) IBOutlet UIImageView *imgMain;
@property (weak, nonatomic) IBOutlet UILabel *lblSponsorName;

- (IBAction)btnGoToEvent_TouchUpInside:(id)sender;
- (IBAction)btnContinue_TouchUpInside:(id)sender;

@property (assign, nonatomic) BOOL isFromSignIn;

@end
