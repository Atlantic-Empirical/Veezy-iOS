//
//  ORBroadcastBehaviorView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 4/8/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ORCaptureView;

@interface ORBroadcastBehaviorView : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (id)initWithVideo:(OREpicVideo *)video;

@property (weak, nonatomic) IBOutlet UIButton *btnSend;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;
@property (weak, nonatomic) IBOutlet UIView *viewHost;
@property (weak, nonatomic) IBOutlet UIView *viewLocation;
@property (weak, nonatomic) IBOutlet UIView *viewHashtags;
@property (weak, nonatomic) IBOutlet UIButton *btnFb;
@property (weak, nonatomic) IBOutlet UIButton *btnTw;
@property (weak, nonatomic) IBOutlet UIView *viewDrawer;
@property (strong, nonatomic) IBOutlet UIView *viewHashtagDrawer;
@property (strong, nonatomic) IBOutlet UIView *viewLocationDrawer;
@property (weak, nonatomic) IBOutlet UITableView *tblLocation;
@property (weak, nonatomic) IBOutlet UITableView *tblHashtags;
@property (weak, nonatomic) IBOutlet UILabel *lblHashtags;
@property (weak, nonatomic) IBOutlet UIButton *btnClearHashtags;
@property (weak, nonatomic) IBOutlet UITextView *txtCaption;

// HEADER
@property (weak, nonatomic) IBOutlet UIButton *btnHashtags;
@property (weak, nonatomic) IBOutlet UIButton *btnLocation;

@property (weak, nonatomic) ORCaptureView *parent;

- (IBAction)btnSend_TouchUpInside:(id)sender;
- (IBAction)btnCancel_TouchUpInside:(id)sender;
- (IBAction)btnLocation_TouchUpInside:(id)sender;
- (IBAction)btnHashtags_TouchUpInside:(id)sender;
- (IBAction)btnFb_TouchUpInside:(id)sender;
- (IBAction)btnTw_TouchUpInside:(id)sender;
- (IBAction)btnClearHashtags_TouchUpInside:(id)sender;
- (IBAction)drawerCloseAction:(id)sender;

@end
