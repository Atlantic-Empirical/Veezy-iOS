//
//  ORVideoItemCell.m
//  Epic
//
//  Created by Thomas Purnell-Fisher on 10/29/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORVideoItemCell.h"
#import "ORVideoManagerView.h"
#import <QuartzCore/QuartzCore.h>
#import "ORFaspPersistentEngine.h"


@interface ORVideoItemCell () <UIAlertViewDelegate>


@end

@implementation ORVideoItemCell


- (void)setVideo:(OREpicVideo *)video
{
    self.modified = ![_video isEqual:video];
    if (video.thumbnailIndex != self.thumbnailIndex) self.modified = YES;
    
    _video = video;

    self.lblTitle.text = video.autoTitle;
    self.lblDate.hidden = NO;
    self.lblDate.text = video.friendlyDateString;
	
	// THUMBNAIL
    if (self.modified) {
        self.thumbnailIndex = self.video.thumbnailIndex;
        
        if (self.video.thumbnailURL && ![self.video.thumbnailURL isEqualToString:@""]) {
            NSString *local = nil;
            
            if ([self.video.userId isEqualToString:CurrentUser.userId]) {
                NSString *file = [NSString stringWithFormat:VIDEO_THUMBNAIL_FORMAT, self.video.thumbnailIndex];
                local = [[ORUtility documentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", self.video.videoId, file]];
            }
            
            if (local && [[NSFileManager defaultManager] fileExistsAtPath:local]) {
                UIImage *thumb = [UIImage imageWithContentsOfFile:local];
                self.imgThumbnail.image = thumb;
            } else {
                NSURL *url = [NSURL URLWithString:self.video.thumbnailURL];
                __weak OREpicVideo *weakVideo = self.video;
                __weak ORVideoItemCell *weakSelf = self;
                [[ORCachedEngine sharedInstance] imageAtURL:url size:self.imgThumbnail.frame.size fill:NO maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
                    if (weakSelf.video != weakVideo) return;
                    if (error) NSLog(@"Error: %@", error);
                    
                    if (image) {
                        weakSelf.imgThumbnail.image = image;
                    } else {
                        weakSelf.imgThumbnail.image = [UIImage imageNamed:@"video"];
                    }
                }];
            }
        } else {
            self.imgThumbnail.image = [UIImage imageNamed:@"video"];
        }
    }
    
    
	
	// special treatment for expiring videos
//	DLog(@"%@ time til expiration: %f", _video.locationFriendlyName, _video.secondsToExpiration);
//	int secondsPerDay = 60*60*24;
//	if ([_video.userId isEqualToString:CurrentUser.userId] && _video.secondsToExpiration < (secondsPerDay*5) && _video.secondsToExpiration > 0)
//	{
//		float alpha = _video.secondsToExpiration / (secondsPerDay*5);
//		self.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:alpha];
//		self.btnExpiringInfo.hidden = NO;
//	} else {
//        self.backgroundColor = [UIColor clearColor];
//		self.btnExpiringInfo.hidden = YES;
//	}
	
	// Duration Label - a bit tricky
	self.lblDuration.text = self.video.friendlyDurationString;
	CGSize maximumLabelSize = CGSizeMake(310, 9999);
	CGRect textRect = [self.lblDuration.text boundingRectWithSize:maximumLabelSize
														  options:NSStringDrawingUsesLineFragmentOrigin
													   attributes:@{NSFontAttributeName:self.lblDuration.font}
														  context:nil];
	CGRect f = self.viewDurationParent.frame;
	f.size = textRect.size;
	f.size.width += 10;
	f.size.height = 14;
	f.origin.x = self.frame.size.width - f.size.width - 10;
	self.viewDurationParent.frame = f;

	// Counts
	self.lblComments.text = [NSString stringWithFormat:@"%d", self.video.commentCount];
	self.lblLikes.text = [NSString stringWithFormat:@"%d", self.video.likeCount];
	self.lblViews.text = [NSString stringWithFormat:@"%d", self.video.viewCount];

	[self configureLayout];
}

- (void)configureLayout
{
	CGRect f = self.imgThumbnail.frame;
	f.origin.x = 6;
	if (self.frame.size.width == [[UIScreen mainScreen] bounds].size.width) {
		f.origin.y = 16;
	} else {
		f.origin.y = 21;
	}
	
	CGRect f1 = self.viewDate.frame;
	f1.size.width = f.size.width;
	self.viewDate.frame = f1;
	
	[self layoutIfNeeded];
}

#pragma mark - UI










@end
