//
//  ORVerifyEmailView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 14/04/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORVerifyEmailView : GAITrackedViewController

@property (nonatomic, weak) IBOutlet UIView *viewBox;
@property (nonatomic, weak) IBOutlet UIButton *btnTapCatcher;
@property (nonatomic, weak) IBOutlet UIButton *btnSend;
@property (nonatomic, weak) IBOutlet UIButton *btnNoThanks;
@property (nonatomic, weak) IBOutlet UITextField *txtEmail;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *aiLoading;

- (IBAction)btnTapCatcher_TouchUpInside:(id)sender;
- (IBAction)btnNoThanks_TouchUpInside:(id)sender;
- (IBAction)btnSend_TouchUpInside:(id)sender;

@end
