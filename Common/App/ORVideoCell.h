//
//  ORHomeCell_Recent.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 3/24/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TTTAttributedLabel;

@interface ORVideoCell : UITableViewCell

@property (strong, nonatomic) OREpicFeedItem *item;
@property (nonatomic, strong) OREpicVideo *video;

@property (weak, nonatomic) IBOutlet UIView *viewContent;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiLoading;
@property (nonatomic, weak) IBOutlet UIImageView *imgThumbnail;
@property (nonatomic, weak) IBOutlet UILabel *lblUserName;
@property (nonatomic, weak) IBOutlet UIImageView *imgAvatar;
@property (weak, nonatomic) IBOutlet UILabel *lblDate;
@property (weak, nonatomic) IBOutlet UILabel *lblDuration;
@property (weak, nonatomic) IBOutlet UIView *viewDurationParent;
@property (weak, nonatomic) IBOutlet UIButton *btnAvatar;
@property (weak, nonatomic) IBOutlet UILabel *lblLocation;
@property (weak, nonatomic) IBOutlet UIImageView *imgPublic;
@property (weak, nonatomic) IBOutlet UIImageView *imgBadge1;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiUploading;
@property (weak, nonatomic) IBOutlet UIButton *btnExpiringInfo;
@property (weak, nonatomic) IBOutlet UIView *viewTimebomb;
@property (weak, nonatomic) IBOutlet UILabel *lblTimebomb;
@property (weak, nonatomic) IBOutlet UIImageView *imgRepost;
@property (weak, nonatomic) IBOutlet UILabel *lblReposter;
@property (weak, nonatomic) IBOutlet UIView *viewLocationHost;
@property (weak, nonatomic) IBOutlet UIView *viewForBorder;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *txtTitle;
@property (weak, nonatomic) IBOutlet UIButton *btnPlay;
@property (weak, nonatomic) IBOutlet UIImageView *imgDirect;
@property (weak, nonatomic) IBOutlet UILabel *lblLikesCount;
@property (weak, nonatomic) IBOutlet UILabel *lblViewsCount;
@property (weak, nonatomic) IBOutlet UIView *viewViewsAndLikes;
@property (weak, nonatomic) IBOutlet UIImageView *imgHeart;

@property (nonatomic, weak) UIViewController *parent;

- (CGFloat)heightForCellWithVideo:(OREpicVideo *)video;

- (IBAction)btnAvatar_TouchUpInside:(id)sender;
- (IBAction)btnPlay_TouchUpInside:(id)sender;

- (void)updateUploadingProgress:(float)progress;
- (void)uploadFinished;

@end
