//
//  ORVideoOrderCell.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 16/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ORUserProfileView;

@interface ORVideoOrderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *viewIndicatorLine;
@property (weak, nonatomic) IBOutlet UILabel *lblVideos;
@property (weak, nonatomic) IBOutlet UIButton *btnOrderBy_Recency;
@property (weak, nonatomic) IBOutlet UIButton *btnOrderBy_Views;
@property (weak, nonatomic) IBOutlet UIButton *btnOrderBy_Likes;
@property (weak, nonatomic) IBOutlet UIButton *btnOrderBy_Reposts;
@property (weak, nonatomic) IBOutlet UILabel *lblViews;
@property (weak, nonatomic) IBOutlet UILabel *lblDate;
@property (weak, nonatomic) IBOutlet UILabel *lblViewCount;
@property (weak, nonatomic) IBOutlet UILabel *lblComments;
@property (weak, nonatomic) IBOutlet UIImageView *imgIndicator;
@property (weak, nonatomic) IBOutlet UIButton *btnPlus;
@property (weak, nonatomic) IBOutlet UIView *viewSeparator;

@property (strong, nonatomic) OREpicFriend *user;
@property (weak, nonatomic) ORUserProfileView *parent;

- (IBAction)navToTab:(UIButton *)button;

- (void)updateVideoCount:(int)count;

@end
