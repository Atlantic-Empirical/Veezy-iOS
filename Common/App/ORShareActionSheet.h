//
//  ORShareActionSheet.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 5/24/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORShareActionSheet : GAITrackedViewController

- (id)initWithVideo:(OREpicVideo*)video andImage:(UIImage*)image showFacebookAndTwitter:(BOOL)showFbAndTw;

@property (weak, nonatomic) IBOutlet UIButton *btnMessage;
@property (weak, nonatomic) IBOutlet UIButton *btnMail;
@property (weak, nonatomic) IBOutlet UIButton *btnTwitter;
@property (weak, nonatomic) IBOutlet UIButton *btnFacebook;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;
@property (weak, nonatomic) IBOutlet UIView *viewMain;
@property (weak, nonatomic) IBOutlet UIButton *btnWhatsApp;
@property (weak, nonatomic) IBOutlet UIButton *btnUrl;
@property (weak, nonatomic) IBOutlet UIButton *btnEmbed;
@property (weak, nonatomic) IBOutlet UIButton *btnVeezyDirect;
@property (weak, nonatomic) IBOutlet UIView *viewTwitterTile;
@property (weak, nonatomic) IBOutlet UIView *viewFacebookTile;

@property (nonatomic, weak) UIViewController *parentVC;

- (IBAction)btnMessage_TouchUpInside:(id)sender;
- (IBAction)btnMail_TouchUpInside:(id)sender;
- (IBAction)btnTwitter_TouchUpInside:(id)sender;
- (IBAction)btnFacebook_TouchUpInside:(id)sender;
- (IBAction)btnCancel_TouchUpInside:(id)sender;
- (IBAction)btnWhatsApp_TouchUpInside:(id)sender;
- (IBAction)btnUrl_TouchUpInside:(id)sender;
- (IBAction)btnEmbed_TouchUpInside:(id)sender;
- (IBAction)btnVeezyDirect_TouchUpInside:(id)sender;

@end
