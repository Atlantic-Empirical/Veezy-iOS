//
//  ORLiveCell.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 3/24/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORHomeCell_Live.h"

@implementation ORHomeCell_Live

- (void)setItem:(OREpicFeedItem *)item
{
    _item = item;
    [self.aiLoading stopAnimating];

    self.lblUserName.text = @"Loading...";
    self.lblLocation.text = item.video.locationFriendlyName;
    self.imgAvatar.image = [UIImage imageNamed:@"profile"];
    
    if (item.type == ORFeedItemTypeFriendIsLiveAwesome) {
        self.viewLiveBadge.hidden = NO;
        self.viewNotLiveBadge.hidden = YES;
    } else {
        self.viewLiveBadge.hidden = YES;
        self.viewNotLiveBadge.hidden = NO;
        self.lblWhen.text = item.video.friendlyDateString;
    }

    if (item.friend) {
        [self setupForFriend:item.friend];
    } else if (item.video.creator) {
        [self setupForFriend:item.video.creator];
    } else if (item.friendId) {
        __weak NSString *weakUserId = item.friendId;
        __weak ORHomeCell_Live *weakSelf = self;
        
        [ApiEngine friendWithId:item.friendId completion:^(NSError *error, OREpicFriend *user) {
            if (![weakSelf.item.friendId isEqualToString:weakUserId]) return;
            
            if (user) {
                weakSelf.item.friend = user;
                [weakSelf setupForFriend:user];
            }
        }];
    }
    
    if (item.video.thumbnailURL && ![item.video.thumbnailURL isEqualToString:@""]) {
        NSString *local = nil;
        
        if ([item.video.userId isEqualToString:CurrentUser.userId]) {
            NSString *file = [NSString stringWithFormat:VIDEO_THUMBNAIL_FORMAT, item.video.thumbnailIndex];
            local = [[ORUtility documentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", item.video.videoId, file]];
        }
        
        if (local && [[NSFileManager defaultManager] fileExistsAtPath:local]) {
            UIImage *thumb = [UIImage imageWithContentsOfFile:local];
            self.imgThumbnail.image = thumb;
        } else {
            NSURL *url = [NSURL URLWithString:item.video.thumbnailURL];
            __weak OREpicFeedItem *weakItem = item;
            __weak ORHomeCell_Live *weakSelf = self;
            
            self.imgThumbnail.image = nil;
            [self.aiLoading startAnimating];
            
            [[ORCachedEngine sharedInstance] imageAtURL:url size:self.imgThumbnail.frame.size fill:NO maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
                [weakSelf.aiLoading stopAnimating];
                if (error) {
                    NSLog(@"Error: %@", error);
                    self.imgThumbnail.image = [UIImage imageNamed:@"video"]; // put default in place
                } else {
                    if (image && weakSelf.item == weakItem) {
                        weakSelf.imgThumbnail.image = image;
                    }
                }
            }];
        }
    } else {
        self.imgThumbnail.image = [UIImage imageNamed:@"video"]; // put default in place
    }
}

- (void)setupForFriend:(OREpicFriend *)friend
{
    self.lblUserName.text = friend.name;
    
    if (friend.profileImageUrl) {
        NSURL *url = [NSURL URLWithString:friend.profileImageUrl];
        __weak OREpicFeedItem *weakItem = self.item;
        __weak ORHomeCell_Live *weakSelf = self;
        
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

@end
