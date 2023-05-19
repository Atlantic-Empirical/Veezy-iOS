//
//  ORFacebookPostView.h
//  Veezy
//
//  Created by Rodrigo Sieiro on 11/12/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORFacebookPostView : UIViewController <UITextViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIControl *viewOverlay;
@property (weak, nonatomic) IBOutlet UIView *viewTitle;
@property (weak, nonatomic) IBOutlet UITextView *txtCaption;
@property (weak, nonatomic) IBOutlet UITableView *captionTableView;
@property (weak, nonatomic) IBOutlet UILabel *lblChars;
@property (weak, nonatomic) IBOutlet UIView *viewFacebook;
@property (weak, nonatomic) IBOutlet UIView *viewPosting;

@property (nonatomic, copy) void (^completionBlock)(BOOL success);

- (id)initWithVideo:(OREpicVideo *)video andShareString:(NSString *)shareString;
- (IBAction)viewOverlay_TouchUpInside:(id)sender;
- (IBAction)btnClearCaption_TouchUpInside:(id)sender;

@end
