//
//  ORUserProfileCell.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 16/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ORUserProfileView;

@interface ORUserProfileCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *btnAvatar;
@property (weak, nonatomic) IBOutlet UIButton *btnFollow;
@property (weak, nonatomic) IBOutlet UIButton *btnApprove;
@property (weak, nonatomic) IBOutlet UIButton *btnDeny;
@property (weak, nonatomic) IBOutlet UILabel *lblBlocked;
@property (weak, nonatomic) IBOutlet UILabel *lblLikeCount;
@property (weak, nonatomic) IBOutlet UILabel *lblViewCount;
@property (weak, nonatomic) IBOutlet UITextView *txtBio;
@property (weak, nonatomic) IBOutlet UILabel *lblRepostCount;
@property (weak, nonatomic) IBOutlet UIImageView *imgAvatar;
@property (weak, nonatomic) IBOutlet UILabel *lblName;
@property (weak, nonatomic) IBOutlet UIButton *btnFollowing;
@property (weak, nonatomic) IBOutlet UIButton *btnFollowers;
@property (weak, nonatomic) IBOutlet UIButton *btnVideos;
@property (weak, nonatomic) IBOutlet UILabel *lblFollowing;
@property (weak, nonatomic) IBOutlet UILabel *lblFollowers;
@property (weak, nonatomic) IBOutlet UIButton *btnMap;
@property (weak, nonatomic) IBOutlet UIImageView *imgMap;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiUpdating;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiFollowers;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiFollowing;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiMap;
@property (weak, nonatomic) IBOutlet UILabel *lblVideoCount;

@property (strong, nonatomic) OREpicFriend *user;
@property (weak, nonatomic) ORUserProfileView *parent;

- (void)loadMapButtonForVideos:(NSArray *)videos;
- (IBAction)btnAvatar_TouchUpInside:(id)sender;
- (IBAction)btnFollow_TouchUpInside:(id)sender;
- (IBAction)btnFollowers_TouchUpInside:(id)sender;
- (IBAction)btnFollowing_TouchUpInsie:(id)sender;
- (IBAction)btnVideos_TouchUpInside:(id)sender;
- (IBAction)btnMap_TouchUpInside:(id)sender;
- (IBAction)btnApprove_TouchUpInside:(id)sender;
- (IBAction)btnDeny_TouchUpInside:(id)sender;

@end
