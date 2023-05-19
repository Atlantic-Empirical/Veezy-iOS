//
//  ORHomeCell_NewFollower.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 03/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORHomeCell_NewFollower.h"
#import "ORUserProfileViewParent.h"
#import <QuartzCore/QuartzCore.h>

@implementation ORHomeCell_NewFollower

- (void)awakeFromNib
{
	self.imgAvatar.layer.cornerRadius = 2.0f;
}

- (void)setItem:(OREpicFeedItem *)item
{
    _item = item;
    
    self.lblUserName.text = @"Loading...";
    self.imgAvatar.image = [UIImage imageNamed:@"profile"];
    
    if (item.friend) {
        [self setupForFriend:item.friend];
    } else if (item.video.user) {
        [self setupForFriend:item.video.user];
    } else if (item.friendId) {
        __weak NSString *weakUserId = item.friendId;
        __weak ORHomeCell_NewFollower *weakSelf = self;
        
        [ApiEngine friendWithId:item.friendId completion:^(NSError *error, OREpicFriend *user) {
            if (![weakSelf.item.friendId isEqualToString:weakUserId]) return;
            
            if (user) {
                weakSelf.item.friend = user;
                [weakSelf setupForFriend:user];
            } else {
                weakSelf.lblUserName.text = @"<error occurred>";
            }
        }];
    }
}

- (void)setupForFriend:(OREpicFriend *)friend
{
    self.lblUserName.text = friend.name;
	self.lblViewCount.text = [NSString stringWithFormat:@"%d", friend.viewCount];
    self.lblFavoriteCount.text = [NSString stringWithFormat:@"%d", friend.likeCount];
    self.lblRepostCount.text = [NSString stringWithFormat:@"%d", friend.repostCount];

    if (friend.profileImageUrl) {
        NSURL *url = [NSURL URLWithString:friend.profileImageUrl];
        __weak OREpicFeedItem *weakItem = self.item;
        __weak ORHomeCell_NewFollower *weakSelf = self;
        
        [[ORCachedEngine sharedInstance] imageAtURL:url size:self.imgAvatar.frame.size fill:YES maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
            if (error) {
                NSLog(@"Error: %@", error);
            } else {
                if (image && weakSelf.item == weakItem) {
                    weakSelf.imgAvatar.image = image;
                }
            }
        }];
    }
}

- (void)cell_TouchUpInside:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMarkItemAsSeen" object:self.item];
    
    ORUserProfileViewParent *vc = [[ORUserProfileViewParent alloc] initWithFriend:self.item.friend];
    [self.parent.navigationController pushViewController:vc animated:YES];
}

@end
