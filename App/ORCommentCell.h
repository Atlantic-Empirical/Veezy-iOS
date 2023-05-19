//
//  ORCommentCell.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 15/01/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TTTAttributedLabel;

@interface ORCommentCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *lblDate;
@property (nonatomic, weak) IBOutlet UILabel *lblName;
@property (nonatomic, weak) IBOutlet TTTAttributedLabel *lblComment;
@property (nonatomic, weak) IBOutlet UIImageView *imgProfile;
@property (nonatomic, weak) UIViewController *parent;
@property (nonatomic, strong) OREpicVideoComment *comment;

+ (CGFloat)heightForCellWithComment:(OREpicVideoComment *)comment;
- (IBAction)showUserProfile:(id)sender;

@end
