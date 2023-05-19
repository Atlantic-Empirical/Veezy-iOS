//
//  ORFeedbackView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/16/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORFeedbackView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UIButton *btnSend;
@property (weak, nonatomic) IBOutlet UITextField *txtName;
@property (weak, nonatomic) IBOutlet UITextField *txtEmail;
@property (weak, nonatomic) IBOutlet UITextView *txtMessage;
@property (weak, nonatomic) IBOutlet UIButton *btnCloseKeyboard;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiSend;

- (IBAction)btnSend_TouchUpInside:(id)sender;
- (IBAction)btnCloseKeyboard_TouchUpInside:(id)sender;

@end
