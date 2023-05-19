//
//  ORHomeCell_FeedSummary.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 3/24/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORHomeCell_FeedFriendFaces.h"
#import "ORUserProfileViewParent.h"

@implementation ORHomeCell_FeedFriendFaces

- (void)setItems:(NSOrderedSet *)items
{
    if (items == _items) return;
    _items = items;
    
    for (UIView *view in self.contentView.subviews) {
        if (view != self.lineView) [view removeFromSuperview];
    }
    
    NSUInteger cells = MIN(items.count, floorf(312.0f / 60.0f));
    CGFloat startLeft = floorf((312.0f / 2.0f) - (60.0f * cells / 2.0f)) + 4.0f;
    
    for (int i = 0; i < cells; i++) {
        OREpicFriend *friend = items[i];
        [self setupForFriend:friend startAt:startLeft index:i count:friend.videoCountForBadge];
        
        startLeft += 60.0f;
    }
}

- (void)setupForFriend:(OREpicFriend *)friend startAt:(CGFloat)startAt index:(NSUInteger)index count:(NSUInteger)count
{
    UIButton *img = [UIButton buttonWithType:UIButtonTypeCustom];
    img.frame = CGRectMake(startAt + 5.0f, 5.0f, 50.0f, 50.0f);
    img.adjustsImageWhenHighlighted = NO;
    img.contentMode = UIViewContentModeScaleAspectFill;
    img.clipsToBounds = YES;
    img.layer.cornerRadius = 25.0f;
    img.tag = index;
    [img addTarget:self action:@selector(imgTapped:) forControlEvents:UIControlEventTouchUpInside];
    [img setBackgroundImage:[UIImage imageNamed:@"profile"] forState:UIControlStateNormal];
    [self.contentView addSubview:img];
    
	// Number badge
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(startAt + 40.0f, 2.0f, 20.0f, 14.0f)];
    lbl.textColor = [UIColor whiteColor];
    lbl.backgroundColor = APP_COLOR_PRIMARY;
    lbl.alpha = 0.85f;
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.font = [UIFont systemFontOfSize:12.0f];
    lbl.minimumScaleFactor = 0.5;
    lbl.clipsToBounds = YES;
    lbl.layer.cornerRadius = 7.0f;
    lbl.text = [NSString stringWithFormat:@"%d", count];
    [self.contentView addSubview:lbl];

	// Name badge
    UILabel *lblName = [[UILabel alloc] initWithFrame:CGRectMake(startAt + 6.0f, 43.0f, 48.0f, 12.0f)];
    lblName.textColor = [UIColor whiteColor];
    lblName.backgroundColor = APP_COLOR_PRIMARY;
    lblName.alpha = 0.85f;
    lblName.textAlignment = NSTextAlignmentCenter;
//    lblName.font = [UIFont  systemFontOfSize:12.0f];
	lblName.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:10.0f];
    lblName.minimumScaleFactor = 0.5;
    lblName.clipsToBounds = YES;
    lblName.layer.cornerRadius = 3.0f;
    lblName.text = friend.firstName;
    [self.contentView addSubview:lblName];

    if (friend.profileImageUrl) {
        NSURL *url = [NSURL URLWithString:friend.profileImageUrl];
        __weak UIButton *weakImg = img;
        
        [[ORCachedEngine sharedInstance] imageAtURL:url size:img.frame.size fill:YES maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
            if (error) {
                NSLog(@"Error: %@", error);
            } else {
                if (image) {
                    [weakImg setBackgroundImage:image forState:UIControlStateNormal];
                }
            }
        }];
    }
}

- (void)imgTapped:(UIButton *)sender
{
    if (sender.tag < self.items.count) {
        OREpicFriend *friend = self.items[sender.tag];
        ORUserProfileViewParent *vc = [[ORUserProfileViewParent alloc] initWithFriend:friend];
        [self.parent.navigationController pushViewController:vc animated:YES];
    }
}

@end
