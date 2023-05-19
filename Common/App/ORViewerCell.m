//
//  ORViewerCell.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 1/7/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORViewerCell.h"

@implementation ORViewerCell

- (void)setEFriend:(OREpicFriend *)eFriend
{
	_eFriend = eFriend;

	self.lblName.text = eFriend.firstName;

	if (self.eFriend.profileImageUrl) {
		[[ORCachedEngine sharedInstance] imageAtURL:[NSURL URLWithString:self.eFriend.profileImageUrl] maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
			if (error) {
				NSLog(@"Error: %@", error);
				self.imgAvatar.image = [UIImage imageNamed:@"profile"];
			}
			else {
				self.imgAvatar.image = image;
			}
		}];
	} else {
		self.imgAvatar.image = [UIImage imageNamed:@"profile"];
	}
}

@end
