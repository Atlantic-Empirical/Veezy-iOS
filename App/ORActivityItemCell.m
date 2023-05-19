//
//  ORNotificationCell.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 29/07/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORActivityItemCell.h"
#import "TTTAttributedLabel.h"
#import "ORUserProfileView.h"
#import "SORelativeDateTransformer.h"

@interface ORActivityItemCell() <TTTAttributedLabelDelegate>

@end

@implementation ORActivityItemCell

+ (CGFloat)heightForItem:(OREpicFeedItem *)item
{
    NSString *text = [NSString stringWithFormat:@"%@\n%@", [self textForItem:item], [self dateForItem:item]];
    CGFloat width = (item.video) ? 187.0f : 263.0f;
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CGSize sizeToFit = [text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f] constrainedToSize:CGSizeMake(width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    #pragma clang diagnostic pop
    
    return fmaxf(44.0f, ceilf(sizeToFit.height) + 10.0f);
}

+ (NSString *)textForItem:(OREpicFeedItem *)item
{
    switch (item.type) {
        case ORFeedItemTypeMyVideoWasReposted:
            return [NSString stringWithFormat:@"%@ reposted your video.", item.friend.firstName];
        case ORFeedItemTypeNewFollower:
            return [NSString stringWithFormat:@"%@ is now following you.", item.friend.firstName];
        case ORFeedItemTypeSomeoneLikedMyVideo:
            return [NSString stringWithFormat:@"%@ liked your video.", item.friend.firstName];
        case ORFeedItemTypeVideoWatched:
            return [NSString stringWithFormat:@"%@ watched your video.", item.friend.firstName];
        case ORFeedItemTypeFriendJoined:
            return [NSString stringWithFormat:@"%@ joined Veezy.", item.friend.firstName];
        case ORFeedItemTypeDirectVideo:
            return [NSString stringWithFormat:@"%@ sent you a video.", item.friend.firstName];
        case ORFeedItemTypeTaggedYou:
            return [NSString stringWithFormat:@"%@ tagged you in a video.", item.friend.firstName];
        case ORFeedItemTypeFollowRequest:
            return [NSString stringWithFormat:@"%@ requested to follow you.", item.friend.firstName];
        case ORFeedItemTypeVideoComment: {
            NSArray *strs = [item.text componentsSeparatedByString:@"\""];
            if (strs.count > 2) {
                return [NSString stringWithFormat:@"%@: %@", item.friend.firstName, [[strs subarrayWithRange:NSMakeRange(1, strs.count - 2)] componentsJoinedByString:@""]];
            } else if (strs.count == 2) {
                return [NSString stringWithFormat:@"%@: %@", item.friend.firstName, strs[1]];
            } else {
                return item.text;
            }
        }
        default:
            return item.text;
    }
}

+ (NSString *)dateForItem:(OREpicFeedItem *)item
{
    SORelativeDateTransformer *rdt = [[SORelativeDateTransformer alloc] init];
    return [rdt transformedValue:item.created];
}

- (void)dealloc
{
    self.lblText.delegate = nil;
}

- (void)awakeFromNib
{
    self.lblText.delegate = self;
    self.lblText.enabledTextCheckingTypes = NSTextCheckingTypeLink;
}

- (void)setItem:(OREpicFeedItem *)item
{
    _item = item;
    
    NSString *text = [ORActivityItemCell textForItem:item];
    NSString *date = [ORActivityItemCell dateForItem:item];
    NSRange dateRange = NSMakeRange(text.length + 1, date.length);
    
    [self.lblText setText:[NSString stringWithFormat:@"%@\n%@", text, date] afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        UIFont *dateFont = [self.lblText.font fontWithSize:self.lblText.font.pointSize - 2.0f];
        [mutableAttributedString addAttribute:NSFontAttributeName value:dateFont range:dateRange];
        [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:dateRange];
        
        return mutableAttributedString;
    }];
    
    NSDictionary *attributes = @{NSFontAttributeName: self.lblText.font, NSForegroundColorAttributeName: APP_COLOR_SECONDARY, NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone)};
    self.lblText.linkAttributes = attributes;
    
    
    
    switch (item.type) {
        case ORFeedItemTypeMyVideoWasReposted:
        case ORFeedItemTypeNewFollower:
        case ORFeedItemTypeSomeoneLikedMyVideo:
        case ORFeedItemTypeVideoWatched:
        case ORFeedItemTypeVideoComment:
        case ORFeedItemTypeFriendJoined:
        case ORFeedItemTypeDirectVideo:
        case ORFeedItemTypeTaggedYou:
        case ORFeedItemTypeFollowRequest: {
            NSURL *url = [NSURL URLWithString:@"user://load"];
            [self.lblText addLinkToURL:url withRange:NSMakeRange(0, item.friend.firstName.length)];
            break;
        }
        default:
            break;
    }
    
    CGRect f = self.lblText.frame;
    CGFloat width = (item.video) ? 187.0f : 263.0f;
    CGSize s = [self.lblText sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    f.size = s;
    self.lblText.frame = f;
    
    self.imgAvatar.image = [UIImage imageNamed:@"profile"];
    
    if (item.friend.profileImageUrl) {
        NSURL *url = [NSURL URLWithString:item.friend.profileImageUrl];
        __weak ORActivityItemCell *weakSelf = self;
        __weak OREpicFriend *weakFriend = item.friend;
        
        [[ORCachedEngine sharedInstance] imageAtURL:url size:((UIImageView*)self.imgAvatar).frame.size fill:YES maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
            if (error) {
                NSLog(@"Error: %@", error);
                
            } else if (image && [weakSelf.item.friend isEqual:weakFriend]) {
                weakSelf.imgAvatar.image = image;
            }
        }];
    }
    
    if (item.video) {
        self.imgThumbnail.image = nil;
        self.imgThumbnail.hidden = NO;
        
        if (item.video.thumbnailURL && ![item.video.thumbnailURL isEqualToString:@""]) {
            NSString *local = nil;
            
            if ([item.video.userId isEqualToString:CurrentUser.userId]) {
                NSString *file = [NSString stringWithFormat:VIDEO_THUMBNAIL_FORMAT, item.video.thumbnailIndex];
                local = [[ORUtility documentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", item.video.videoId, file]];
            }
            
            if (local && [[NSFileManager defaultManager] fileExistsAtPath:local]) {
                UIImage *thumb = [UIImage imageWithContentsOfFile:local];
                [self.imgThumbnail setImage:thumb];
            } else {
                NSURL *url = [NSURL URLWithString:item.video.thumbnailURL];
                __weak ORActivityItemCell *weakSelf = self;
                __weak OREpicVideo *weakVideo = item.video;
                
                [self.imgThumbnail setImage:nil];
                
                [[ORCachedEngine sharedInstance] imageAtURL:url size:((UIImageView *)self.imgThumbnail).frame.size fill:NO maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
                    if (error) {
                        NSLog(@"Error: %@", error);
                        
                        if ([weakSelf.item.video isEqual:weakVideo]) {
                            [weakSelf.imgThumbnail setImage:[UIImage imageNamed:@"video"]]; // put default in place
                        }
                    } else if (image && [weakSelf.item.video isEqual:weakVideo]) {
                        [weakSelf.imgThumbnail setImage:image];
                    }
                }];
            }
        } else {
            [self.imgThumbnail setImage:[UIImage imageNamed:@"video"]]; // put default in place
        }
    } else {
        self.imgThumbnail.hidden = YES;
    }
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if ([url.scheme isEqualToString:@"user"]) {
        [self btnAvatar_TouchUpInside:nil];
    }
}

- (void)btnAvatar_TouchUpInside:(id)sender
{
    ORUserProfileView *profile = [[ORUserProfileView alloc] initWithFriend:self.item.friend];
    [self.parent.navigationController pushViewController:profile animated:YES];
}

@end
