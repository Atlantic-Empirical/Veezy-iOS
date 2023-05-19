//
//  ORViewsCell.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 6/30/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORViewsCell.h"
#import "TTTAttributedLabel.h"
#import "ORUserProfileView.h"
#import "ORUserListView.h"

@interface ORViewsCell() <TTTAttributedLabelDelegate>

@property (nonatomic, strong) NSMutableOrderedSet *viewers;
@property (nonatomic, assign) BOOL loaded;

@end

@implementation ORViewsCell

- (void)dealloc
{
    self.lblNames.delegate = nil;
}

- (void)awakeFromNib
{
	self.aiLoading.color = APP_COLOR_PRIMARY;
    
    self.lblNames.delegate = self;
    self.lblNames.enabledTextCheckingTypes = NSTextCheckingTypeLink;
}

- (void)setVideo:(OREpicVideo *)video
{
    if (![video isEqual:_video]) self.viewers = nil;

	_video = video;
	[self update];

}

- (void)setViewers:(NSMutableOrderedSet *)viewers
{
    _viewers = viewers;
    
    if (viewers.count == 0 && !self.video.viewed) {
        if (self.video.uniqueViewCount == 1) {
            self.lblNames.text = [NSString stringWithFormat:@"%d person", self.video.uniqueViewCount];
        } else {
            self.lblNames.text = [NSString stringWithFormat:@"%d people", self.video.uniqueViewCount];
        }

        return;
    }

    OREpicFriend *f = [CurrentUser asFriend];
    if ([viewers containsObject:f]) {
        self.video.viewed = YES;
        [viewers removeObject:f];
    }
    
    if (self.video.viewed) [viewers insertObject:f atIndex:0];
    
    NSMutableArray *nameArray = [NSMutableArray arrayWithCapacity:viewers.count];
    
    for (OREpicFriend *f in viewers) {
        if ([f.userId isEqualToString:CurrentUser.userId]) {
            [nameArray addObject:@"You"];
        } else {
            [nameArray addObject:f.firstName];
        }
    }
    
    while (nameArray.count > 0) {
        NSString *names = [nameArray componentsJoinedByString:@", "];
        NSDictionary *attributes = @{NSFontAttributeName: self.lblNames.font, NSForegroundColorAttributeName: [UIColor darkGrayColor], NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone)};
        self.lblNames.linkAttributes = attributes;
        
        NSUInteger difference = (self.video.uniqueViewCount > nameArray.count) ? self.video.uniqueViewCount - nameArray.count : 0;
		
        if (difference > 1) {
            names = [names stringByAppendingFormat:@" and %d others", difference];
        } else if (difference == 1) {
            names = [names stringByAppendingFormat:@" and %d other", 1];
        }
        
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CGSize sizeToFit = [names sizeWithFont:self.lblNames.font constrainedToSize:CGSizeMake(self.lblNames.frame.size.width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
        #pragma clang diagnostic pop
        
        if (sizeToFit.height > self.lblNames.frame.size.height) {
            [nameArray removeLastObject];
        } else {
            self.lblNames.text = names;
            NSUInteger pos = 0, idx = 0;
            
            for (NSString *name in nameArray) {
                OREpicFriend *f = viewers[idx];
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"user://%@", f.userId]];
                
                [self.lblNames addLinkToURL:url withRange:NSMakeRange(pos, name.length)];
                pos += name.length + 2;
                idx++;
            }
            
            return;
        }
    }
    
    if (self.video.uniqueViewCount == 1) {
        self.lblNames.text = [NSString stringWithFormat:@"%d person", self.video.uniqueViewCount];
    } else {
        self.lblNames.text = [NSString stringWithFormat:@"%d people", self.video.uniqueViewCount];
    }
}

- (void)update
{
    if (self.loaded) {
        self.viewers = self.viewers;
        return;
    }
    
    if (self.video.uniqueViewCount == 1) {
        self.lblNames.text = [NSString stringWithFormat:@"%d person", self.video.uniqueViewCount];
    } else {
        self.lblNames.text = [NSString stringWithFormat:@"%d people", self.video.uniqueViewCount];
    }

    [self.aiLoading startAnimating];
    
    __weak ORViewsCell *weakSelf = self;
    
    [ApiEngine viewersForVideo:self.video.videoId completion:^(NSError *error, NSArray *result) {
        if (error) NSLog(@"Error: %@", error);
        
		weakSelf.viewers = [NSMutableOrderedSet orderedSetWithArray:result];
        weakSelf.loaded = YES;
        [weakSelf.aiLoading stopAnimating];
    }];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if ([url.scheme isEqualToString:@"user"]) {
        for (OREpicFriend *f in self.viewers) {
            if ([f.userId isEqualToString:url.host]) {
                ORUserProfileView *profile = [[ORUserProfileView alloc] initWithFriend:f];
                [self.parent.navigationController pushViewController:profile animated:YES];
                break;
            }
        }
    } else if ([url.scheme isEqualToString:@"allusers"]) {
        ORUserListView *vc = [[ORUserListView alloc] initWithUsers:[self.viewers array]];
        vc.title = @"Viewers";
        [self.parent.navigationController pushViewController:vc animated:YES];
    }
}

@end
