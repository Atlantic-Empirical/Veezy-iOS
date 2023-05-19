//
//  ORAddEmailView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 14/04/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORAddEmailView : GAITrackedViewController

@property (nonatomic, weak) IBOutlet UIView *viewBox;
@property (nonatomic, weak) IBOutlet UIButton *btnTapCatcher;
@property (nonatomic, weak) IBOutlet UIButton *btnDone;
@property (nonatomic, weak) IBOutlet UITextField *txtEmail;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *aiLoading;
@property (weak, nonatomic) IBOutlet UIButton *btnSignout;

- (IBAction)btnTapCatcher_TouchUpInside:(id)sender;
- (IBAction)btnDone_TouchUpInside:(id)sender;
- (IBAction)btnSignout_TouchUpInside:(id)sender;
- (IBAction)btnPrivacy_TouchUpInside:(id)sender;

@end
