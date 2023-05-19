//
//  ORHomeCell_Recent.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 3/24/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ORWatchView, TTTAttributedLabel;

@interface ORWatchVideoCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *viewVideo;
@property (weak, nonatomic) IBOutlet UIView *viewOverlay;
@property (nonatomic, weak) IBOutlet UILabel *lblUserName;
@property (nonatomic, weak) IBOutlet UIImageView *imgAvatar;
@property (nonatomic, weak) IBOutlet UILabel *lblViews;
@property (weak, nonatomic) IBOutlet UILabel *lblDate;
@property (weak, nonatomic) IBOutlet UILabel *lblDuration;
@property (weak, nonatomic) IBOutlet UIView *viewDurationParent;
@property (weak, nonatomic) IBOutlet UIButton *btnAvatar;
@property (weak, nonatomic) IBOutlet UILabel *lblLocation;
@property (weak, nonatomic) IBOutlet UIImageView *imgBadge1;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiUploading;
@property (weak, nonatomic) IBOutlet UIView *viewTimebomb;
@property (weak, nonatomic) IBOutlet UILabel *lblTimebomb;
@property (weak, nonatomic) IBOutlet UIButton *btnLocation;
@property (weak, nonatomic) IBOutlet UIButton *btnFavorite;
@property (weak, nonatomic) IBOutlet UIButton *btnRepost;
@property (weak, nonatomic) IBOutlet UIButton *btnDots;
@property (weak, nonatomic) IBOutlet UIView *viewTitle;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *lblTitle;
@property (weak, nonatomic) IBOutlet UIView *viewButtons;
@property (weak, nonatomic) IBOutlet UIButton *btnShare;
@property (weak, nonatomic) IBOutlet UIButton *btnDelete;
@property (weak, nonatomic) IBOutlet UIView *viewFacebookLike;

@property (nonatomic, weak) ORWatchView *parent;
@property (nonatomic, strong) OREpicVideo *video;

- (CGFloat)heightForCellWithVideo:(OREpicVideo *)video;
- (IBAction)btnAvatar_TouchUpInside:(id)sender;
- (IBAction)btnLocation_TouchUpInside:(id)sender;
- (IBAction)btnFavorite_TouchUpInside:(id)sender;
- (IBAction)btnRepost_TouchUpInside:(id)sender;
- (IBAction)btnDots_TouchUpInside:(id)sender;
- (IBAction)btnDelete_TouchUpInside:(id)sender;
- (IBAction)btnShare_TouchUpInside:(id)sender;

- (void)uploadFinished;
- (void)hardPause;
- (void)softPause;
- (void)unpause;
- (void)play;
- (void)stop;

@end
