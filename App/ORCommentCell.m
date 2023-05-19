//
//  ORCommentCell.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 15/01/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORCommentCell.h"
#import "ORUserProfileView.h"
#import "SORelativeDateTransformer.h"
#import "TTTAttributedLabel.h"
#import "ORRangeString.h"
#import "ORHashtagView.h"

@interface ORCommentCell () <TTTAttributedLabelDelegate>

@end

@implementation ORCommentCell

+ (CGFloat)heightForCellWithComment:(OREpicVideoComment *)comment
{
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CGSize sizeToFit = [comment.comment sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:15.0f] constrainedToSize:CGSizeMake(254.0f, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    #pragma clang diagnostic pop
    
    return fmaxf(54.0f, ceilf(sizeToFit.height) + 38.0f);
}

- (void)dealloc
{
    self.lblComment.delegate = nil;
}

- (void)awakeFromNib
{
    self.lblComment.delegate = self;
    self.lblComment.enabledTextCheckingTypes = NSTextCheckingTypeLink;
}

- (void)setComment:(OREpicVideoComment *)comment
{
    _comment = comment;
    
    self.lblName.text = comment.user.firstName;
    [self setCommentText:comment];
    
    SORelativeDateTransformer *rdt = [[SORelativeDateTransformer alloc] init];
    self.lblDate.text = [rdt transformedValue:comment.created];
    
    self.imgProfile.image = [UIImage imageNamed:@"profile"];

    if (comment.user.profileImageUrl) {
        __weak OREpicFriend *weakUser = comment.user;
        __weak ORCommentCell *weakCell = self;
        
        NSURL *url = [NSURL URLWithString:comment.user.profileImageUrl];
        [[ORCachedEngine sharedInstance] imageAtURL:url size:self.imgProfile.frame.size fill:YES maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
            if (error) NSLog(@"Error: %@", error);
            
            if (image && weakUser == weakCell.comment.user) {
                self.imgProfile.image = image;
            }
        }];
    }
}

- (void)setCommentText:(OREpicVideoComment *)comment
{
    if (ORIsEmpty(comment.comment)) {
        self.lblComment.text = nil;
        return;
    }
    
    NSDictionary *attributes = @{NSFontAttributeName: self.lblComment.font, NSForegroundColorAttributeName: APP_COLOR_LIGHT_PURPLE, NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone)};
    self.lblComment.linkAttributes = attributes;
    self.lblComment.text = comment.comment;
    
    [comment parseHashtagsForce:NO];
    
    for (ORRangeString *tag in comment.parsedHashtags) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tag://%@", [tag.string stringByReplacingOccurrencesOfString:@"#" withString:@""]]];
        [self.lblComment addLinkToURL:url withRange:tag.range];
    }
    
    for (ORRangeString *tag in comment.taggedUsers) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"user://%@", tag.string]];
        [self.lblComment addLinkToURL:url withRange:tag.range];
    }
}

- (void)showUserProfile:(id)sender
{
	ORUserProfileView *profile = [[ORUserProfileView alloc] initWithFriend:self.comment.user];
	[self.parent.navigationController pushViewController:profile animated:YES];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imgProfile.layer.cornerRadius = self.imgProfile.frame.size.width / 2;
    
    CGSize size = [self.lblComment sizeThatFits:CGSizeMake(self.lblComment.frame.size.width, CGFLOAT_MAX)];
    CGRect f = self.lblComment.frame;
    f.size.height = size.height;
    self.lblComment.frame = f;
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if ([url.scheme isEqualToString:@"user"]) {
        for (OREpicFriend *f in CurrentUser.relatedUsers) {
            if ([f.userId isEqualToString:url.host]) {
                ORUserProfileView *profile = [[ORUserProfileView alloc] initWithFriend:f];
                [self.parent.navigationController pushViewController:profile animated:YES];
                return;
            }
        }
        
        __weak ORCommentCell *weakSelf = self;
        [ApiEngine friendWithId:url.host completion:^(NSError *error, OREpicFriend *epicFriend) {
            if (weakSelf.parent && epicFriend) {
                ORUserProfileView *profile = [[ORUserProfileView alloc] initWithFriend:epicFriend];
                [weakSelf.parent.navigationController pushViewController:profile animated:YES];
            }
        }];
    } else if ([url.scheme isEqualToString:@"tag"]) {
        ORHashtagView *vc = [[ORHashtagView alloc] initWithHashtag:url.host];
        [self.parent.navigationController pushViewController:vc animated:YES];
    }
}

@end
