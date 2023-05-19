//
//  ORMyCommentCell.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 15/01/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ORWatchView, TTTAttributedLabel;

@interface ORMyCommentCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *lblDate;
@property (nonatomic, weak) IBOutlet UILabel *lblName;
@property (nonatomic, weak) IBOutlet TTTAttributedLabel *lblComment;
@property (nonatomic, weak) IBOutlet UIImageView *imgProfile;

@property (nonatomic, weak) ORWatchView *parent;
@property (nonatomic, strong) OREpicVideoComment *comment;

@end
