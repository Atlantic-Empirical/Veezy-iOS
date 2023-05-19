//
//  ORLikesCell.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 6/30/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORLikesCell.h"
#import "TTTAttributedLabel.h"
#import "ORUserProfileView.h"
#import "ORUserListView.h"

@interface ORLikesCell() <TTTAttributedLabelDelegate>

@property (nonatomic, strong) NSMutableOrderedSet *likers;
@property (nonatomic, assign) BOOL loaded;

@end

@implementation ORLikesCell

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
    if (![video isEqual:_video]) self.likers = nil;

	_video = video;
	[self update];

}

- (void)setLikers:(NSMutableOrderedSet *)likers
{
    _likers = likers;
    
    if (likers.count == 0 && !self.video.liked) {
        self.lblNames.text = nil;
        return;
    }
    
    OREpicFriend *f = [CurrentUser asFriend];
    if ([self.likers containsObject:f]) [self.likers removeObject:f];
    if (self.video.liked) [self.likers insertObject:f atIndex:0];
    
    NSMutableArray *nameArray = [NSMutableArray arrayWithCapacity:likers.count];
    
    for (OREpicFriend *f in likers) {
        if ([f.userId isEqualToString:CurrentUser.userId]) {
            [nameArray addObject:@"You"];
        } else {
            [nameArray addObject:f.firstName];
        }
    }
    
    NSString *names = [nameArray componentsJoinedByString:@", "];
    NSDictionary *attributes = @{NSFontAttributeName: self.lblNames.font, NSForegroundColorAttributeName: [UIColor darkGrayColor], NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone)};
    self.lblNames.linkAttributes = attributes;

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CGSize sizeToFit = [names sizeWithFont:self.lblNames.font constrainedToSize:CGSizeMake(self.lblNames.frame.size.width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    #pragma clang diagnostic pop
    
    if (sizeToFit.height > self.lblNames.frame.size.height) {
        NSString *name = [NSString stringWithFormat:@"%d favorite%@", self.likers.count, self.likers.count > 1 ? @"s" : @""];
        self.lblNames.text = name;
        NSURL *url = [NSURL URLWithString:@"allusers://show"];
        [self.lblNames addLinkToURL:url withRange:NSMakeRange(0, name.length)];
    } else {
        self.lblNames.text = names;
        NSUInteger pos = 0;
        
        for (OREpicFriend *f in self.likers) {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"user://%@", f.userId]];
            NSString *name = ([f.userId isEqualToString:CurrentUser.userId]) ? @"You" : f.firstName;
            
            [self.lblNames addLinkToURL:url withRange:NSMakeRange(pos, name.length)];
            pos += name.length + 2;
        }
    }
}

- (void)update
{
    if (self.loaded) {
        self.likers = self.likers;
        return;
    }
    
    self.lblNames.text = nil;
    [self.aiLoading startAnimating];
    
    __weak ORLikesCell *weakSelf = self;
    
    [ApiEngine likersForVideo:self.video.videoId completion:^(NSError *error, NSArray *result) {
        if (error) NSLog(@"Error: %@", error);
        
		weakSelf.likers = [NSMutableOrderedSet orderedSetWithArray:result];
        weakSelf.loaded = YES;
        [weakSelf.aiLoading stopAnimating];
    }];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if ([url.scheme isEqualToString:@"user"]) {
        for (OREpicFriend *f in self.likers) {
            if ([f.userId isEqualToString:url.host]) {
                ORUserProfileView *profile = [[ORUserProfileView alloc] initWithFriend:f];
                [self.parent.navigationController pushViewController:profile animated:YES];
                break;
            }
        }
    } else if ([url.scheme isEqualToString:@"allusers"]) {
        ORUserListView *vc = [[ORUserListView alloc] initWithUsers:[self.likers array]];
        vc.title = @"Likers";
        [self.parent.navigationController pushViewController:vc animated:YES];
    }
}

@end
