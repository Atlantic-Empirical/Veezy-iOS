//
//  ORAnonLandingView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 8/19/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORAnonLandingView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UIView *viewContent;
@property (weak, nonatomic) IBOutlet UIButton *btnSignIn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiLoading;
@property (nonatomic, strong) UIToolbar *blur;

- (IBAction)btnSignIn_TouchUpInside:(id)sender;
- (IBAction)viewBg_TouchUpInside:(id)sender;

@end
