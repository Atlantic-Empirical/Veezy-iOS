//
//  ORPreCaptureView.h
//  Veezy
//
//  Created by Rodrigo Sieiro on 24/11/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORPreCaptureView : UIViewController <UITextViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIControl *viewBackground;
@property (weak, nonatomic) IBOutlet UIControl *viewOverlay;
@property (weak, nonatomic) IBOutlet UIView *viewTitle;
@property (weak, nonatomic) IBOutlet UITextView *txtCaption;
@property (weak, nonatomic) IBOutlet UITableView *captionTableView;
@property (weak, nonatomic) IBOutlet UILabel *lblChars;
@property (weak, nonatomic) IBOutlet UIButton *btnPlus;
@property (nonatomic, weak) IBOutlet UIView *viewTrialMode;

- (IBAction)btnTrialMode_TouchUpInside:(id)sender;
- (IBAction)viewBackground_TouchUpInside:(id)sender;
- (IBAction)viewOverlay_TouchUpInside:(id)sender;
- (IBAction)btnClearCaption_TouchUpInside:(id)sender;
- (IBAction)btnLocation_TouchUpInside:(id)sender;
- (IBAction)btnPlus_TouchUpInside:(id)sender;

@end
