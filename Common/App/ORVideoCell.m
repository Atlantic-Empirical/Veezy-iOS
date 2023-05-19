//
//  ORHomeCell_Recent.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 3/24/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORVideoCell.h"
#import "ORWatchView.h"
#import <QuartzCore/QuartzCore.h>
#import "ORUserProfileView.h"
#import "ORFaspPersistentEngine.h"
#import "TTTAttributedLabel.h"
#import "ORRangeString.h"
#import "ORHashtagView.h"

@interface ORVideoCell () <TTTAttributedLabelDelegate>

@property (nonatomic, assign) BOOL modified;
@property (nonatomic, strong) OREpicFriend *friend;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, assign) NSUInteger thumbnailIndex;

@end

@implementation ORVideoCell

- (CGFloat)heightForCellWithVideo:(OREpicVideo *)video
{
	float affordanceForViewsAndLikes = (video.viewCount > 0) ? self.viewViewsAndLikes.frame.size.height : 0;
	float result = 0;
	
    if (ORIsEmpty(video.name)) {
        result = CGRectGetMinY(self.txtTitle.frame) + 28.0f + affordanceForViewsAndLikes;
    } else {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CGFloat lineHeight = [video.name sizeWithFont:self.txtTitle.font].height;
        CGSize sizeToFit = [video.name sizeWithFont:self.txtTitle.font constrainedToSize:CGSizeMake(self.txtTitle.frame.size.width, ceilf(lineHeight * self.txtTitle.numberOfLines)) lineBreakMode:NSLineBreakByWordWrapping];
        #pragma clang diagnostic pop
        result = CGRectGetMinY(self.txtTitle.frame) + ceilf(sizeToFit.height) + 28.0f + affordanceForViewsAndLikes;
    }
	
	return result;
}

- (void)awakeFromNib
{
	self.viewForBorder.layer.borderColor = APP_COLOR_DARK_GREY.CGColor;
	self.viewForBorder.layer.borderWidth = 1.0f;
	self.imgAvatar.layer.cornerRadius = self.imgAvatar.frame.size.width / 2;
	self.imgThumbnail.layer.borderColor = [UIColor blackColor].CGColor;
	self.imgThumbnail.layer.borderWidth = 1.0f;
    self.txtTitle.delegate = self;
    self.txtTitle.enabledTextCheckingTypes = NSTextCheckingTypeLink;
	self.viewTimebomb.layer.cornerRadius = 5.0f;
	self.imgPublic.layer.cornerRadius = 2.0f;
	self.imgBadge1.layer.cornerRadius = 2.0f;
	self.imgDirect.layer.cornerRadius = 2.0f;
}

- (void)dealloc
{
    self.txtTitle.delegate = nil;
    self.alertView.delegate = nil;
}

- (void)setItem:(OREpicFeedItem *)item
{
	_item = item;
    [self setupForItem:item];
}

- (void)setVideo:(OREpicVideo *)video
{
	_video = video;
    
    self.lblReposter.hidden = YES;
    self.imgRepost.hidden = YES;
	   
	self.aiLoading.color = APP_COLOR_PRIMARY;
	self.aiUploading.color = APP_COLOR_PRIMARY;
	
	// THUMBNAIL
	
    if (self.video.thumbnailURL && ![self.video.thumbnailURL isEqualToString:@""]) {
        NSString *local = nil;
        
        if ([self.video.userId isEqualToString:CurrentUser.userId]) {
            NSString *file = [NSString stringWithFormat:VIDEO_THUMBNAIL_FORMAT, self.video.thumbnailIndex];
            local = [[ORUtility documentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", self.video.videoId, file]];
        }
        
        if (local && [[NSFileManager defaultManager] fileExistsAtPath:local]) {
            UIImage *thumb = [UIImage imageWithContentsOfFile:local];
            [self.imgThumbnail setImage:thumb];
        } else {
            NSURL *url = [NSURL URLWithString:self.video.thumbnailURL];
            __weak ORVideoCell *weakSelf = self;
            __weak OREpicVideo *weakVideo = self.video;
            
            [self.imgThumbnail setImage:nil];
            [self.aiLoading startAnimating];
            
            [[ORCachedEngine sharedInstance] imageAtURL:url size:((UIImageView *)self.imgThumbnail).frame.size fill:NO maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
                [weakSelf.aiLoading stopAnimating];
                
                if (error) {
                    NSLog(@"Error: %@", error);
                    
                    if ([weakSelf.video isEqual:weakVideo]) {
                        [weakSelf.imgThumbnail setImage:[UIImage imageNamed:@"video"]]; // put default in place
                    }
                } else if (image && [weakSelf.video isEqual:weakVideo]) {
                    [weakSelf.imgThumbnail setImage:image];
                }
            }];
        }
    } else {
        [self.imgThumbnail setImage:[UIImage imageNamed:@"video"]]; // put default in place
    }

	
	// DURATION
	
	self.lblDuration.text = self.video.friendlyDurationString;
	CGSize maximumLabelSize = CGSizeMake(310, 9999);
	CGRect textRect = [self.lblDuration.text boundingRectWithSize:maximumLabelSize
														  options:NSStringDrawingUsesLineFragmentOrigin
													   attributes:@{NSFontAttributeName:self.lblDuration.font}
														  context:nil];

	CGRect f = self.viewDurationParent.frame;
	f.size.width = textRect.size.width + 16;
	f.origin.x = self.viewDurationParent.superview.frame.size.width - f.size.width - 8;
	self.viewDurationParent.frame = f;
	self.viewDurationParent.layer.cornerRadius = 5.0f;

	
	// WHEN
	
	self.lblDate.text = self.video.friendlyDateString;
	
	
	// LOCATION
	
	if (self.video.locationFriendlyName // there's a location name
		&& ![self.video.locationFriendlyName isEqualToString:@"Unknown"] // the location is real
		&& ([self.video.name rangeOfString:self.video.locationFriendlyName].location == NSNotFound)) // the video title doesn't contain the exact location name (this was getting pretty redundant)
	{
		
		self.lblLocation.text = self.video.locationFriendlyName;
		
		CGSize maximumLabelSize = CGSizeMake(310, 9999);
		CGRect textRect = [self.lblLocation.text boundingRectWithSize:maximumLabelSize
															  options:NSStringDrawingUsesLineFragmentOrigin
														   attributes:@{NSFontAttributeName:self.lblLocation.font}
															  context:nil];

		CGRect f = self.viewLocationHost.frame;
		f.origin.x = MAX(self.viewLocationHost.superview.frame.size.width - ceilf(textRect.size.width) - 8 - self.lblLocation.frame.origin.x - 8, 6);
		f.size.width = MIN(textRect.size.width + self.lblLocation.frame.origin.x + 8, 290);
		self.viewLocationHost.frame = f;
		
		f = self.lblLocation.frame;
//		f.size.width = ceilf(textRect.size.width);
		f.size.width = self.lblLocation.superview.frame.size.width - f.origin.x - 3;
		self.lblLocation.frame = f;

		self.viewLocationHost.layer.cornerRadius = 5.0f;
		
		self.viewLocationHost.hidden = NO;
	} else {
		self.viewLocationHost.hidden = YES;
	}
	
	
	// TITLE
	
    [self setVideoTitle:self.video];

	
	// LIKES & VIEWS

	self.imgHeart.hidden = YES;
	self.lblLikesCount.hidden = YES;

	if (self.video.viewCount > 0) {
		self.viewViewsAndLikes.hidden = NO;
		self.lblViewsCount.text = self.video.viewCountString;
	} else {
		self.viewViewsAndLikes.hidden = YES;
	}
	
	if (self.video.likeCount > 0) {
		self.imgHeart.hidden = NO;
		self.lblLikesCount.hidden = NO;
		self.lblLikesCount.text = self.video.likeCountString;
	}

	
	// OTHER
	
    self.imgPublic.image = nil;
	self.imgPublic.hidden = YES;
	self.viewTimebomb.hidden = YES;
	self.imgBadge1.hidden = YES;
	self.imgDirect.hidden = YES;
    self.viewContent.alpha = 1.0f;
    self.btnPlay.hidden = NO;

	// BADGES & EDIT BUTTON
	if ([self.video.userId isEqualToString:CurrentUser.userId]) {

        // Private
		if (self.video.privacy != OREpicVideoPrivacyPublic && !self.video.authorizedNames) {
			self.imgPublic.image = [UIImage imageNamed:@"lock-icon-wire-white-glow-30x"];
		} else if (self.video.authorizedNames.count > 0) {

			if (self.video.privacy == OREpicVideoPrivacyPublic) {
                self.imgPublic.image = [UIImage imageNamed:@"public-icon-wire-white-glow-30x"];
				self.imgPublic.hidden = NO;
			}
			
			self.imgDirect.image = [UIImage imageNamed:@"direct-circle-icon-wire-white-30x"];
			self.imgDirect.hidden = NO;
			
		} else {
            self.imgPublic.image = [UIImage imageNamed:@"public-icon-wire-white-glow-30x"];
			self.imgPublic.hidden = NO;
        }
		
        // Timebomb
        if (self.video.state == OREpicVideoStateExpired) {
            self.viewTimebomb.hidden = NO;
            self.lblTimebomb.text = @"Expired";
            self.viewContent.alpha = 0.5f;
            self.btnPlay.hidden = YES;

            CGSize maximumLabelSize = CGSizeMake(310, 9999);
            CGRect textRect = [self.lblTimebomb.text boundingRectWithSize:maximumLabelSize
                                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                                               attributes:@{NSFontAttributeName:self.lblTimebomb.font}
                                                                  context:nil];
            
            CGRect f = self.viewTimebomb.frame;
            f.origin.x = MAX(self.viewTimebomb.superview.frame.size.width - ceilf(textRect.size.width) - 8 - self.lblTimebomb.frame.origin.x - 14, 6);
            f.size.width = MIN(textRect.size.width + self.lblTimebomb.frame.origin.x + 14, 290);
            self.viewTimebomb.frame = f;
        } else if (self.video.timebombMinutes > 0) {
			self.viewTimebomb.hidden = NO;
			self.lblTimebomb.text = self.video.friendlyTimebombString;
			
			CGSize maximumLabelSize = CGSizeMake(310, 9999);
			CGRect textRect = [self.lblTimebomb.text boundingRectWithSize:maximumLabelSize
																  options:NSStringDrawingUsesLineFragmentOrigin
															   attributes:@{NSFontAttributeName:self.lblTimebomb.font}
																  context:nil];
			
			CGRect f = self.viewTimebomb.frame;
			f.origin.x = MAX(self.viewTimebomb.superview.frame.size.width - ceilf(textRect.size.width) - 8 - self.lblTimebomb.frame.origin.x - 14, 6);
			f.size.width = MIN(textRect.size.width + self.lblTimebomb.frame.origin.x + 14, 290);
			self.viewTimebomb.frame = f;
        }
		
		switch (self.video.state) {
			case OREpicVideoStateUploaded:
            case OREpicVideoStateExpired:
				self.imgBadge1.image = nil;
				break;
				
			case OREpicVideoStateUploading:
				self.imgBadge1.image = [UIImage imageNamed:@"uploading-icon-wire-white-glow-20x"];
				self.imgBadge1.hidden = NO;
				[self.aiUploading startAnimating];
				break;
				
			case OREpicVideoStateNotUploaded:
            case OREpicVideoStateDeleted:
				DLog(@"OREpicVideoStateNotUploaded");
				self.imgBadge1.image = [UIImage imageNamed:@"uploading-icon-wire-white-glow-20x"];
				self.imgBadge1.hidden = NO;
				break;
				
			case OREpicVideoStateUnknown:
				DLog(@"OREpicVideoStateUnknown");
				self.imgBadge1.image = [UIImage imageNamed:@"alert-icon-wire-white-glow-20x"];
				self.imgBadge1.hidden = NO;
				break;
				
			case OREpicVideoStateUploadFailed:
				DLog(@"OREpicVideoStateUploadFailed");
				self.imgBadge1.image = [UIImage imageNamed:@"alert-icon-wire-white-glow-20x"];
				self.imgBadge1.hidden = NO;
				break;
		}
	}
    
    if (!self.item) {
        if ([video.userId isEqualToString:CurrentUser.userId]) {
            self.friend = [CurrentUser asFriend];
            [self setupForFriend];
        } else if (video.user) {
            self.friend = video.user;
            [self setupForFriend];
        } else if (video.userId) {
            __weak OREpicVideo *weakVideo = video;
            __weak ORVideoCell *weakSelf = self;
            
            [ApiEngine friendWithId:video.userId completion:^(NSError *error, OREpicFriend *user) {
                if (![weakVideo.userId isEqualToString:user.userId]) return;
                
                if (user) {
                    weakVideo.user = user;
                    weakSelf.friend = user;
                    [weakSelf setupForFriend];
                }
            }];
        }
    }
}

- (void)setVideoTitle:(OREpicVideo *)video
{
    if (ORIsEmpty(self.video.name)) {
        self.txtTitle.text = nil;
        return;
    }
    
    NSDictionary *attributes = @{NSFontAttributeName: self.txtTitle.font, NSForegroundColorAttributeName: APP_COLOR_LIGHT_PURPLE, NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone)};
    self.txtTitle.linkAttributes = attributes;
    self.txtTitle.text = video.name;
    
    [video parseHashtagsForce:NO];
    
    for (ORRangeString *tag in video.parsedHashtags) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tag://%@", [tag.string stringByReplacingOccurrencesOfString:@"#" withString:@""]]];
        [self.txtTitle addLinkToURL:url withRange:tag.range];
    }
    
    for (ORRangeString *tag in video.taggedUsers) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"user://%@", tag.string]];
        [self.txtTitle addLinkToURL:url withRange:tag.range];
    }
}

- (void)setupForItem:(OREpicFeedItem *)item
{
    [self.aiLoading stopAnimating];

	self.modified = ![_video isEqual:self.video];
    if (self.video.thumbnailIndex != self.thumbnailIndex) self.modified = YES;

    [self.lblUserName setText:@"Loading..."];
    self.imgAvatar.image = [UIImage imageNamed:@"profile"];
    
    if ([item.video.userId isEqualToString:CurrentUser.userId]) {
        self.friend = [CurrentUser asFriend];
        [self setupForFriend];
    } else if (item.video.user) {
        self.friend = item.video.user;
        [self setupForFriend];
    } else if (item.video.userId && ![item.video.userId isEqualToString:item.friendId]) {
        __weak OREpicFeedItem *weakItem = item;
        __weak ORVideoCell *weakSelf = self;
        
        [ApiEngine friendWithId:item.video.userId completion:^(NSError *error, OREpicFriend *user) {
            if (![weakItem.video.userId isEqualToString:user.userId]) return;
            
            if (user) {
                weakItem.video.user = user;
                weakSelf.friend = user;
                [weakSelf setupForFriend];
            }
        }];
    } else if ([item.friendId isEqualToString:CurrentUser.userId]) {
        self.friend = [CurrentUser asFriend];
        [self setupForFriend];
    } else if (item.friend) {
        self.friend = item.friend;
        [self setupForFriend];
    } else if (item.friendId) {
        __weak OREpicFeedItem *weakItem = item;
        __weak ORVideoCell *weakSelf = self;
        
        [ApiEngine friendWithId:item.friendId completion:^(NSError *error, OREpicFriend *user) {
            if (![weakItem.friendId isEqualToString:user.userId]) return;
            
            if (user) {
                weakItem.friend = user;
                weakSelf.friend = user;
                [weakSelf setupForFriend];
            }
        }];
    }
    
    self.video = item.video;
    
    if (item.type == ORFeedItemTypeVideoRepost) {
        CGRect f = self.lblUserName.frame;
        f.origin.y = 20.0f;
        self.lblUserName.frame = f;
        self.lblReposter.hidden = NO;
        self.imgRepost.hidden = NO;
        
        if (item.friend) {
            self.lblReposter.text = item.friend.firstName;
        } else if (item.friendId) {
            __weak OREpicFeedItem *weakItem = item;
            __weak ORVideoCell *weakSelf = self;
            
            self.lblReposter.text = @"Loading...";
            
            [ApiEngine friendWithId:item.friendId completion:^(NSError *error, OREpicFriend *user) {
                if (![weakItem.friendId isEqualToString:user.userId]) return;
                
                if (user) {
                    weakItem.friend = user;
                    weakSelf.lblReposter.text = user.firstName;
                }
            }];
        } else {
            self.lblReposter.text = @"Unknown";
        }
    }
	
	OREpicFeedItem *lastComment = nil;
    
    for (OREpicFeedItem *i in item.itemActions) {
        switch (i.type) {
            case ORFeedItemTypeSomeoneLikedMyVideo:
                break;
            case ORFeedItemTypeVideoComment:
                if (!lastComment || [lastComment.created compare:i.created] == NSOrderedAscending) lastComment = i;
                break;
            case ORFeedItemTypeMyVideoWasReposted:
                break;
            default:
                break;
        }
    }
}

- (void)setupForFriend
{
    if (self.video && !self.video.user && [self.friend.userId isEqualToString:self.video.userId]) self.video.user = self.friend;
    if (self.item.video && !self.item.video.user && [self.friend.userId isEqualToString:self.item.video.userId]) self.item.video.user = self.friend;
    
    [self.lblUserName setText:self.friend.name];
    self.imgAvatar.image = [UIImage imageNamed:@"profile"];
	
	if (self.friend.profileImageUrl) {
        NSURL *url = [NSURL URLWithString:self.friend.profileImageUrl];
        __weak ORVideoCell *weakSelf = self;
        __weak OREpicFriend *weakFriend = self.friend;
        
        [[ORCachedEngine sharedInstance] imageAtURL:url size:((UIImageView*)self.imgAvatar).frame.size fill:YES maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
            if (error) {
                NSLog(@"Error: %@", error);
            } else if (image && [weakSelf.friend isEqual:weakFriend]) {
                weakSelf.imgAvatar.image = image;
            }
        }];
    }
}

//- (void)thumbSelector:(UIButton *)sender
//{
//	if (self.item.video) {
//		ORWatchView *vc = [[ORWatchView alloc] initWithVideo:self.item.video];
//		[self.parent.navigationController pushViewController:vc animated:YES];
//	} else if (self.item.videoId) {
//		ORWatchView *vc = [[ORWatchView alloc] initWithVideoId:self.item.videoId];
//		[self.parent.navigationController pushViewController:vc animated:YES];
//	}
//}

#pragma mark - UI

- (IBAction)btnAvatar_TouchUpInside:(id)sender
{
	ORUserProfileView *vc;
	
	if (self.item.friend) {
		vc = [[ORUserProfileView alloc] initWithFriend:self.item.friend];
	} else if (self.item.video.user) {
		vc = [[ORUserProfileView alloc] initWithFriend:self.item.video.user];
	} else if (self.video.user) {
		vc = [[ORUserProfileView alloc] initWithFriend:self.video.user];
	} else {
		DLog(@"WARNING: FIGURE THIS OUT - SHOULDN'T HAPPEN");
	}
	
	[self.parent.navigationController pushViewController:vc animated:YES];
}

- (IBAction)btnPlay_TouchUpInside:(id)sender
{
    OREpicVideo *video = (self.video) ?: self.item.video;
    ORWatchView *vc = [[ORWatchView alloc] initWithVideo:video];
    vc.shouldAutoplay = YES;
    
    [self.parent.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Custom

- (void)deleteVideo
{
    // Cancel the video upload, if pending
    [[ORFaspPersistentEngine sharedInstance] cancelVideoUpload:self.video];
	
    [ApiEngine deleteVideoWithId:self.video.videoId cb:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
        
        if (result) {
            CurrentUser.totalVideoCount--;
            [CurrentUser saveLocalUser];
            
            // Delete local files
            NSString *localPath = [[ORUtility documentsDirectory] stringByAppendingPathComponent:self.video.videoId];
			
            BOOL isDir = NO;
            BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:localPath isDirectory:&isDir];
            
            if (result && isDir) {
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:localPath error:&error];
                if (error) NSLog(@"Can't delete local video files: %@", error);
            }
        }
    }];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORVideoDeleted" object:self.video];
}

#pragma mark - Uploading Progress

- (void)updateUploadingProgress:(float)progress
{
	//
}

- (void)uploadFinished
{
    [self setVideo:self.video];
	[self.aiUploading stopAnimating];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    if (alertView.cancelButtonIndex == buttonIndex) return;
	
	switch (alertView.tag) {
		case 1: // Unused
			break;
        case 2:
            [self deleteVideo];
            break;
		default:
			break;
	}
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
        
        __weak ORVideoCell *weakSelf = self;
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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize size = [self.txtTitle sizeThatFits:CGSizeMake(self.txtTitle.frame.size.width, CGFLOAT_MAX)];
    CGRect f = self.txtTitle.frame;
    f.size.height = size.height;
    self.txtTitle.frame = f;
}

@end
