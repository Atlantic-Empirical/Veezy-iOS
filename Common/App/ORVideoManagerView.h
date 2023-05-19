//
//  ORVideoManagerInnerView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/27/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ORNotifySwitch, ORMoviePlayerView;

@interface ORVideoManagerView : GAITrackedViewController <UITextViewDelegate, UITableViewDataSource, UITableViewDelegate>

- (id)initWithVideo:(OREpicVideo*)video andPlaces:(NSArray*)places;

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutlet UIView *viewThumbHost;

@property (weak, nonatomic) IBOutlet UIView *viewTitle;
@property (weak, nonatomic) IBOutlet UITextView *txtTitle;
@property (weak, nonatomic) IBOutlet UIButton *btnLocation;
@property (weak, nonatomic) IBOutlet UIControl *viewOverlay;
@property (weak, nonatomic) IBOutlet UITableView *captionTableView;
@property (weak, nonatomic) IBOutlet UIButton *btnClearCaption;

@property (weak, nonatomic) IBOutlet UILabel *lblDiscardVideoAfter;
@property (weak, nonatomic) IBOutlet UIView *viewTimebombIndicator;
@property (weak, nonatomic) IBOutlet UIButton *btnTimebomb1hr;
@property (weak, nonatomic) IBOutlet UIButton *btnTimebomb1day;
@property (weak, nonatomic) IBOutlet UIButton *btnTimebomb1week;
@property (weak, nonatomic) IBOutlet UIButton *btnTimebombNever;
@property (weak, nonatomic) IBOutlet UIView *view1Hour;
@property (weak, nonatomic) IBOutlet UIView *view1Day;
@property (weak, nonatomic) IBOutlet UIView *view1Week;
@property (weak, nonatomic) IBOutlet UIView *viewEver;
@property (weak, nonatomic) IBOutlet UILabel *lblExpirationInfo;
@property (weak, nonatomic) IBOutlet UIButton *btnRecoverVideo;

@property (weak, nonatomic) IBOutlet UIView *viewShareButtons;
@property (weak, nonatomic) IBOutlet UIView *viewIndicator;
@property (weak, nonatomic) IBOutlet UIButton *btnPrivate;
@property (weak, nonatomic) IBOutlet UIButton *btnPublic;
@property (weak, nonatomic) IBOutlet UIView *viewFollowers;
@property (weak, nonatomic) IBOutlet UIView *viewJustMe;

- (IBAction)btnLocation_TouchUpInside:(id)sender;
- (IBAction)viewOverlay_TouchUpInside:(id)sender;
- (IBAction)btnTimebomb1hr_TouchUpInside:(id)sender;
- (IBAction)btnTimebomb1day_TouchUpInside:(id)sender;
- (IBAction)btnTimebomb1week_TouchUpInside:(id)sender;
- (IBAction)btnTimebombNever_TouchUpInside:(id)sender;
- (IBAction)btnClearCaption_TouchUpInside:(id)sender;
- (IBAction)btnPrivate_TouchUpInside:(id)sender;
- (IBAction)btnPublic_TouchUpInside:(id)sender;
- (IBAction)btnRecoverVideo_TouchUpInside:(id)sender;

@property (nonatomic, strong) ORMoviePlayerView *moviePlayer;

- (void)layoutSubviews;
- (void)prepareTags;
- (void)deleteVideo;

@end
