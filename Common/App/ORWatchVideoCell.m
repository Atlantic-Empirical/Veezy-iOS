//
//  ORHomeCell_Recent.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 3/24/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "ORWatchVideoCell.h"
#import "ORWatchView.h"
#import <QuartzCore/QuartzCore.h>
#import "ORUserProfileView.h"
#import "ORFaspPersistentEngine.h"
#import "ORMoviePlayerView.h"
#import "ORWatchView.h"
#import "ORMapView.h"
#import "ORPopDownView.h"
#import "TTTAttributedLabel.h"
#import "ORRangeString.h"
#import "ORShareActionSheet.h"
#import "ORHashtagView.h"

@interface ORWatchVideoCell () <UIActionSheetDelegate, ORMoviePlayerViewDelegate, TTTAttributedLabelDelegate>

@property (nonatomic, assign) BOOL repostPending;
@property (nonatomic, assign) BOOL likePending;
@property (nonatomic, assign) BOOL loadedStatus;

@property (nonatomic, assign) BOOL triedFacebook;
@property (nonatomic, assign) BOOL modified;
@property (nonatomic, strong) OREpicFriend *friend;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, assign) NSUInteger thumbnailIndex;
@property (nonatomic, strong) ORMoviePlayerView *moviePlayer;
@property (nonatomic, strong) NSString *tempString;
@property (nonatomic, strong) NSString *tempAction;

@end

@implementation ORWatchVideoCell

- (void)dealloc
{
    if (self.likePending) {
        [self performLike];
    }
    
    if (self.repostPending) {
        [self performRepostKeepSelf:NO];
    }
    
    self.lblTitle.delegate = nil;
    self.alertView.delegate = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (CGFloat)heightForCellWithVideo:(OREpicVideo *)video
{
    if (ORIsEmpty(video.name)) {
        return CGRectGetMinY(self.viewTitle.frame) + CGRectGetHeight(self.viewButtons.frame) + 1.0f;
    } else {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CGSize sizeToFit = [video.name sizeWithFont:self.lblTitle.font constrainedToSize:CGSizeMake(self.lblTitle.frame.size.width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
        #pragma clang diagnostic pop
        return CGRectGetMinY(self.viewTitle.frame) + ceilf(sizeToFit.height) + 22.0f + CGRectGetHeight(self.viewButtons.frame);
    }
}

- (void)awakeFromNib
{
	self.aiUploading.color = APP_COLOR_PRIMARY;
    self.viewDurationParent.layer.cornerRadius = 5.0f;
    
    self.btnFavorite.layer.cornerRadius = 5.0f;
    self.btnFavorite.layer.borderWidth = 1.0f;
    self.btnFavorite.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.btnRepost.layer.cornerRadius = 5.0f;
    self.btnRepost.layer.borderWidth = 1.0f;
    self.btnRepost.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.lblTitle.delegate = self;
    self.lblTitle.enabledTextCheckingTypes = NSTextCheckingTypeLink;
	
	[self updateLikeAndRepostButtons];
}

- (void)setVideo:(OREpicVideo *)video
{
	_video = video;
    
    if (!self.moviePlayer && video) {
        self.moviePlayer = [[ORMoviePlayerView alloc] initWithVideo:video];
        [self.parent addChildViewController:self.moviePlayer];
        self.moviePlayer.delegate = self;
        self.moviePlayer.view.frame = self.viewVideo.bounds;
        [self.viewVideo addSubview:self.moviePlayer.view];
        [self.moviePlayer didMoveToParentViewController:self.parent];
        [self.moviePlayer loadVideo];
        if (self.parent.shouldAutoplay) [self.moviePlayer btnPlay_TouchUpInside:nil];
    } else {
//        [self.moviePlayer play];
    }
	   
    self.lblViews.text = self.video.viewCountString;
	self.lblDuration.text = self.video.friendlyDurationString;
	self.lblDate.text = self.video.friendlyDateString;
	self.lblLocation.text = self.video.locationFriendlyName;
    
    [self setVideoTitle:self.video];
    
	CGSize maximumLabelSize = CGSizeMake(310, 9999);
	CGRect textRect = [self.lblDuration.text boundingRectWithSize:maximumLabelSize
														  options:NSStringDrawingUsesLineFragmentOrigin
													   attributes:@{NSFontAttributeName:self.lblDuration.font}
														  context:nil];
    CGRect f = self.viewDurationParent.frame;
	f.size.width = textRect.size.width + 16.0f;
	f.origin.x = self.viewDurationParent.superview.frame.size.width - f.size.width - 8.0f;
	self.viewDurationParent.frame = f;
	
	// LIKE & REPOST
	[self updateLikeAndRepostButtons];
	
	// LOCATION
    if (self.video.latitude == 0 && self.video.longitude == 0) {
        self.lblLocation.textColor = [UIColor lightGrayColor];
        self.btnLocation.enabled = NO;
    } else {
        self.lblLocation.textColor = [UIColor darkGrayColor];
        self.btnLocation.enabled = YES;
    }
	
	// BADGES & EDIT BUTTON
	if ([self.video.userId isEqualToString:CurrentUser.userId]) {
		
        // Timebomb
        if (self.video.timebombMinutes > 0) {
			self.viewTimebomb.hidden = NO;
			self.lblTimebomb.text = self.video.friendlyTimebombString;
        } else {
			self.viewTimebomb.hidden = YES;
		}
		
		// Uploading / Bad State
		switch (self.video.state) {
					
			case OREpicVideoStateUploaded:
            case OREpicVideoStateExpired:
				self.imgBadge1.image = nil;
				break;
				
			case OREpicVideoStateUploading:
				self.imgBadge1.image = [UIImage imageNamed:@"uploading-icon-wire-white-glow-20x"];
				[self.aiUploading startAnimating];
				break;
				
			case OREpicVideoStateNotUploaded:
            case OREpicVideoStateDeleted:
				DLog(@"OREpicVideoStateNotUploaded");
				self.imgBadge1.image = [UIImage imageNamed:@"uploading-icon-wire-white-glow-20x"];
				break;
				
			case OREpicVideoStateUnknown:
				DLog(@"OREpicVideoStateUnknown");
				self.imgBadge1.image = [UIImage imageNamed:@"alert-icon-wire-white-glow-20x"];
				break;
				
			case OREpicVideoStateUploadFailed:
				DLog(@"OREpicVideoStateUploadFailed");
				self.imgBadge1.image = [UIImage imageNamed:@"alert-icon-wire-white-glow-20x"];
				break;
		}
		
		self.btnDelete.hidden = NO;
		self.btnShare.hidden = NO;
	} else {
		
		self.btnDelete.hidden = YES;
		self.btnShare.hidden = (self.video.privacy == OREpicVideoPrivacyPrivate);
	}
	
    if (video.user) {
        self.friend = video.user;
        [self setupForFriend];
    } else if (video.userId) {
        __weak OREpicVideo *weakVideo = video;
        __weak ORWatchVideoCell *weakSelf = self;
        
        [ApiEngine friendWithId:video.userId completion:^(NSError *error, OREpicFriend *user) {
            if (![weakVideo.userId isEqualToString:user.userId]) return;
            
            if (user) {
                weakVideo.user = user;
                weakSelf.friend = user;
                [weakSelf setupForFriend];
            }
        }];
    }
    
    if (!self.loadedStatus && self.video) {
        self.loadedStatus = YES;

        [ApiEngine videoStatusWithId:self.video.videoId completion:^(NSError *error, OREpicVideo *video) {
            if (video) {
                self.video.liked = video.liked;
                self.video.reposted = video.reposted;
                if (video.liked || video.reposted) [[NSNotificationCenter defaultCenter] postNotificationName:@"ORVideoLikedUnliked" object:self.video];
				[self updateLikeAndRepostButtons];
            }
        }];
    }
}

- (void)updateLikeAndRepostButtons
{
	// LIKE
	self.btnFavorite.selected = self.video.liked;
	self.btnFavorite.backgroundColor = (self.btnFavorite.selected) ? APP_COLOR_PURPLE : [UIColor clearColor];
	self.btnFavorite.layer.borderColor = (self.btnFavorite.selected) ? [UIColor clearColor].CGColor : [UIColor lightGrayColor].CGColor;
	
	// Set Like Button Frame
	CGRect f = self.btnFavorite.frame;
//	if (CurrentUser.isFacebookAuthenticated && self.video.privacy == OREpicVideoPrivacyPublic && !self.video.liked) {
//		self.viewFacebookLike.hidden = NO;
//		f.size.width = 122.0f;
//		[self.btnFavorite setTitle:@"Like" forState:UIControlStateNormal];
//	} else {
		if (self.video.liked) {
			self.viewFacebookLike.hidden = YES;
			f.size.width = 84.0f;
			[self.btnFavorite setTitle:@"Liked" forState:UIControlStateNormal];
		} else {
			self.viewFacebookLike.hidden = YES;
			f.size.width = 78.0f;
			[self.btnFavorite setTitle:@"Like" forState:UIControlStateNormal];
		}
//	}
	self.btnFavorite.frame = f;
	
	// REPOST
	self.btnRepost.selected = self.video.reposted;
	self.btnRepost.backgroundColor = (self.btnRepost.selected) ? APP_COLOR_PURPLE : [UIColor clearColor];
	self.btnRepost.layer.borderColor = (self.btnRepost.selected) ? [UIColor clearColor].CGColor : [UIColor lightGrayColor].CGColor;
	
	self.btnRepost.hidden = (self.video.privacy != OREpicVideoPrivacyPublic);
	if ([self.video.userId isEqualToString:CurrentUser.userId]) self.btnRepost.hidden = YES;
	
	// Set Repost Button Frame
	CGRect f1 = self.btnRepost.frame;
	f1.origin.x = f.origin.x + f.size.width + 8;
	if (self.video.reposted) {
		f1.size.width = 104.0f;
		[self.btnRepost setTitle:@"Reposted" forState:UIControlStateNormal];
	} else {
		f1.size.width = 92.0f;
		[self.btnRepost setTitle:@"Repost" forState:UIControlStateNormal];
	}
	self.btnRepost.frame = f1;

}

- (void)setVideoTitle:(OREpicVideo *)video
{
    if (ORIsEmpty(self.video.name)) {
        self.viewTitle.hidden = YES;
        return;
    }

    NSDictionary *attributes = @{NSFontAttributeName: self.lblTitle.font, NSForegroundColorAttributeName: APP_COLOR_LIGHT_PURPLE, NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone)};
    self.lblTitle.linkAttributes = attributes;
    self.lblTitle.text = video.name;
    self.viewTitle.hidden = NO;
    
    [video parseHashtagsForce:NO];
    
    for (ORRangeString *tag in video.parsedHashtags) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tag://%@", [tag.string stringByReplacingOccurrencesOfString:@"#" withString:@""]]];
        [self.lblTitle addLinkToURL:url withRange:tag.range];
    }
    
    for (ORRangeString *tag in video.taggedUsers) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"user://%@", tag.string]];
        [self.lblTitle addLinkToURL:url withRange:tag.range];        
    }
}

- (void)setupForFriend
{
    [self.lblUserName setText:self.friend.firstName];
    self.imgAvatar.image = [UIImage imageNamed:@"profile"];
    
	if (self.friend.profileImageUrl) {
        NSURL *url = [NSURL URLWithString:self.friend.profileImageUrl];
        __weak ORWatchVideoCell *weakSelf = self;
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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.imgAvatar.layer.cornerRadius = self.imgAvatar.frame.size.width / 2.0f;
    
    CGSize size = [self.lblTitle sizeThatFits:CGSizeMake(self.lblTitle.frame.size.width, CGFLOAT_MAX)];
    CGRect f = self.lblTitle.frame;
    f.size.height = size.height;
    self.lblTitle.frame = f;
    
    f = self.viewVideo.frame;
    if (UIInterfaceOrientationIsLandscape(self.parent.interfaceOrientation)) {
        f.size.height = 320.0f;
    } else {
        f.size.height = ceilf(f.size.width * 9.0f / 16.0f);
    }
    
    self.viewVideo.frame = f;
    self.viewOverlay.frame = f;
}

#pragma mark - UI

- (IBAction)btnAvatar_TouchUpInside:(id)sender
{
	ORUserProfileView *vc;
    
	if (self.friend) {
		vc = [[ORUserProfileView alloc] initWithFriend:self.friend];
    } else if (self.video.user) {
		vc = [[ORUserProfileView alloc] initWithFriend:self.video.user];
	} else {
		DLog(@"WARNING: FIGURE THIS OUT - SHOULDN'T HAPPEN");
	}
    
	[self.parent.navigationController pushViewController:vc animated:YES];
}

- (IBAction)btnDots_TouchUpInside:(id)sender
{
	[self openExtendedActionSheet];
}

- (IBAction)btnShare_TouchUpInside:(id)sender
{
	if (CurrentUser.accountType == 3) {
		[RVC presentSignInWithMessage:@"Sign-in to share your videos!" completion:^(BOOL success) {
			if (success) {
				if (![self.video.userId isEqualToString:CurrentUser.userId]) self.video.userId = CurrentUser.userId;
			}
		}];
		
		return;
	}

    [self showNativeShare];
}

- (IBAction)btnDelete_TouchUpInside:(id)sender {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete this video?"
													message:[NSString stringWithFormat:@"This action cannot be undone."]
												   delegate:self
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"Delete", nil];
	alert.tag = 2;
	[alert show];
}

- (IBAction)btnLocation_TouchUpInside:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORPausePlayerSOFT" object:nil];
    
    ORMapView *vc = [[ORMapView alloc] initWithVideos:@[self.video]];
	[self.parent.navigationController pushViewController:vc animated:YES];
}

- (IBAction)btnFavorite_TouchUpInside:(id)sender
{
    if (CurrentUser.accountType == 3) {
        [RVC presentSignInWithMessage:@"Sign-in to favorite this video!" completion:^(BOOL success) {
            if (success) {
                [self btnFavorite_TouchUpInside:sender];
            }
        }];
        
        return;
    }

    if (self.video.liked) {
        if (self.likePending) {
            self.likePending = NO;
        } else {
            [self performUnlike];
        }
        
        self.video.liked = NO;
        self.video.likeCount--;
		[self updateLikeAndRepostButtons];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORVideoLikedUnliked" object:self.video];
    } else {
		
//        if (!self.triedFacebook && CurrentUser.isFacebookAuthenticated && ![FBSession.activeSession.permissions containsObject:@"publish_actions"]) {
//            self.triedFacebook = YES;
//            
//            [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions"] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
//                if (error) NSLog(@"Error: %@", error);
//                if (!error) [RVC updateFacebookPairing];
//                
//                [self btnFavorite_TouchUpInside:self.btnFavorite];
//            }];
//            
//            return;
//        }
		
        self.likePending = YES;
        self.video.liked = YES;
        self.video.likeCount++;
		[self updateLikeAndRepostButtons];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORVideoLikedUnliked" object:self.video];
        
        ORPopDownView *pop = [[ORPopDownView alloc] initWithTitle:@"Video Liked"
                                                         subtitle:@""];
        
        __weak ORWatchVideoCell *weakSelf = self;
        
        [pop setUndoBlock:^{
            [weakSelf btnFavorite_TouchUpInside:sender];
        }];
        
        [pop setCompletionBlock:^{
            [weakSelf performLike];
        }];
        
        [pop displayInView:self.parent.view hideAfter:4.0f];
    }
}

- (IBAction)btnRepost_TouchUpInside:(id)sender
{
    // You can't repost your own video
    if ([self.video.userId isEqualToString:CurrentUser.userId]) return;
    
    if (CurrentUser.accountType == 3) {
        [RVC presentSignInWithMessage:@"Sign-in to repost this video!" completion:^(BOOL success) {
            if (success) {
                [self btnRepost_TouchUpInside:sender];
            }
        }];
        
        return;
    }
    
    if (self.video.user.isPrivate) {
        ORPopDownView *pop = [[ORPopDownView alloc] initWithTitle:@"Repost Failed"
                                                         subtitle:@"Unable to repost videos from a private account"];
        
        [pop displayInView:self.parent.view hideAfter:4.0f];
        return;
    }

    if (self.video.reposted) {
        if (self.repostPending) {
            self.repostPending = NO;
        } else {
            [self performUnrepost];
        }
        
        self.video.reposted = NO;
        self.video.repostCount--;
		[self updateLikeAndRepostButtons];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORVideoRepostedUnreposted" object:self.video];
    } else {
        self.repostPending = YES;

        self.video.reposted = YES;
        self.video.repostCount++;
		[self updateLikeAndRepostButtons];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORVideoRepostedUnreposted" object:self.video];
        
        ORPopDownView *pop = [[ORPopDownView alloc] initWithTitle:@"Video Reposted"
                                                         subtitle:@""];
        
        __weak ORWatchVideoCell *weakSelf = self;
        
        [pop setUndoBlock:^{
            [weakSelf btnRepost_TouchUpInside:sender];
        }];
        
        [pop setCompletionBlock:^{
            [weakSelf performRepostKeepSelf:YES];
        }];
        
        [pop displayInView:self.parent.view hideAfter:4.0f];
    }
}

#pragma mark - Custom

- (void)showNativeShare
{
	if (CurrentUser.accountType == 3 && [self.video.userId isEqualToString:CurrentUser.userId]) {
		[RVC presentSignInWithMessage:@"Sign-in to share videos!" completion:^(BOOL success) {
			if (success) {
				if (![self.video.userId isEqualToString:CurrentUser.userId]) self.video.userId = CurrentUser.userId;
			}
		}];
		
		return;
	}
	
	if (self.video.privacy != OREpicVideoPrivacyPublic && ![self.video.userId isEqualToString:CurrentUser.userId])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Share"
														message:@"Sorry, this video is private and can't be shared."
													   delegate:nil
											  cancelButtonTitle:@"Ok"
											  otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	if ([self.video.userId isEqualToString:CurrentUser.userId]) {
		self.video.user = [[OREpicFriend alloc] initWithUser:CurrentUser];
	}
	
	ORShareActionSheet *share = [[ORShareActionSheet alloc] initWithVideo:self.video andImage:self.moviePlayer.imgThumbnail.image showFacebookAndTwitter:YES];
	share.parentVC = self.parent;
	[self.parent presentViewController:share animated:YES completion:^{
	}];
}

- (void)performRepostKeepSelf:(BOOL)keepSelf
{
	if (!self.repostPending) return;
	self.repostPending = NO;
    
    __weak ORWatchVideoCell *weakSelf = (keepSelf) ? self : nil;
	
	[ApiEngine repostVideo:self.video.videoId completion:^(NSError *error, BOOL result) {
		if (error) NSLog(@"Error: %@", error);
		if (result) NSLog(@"Video Reposted on Server");
        if (!error && !result && weakSelf.parent) {
            ORPopDownView *pop = [[ORPopDownView alloc] initWithTitle:@"Repost Failed"
                                                             subtitle:@"Unable to repost videos from a private account"];
            
            [pop displayInView:weakSelf.parent.view hideAfter:4.0f];
        }
	}];
	
	// TODO: TPF: reenable these when you add the opt-in UI
	//    [self.video postToTwitter];
	//    [self.video postToFacebook];
}

- (void)performUnrepost
{
	[ApiEngine unrepostVideo:self.video.videoId completion:^(NSError *error, BOOL result) {
		if (error) NSLog(@"Error: %@", error);
		if (result) NSLog(@"Video Unreposted on Server");
	}];
}

- (void)performLike
{
	if (!self.likePending) return;
	self.likePending = NO;
	
	[ApiEngine likeVideo:self.video.videoId completion:^(NSError *error, BOOL result) {
		if (error) NSLog(@"Error: %@", error);
		if (result) NSLog(@"Video Liked on Server");
	}];
    
//    if (CurrentUser.isFacebookAuthenticated && self.video.privacy == OREpicVideoPrivacyPublic) {
//        NSDictionary *params = @{@"object": self.video.playerUrlPublic};
//        
//        [FBRequestConnection startWithGraphPath:@"/me/og.likes" parameters:params HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//            if (error) NSLog(@"Error: %@", error);
//            
//            if ([result isKindOfClass:[NSDictionary class]]) {
//                NSString *likeId = [result objectForKey:@"id"];
//                NSLog(@"Video liked on FB: %@", likeId);
//            }
//        }];
//    }
}

- (void)performUnlike
{
	[ApiEngine unlikeVideo:self.video.videoId completion:^(NSError *error, BOOL result) {
		if (error) NSLog(@"Error: %@", error);
		if (result) NSLog(@"Video Unliked on Server");
	}];
}

- (void)deleteVideo
{
    OREpicVideo *video = self.video;
    
    // Cancel the video upload, if pending
    [[ORFaspPersistentEngine sharedInstance] cancelVideoUpload:video];
	
    [ApiEngine deleteVideoWithId:video.videoId cb:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
        
        if (result) {
            CurrentUser.totalVideoCount--;
            [CurrentUser saveLocalUser];
            
            // Delete local files
            NSString *localPath = [[ORUtility documentsDirectory] stringByAppendingPathComponent:video.videoId];
			
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
    [self.parent close];
}

#pragma mark - Uploading Progress

- (void)uploadFinished
{
    [self setVideo:self.video];
	[self.aiUploading stopAnimating];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
	
	switch (alertView.tag) {
		case 1: // Unused
			break;
        case 2:
            if (alertView.cancelButtonIndex == buttonIndex) return;
            [self deleteVideo];
            break;
		case 3: // Unused
//            if (buttonIndex == alertView.firstOtherButtonIndex) {
//                [self displaySmsComposer];
//            } else if (buttonIndex == alertView.firstOtherButtonIndex + 1) {
//                [self displayEmailComposer];
//            }
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
        
        __weak ORWatchVideoCell *weakSelf = self;
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

#pragma mark - ORMoviePlayerViewDelegate

- (void)moviePlayerWillStartPlaying:(ORMoviePlayerView *)moviePlayer
{
    self.viewOverlay.hidden = YES;
}

- (void)moviePlayerDidStartPlaying:(ORMoviePlayerView *)moviePlayer
{
	self.lblViews.text = self.video.viewCountString;
}

- (void)moviePlayerDidFinishPlaying:(ORMoviePlayerView *)moviePlayer
{
    self.viewOverlay.hidden = NO;
}

- (void)moviePlayerDidFailPlaying:(ORMoviePlayerView *)moviePlayer
{
    [self.parent close];
}

- (void)moviePlayerDidExitFullscreen:(ORMoviePlayerView *)moviePlayer
{
    [self.parent configureForOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

#pragma mark - Video Playback

- (void)hardPause
{
    [self.moviePlayer hardPause];
}

- (void)softPause
{
	[self.moviePlayer softPause];
}

- (void)unpause
{
    [self.moviePlayer unpause];
}

- (void)play
{
    [self.moviePlayer play];
}

- (void)stop
{
    [self.moviePlayer stop];
}

#pragma mark - UIActionSheet

- (void)openExtendedActionSheet
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORPausePlayerSOFT" object:nil];
    UIActionSheet *actionSheet;
	
//	if ([self.video.userId isEqualToString:CurrentUser.userId]) {
//		actionSheet = [[UIActionSheet alloc] initWithTitle:@""
//												  delegate:self
//										 cancelButtonTitle:@"Cancel"
//									destructiveButtonTitle:nil
//										 otherButtonTitles:@"Get Video Url", @"Get Embed Code", @"Flag Video", @"Share", @"Delete Video", nil];
//		actionSheet.destructiveButtonIndex = 5;
//	} else {
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"Video Options"
									  delegate:self
							 cancelButtonTitle:@"Cancel"
						destructiveButtonTitle:nil
							 otherButtonTitles:@"Flag Video", nil];
		actionSheet.destructiveButtonIndex = 4;
//	}
	
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	actionSheet.tag = 2;
    [actionSheet showInView:AppDelegate.viewController.view];
}

- (void)showFlaggingActionSheet
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORPausePlayerSOFT" object:nil];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
													cancelButtonTitle:@"Cancel"
											   destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Violates Copyright", @"Illegal", @"Violates Content Policy", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    actionSheet.destructiveButtonIndex = 3;
	actionSheet.tag = 1;
    [actionSheet showInView:AppDelegate.viewController.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    actionSheet.delegate = nil;
    
	if (actionSheet.tag == 1) {
		if (buttonIndex == 0) {
			DLog(@"Violates copyright");
		} else if (buttonIndex == 1) {
			DLog(@"Illegal");
		} else if (buttonIndex == 2) {
			DLog(@"Violates content policy");
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ORUnpausePlayer" object:nil];
	} else if (actionSheet.tag == 2) {
		switch (buttonIndex) {
			case 0:
				[self showFlaggingActionSheet];
				break;
			case 1:
				//
				break;
			case 2:
				//
				break;
			case 3:
				// N/A
				break;
			default:
				break;
		}
	}
}

@end
