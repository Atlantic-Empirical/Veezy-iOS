//
//  ORNoVideosCell.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 16/09/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORNoVideosCell.h"

@implementation ORNoVideosCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setUser:(OREpicFriend *)user
{
	_user = user;
	if ([CurrentUser.userId isEqualToString:self.user.userId]) {
		self.lblMessage.text = @"Any videos you record will be listed here.";
	} else if (user.isPrivate && !user.isFollowing) {
        self.lblMessage.text = [NSString stringWithFormat:@"%@'s videos are private", user.firstName];
    } else {
		self.lblMessage.text = [NSString stringWithFormat:@"%@ hasn't shared any videos", user.firstName];
	}
}

@end
