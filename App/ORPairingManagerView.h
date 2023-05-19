//
//  ORSocialConfigView.h
//  OneCent
//
//  Created by Thomas Purnell-Fisher on 12/18/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORPairingManagerView : GAITrackedViewController

@property (nonatomic, weak) IBOutlet UIButton *btnTwitter;
@property (nonatomic, weak) IBOutlet UIButton *btnFacebook;
@property (nonatomic, weak) IBOutlet UIButton *btnGoogle;
@property (nonatomic, weak) IBOutlet UIButton *btnCancel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *aiLoading;

- (IBAction)btnTwitter_TouchUpInside:(id)sender;
- (IBAction)btnFacebook_TouchUpInside:(id)sender;
- (IBAction)btnGoogle_TouchUpInside:(id)sender;
- (IBAction)btnCancel_TouchUpInside:(id)sender;

@end
