//
//  ORPostCaptureInnerView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/27/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORPostCaptureView.h"
#import "OREpicVideo.h"
#import "ORLocationPicker.h"
#import <Social/Social.h>
#import "ORFaspPersistentEngine.h"
#import "ORFoursquareVenue.h"
#import "ORFoursquareVenueLocation.h"
#import "ORGooglePlaceDetails.h"
#import "ORGooglePlaceDetailsGeometry.h"
#import "ORGooglePlaceDetailsGeometryLocation.h"
#import "ORDirectSendView.h"
#import "ORMoviePlayerView.h"
#import "ORTwitterPlace.h"
#import "ORTwitterTrend.h"
#import "ORRangeString.h"
#import "ORUserCell.h"
#import "KAProgressLabel.h"
#import "ORSubscriptionUpsell.h"
#import "ORFacebookPicker.h"
#import "ORTwitterPicker.h"
#import "ORShareActionSheet.h"
#import "ORMessageOverlayView.h"
#import "ORTwitterAccount.h"
#import "ORFacebookPage.h"
#import "ORPopDownView.h"

@interface ORPostCaptureView () <UIAlertViewDelegate, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL videoSaved;
@property (assign, nonatomic) BOOL videoSent;

@property (nonatomic, readonly) UIScrollView *scrollView;
@property (strong, nonatomic) OREpicVideo* video;
@property (strong, nonatomic) NSArray *places;
@property (assign, nonatomic) BOOL isUploaded;
@property (assign, nonatomic) BOOL isTranscoding;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, assign) BOOL isLoadingHashtags;
@property (nonatomic, strong) ORLocationPicker *locationPicker;

@property (nonatomic, assign) NSUInteger lastWoeId;
@property (nonatomic, strong) NSArray *twitterHashtags;
@property (nonatomic, strong) NSString *cachedTagsFilename;
@property (nonatomic, strong) NSMutableOrderedSet *cachedTags;
@property (nonatomic, strong) NSString *titlePlaceholder;

@property (assign, nonatomic) CGPoint previousOffset;
@property (nonatomic, assign) NSRange hashtagRange;
@property (nonatomic, assign) NSRange nameRange;
@property (nonatomic, strong) NSMutableOrderedSet *allHashtags;
@property (nonatomic, strong) NSMutableOrderedSet *filteredHashtags;
@property (nonatomic, strong) NSMutableOrderedSet *filteredUsers;
@property (nonatomic, strong) NSMutableArray *taggedUsers;
@property (nonatomic, assign) BOOL tagsChanged;
@property (nonatomic, assign) BOOL nameSearch;

@property (nonatomic, copy) NSString *videoName;
@property (nonatomic, assign) OREpicVideoPrivacy videoPrivacy;
@property (nonatomic, assign) NSUInteger videoTimebombMinutes;
@property (nonatomic, copy) NSDate *videoExpirationTime;

@end

@implementation ORPostCaptureView

- (UIScrollView *)scrollView
{
    return ((UIScrollView *)self.view);
}

- (void)dealloc
{
    self.alertView.delegate = nil;
    self.contentView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithVideo:(OREpicVideo*)video andPlaces:(NSArray*)places
{
    self = [super initWithNibName:@"ORPostCaptureView" bundle:nil];
    if (self) {
        _video = video;
		_places = places;

        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self.view addSubview:self.contentView];
    self.scrollView.contentSize = self.contentView.frame.size;

    self.screenName = @"PostCapture";
    
    OREpicVideo *existing = [[ORDataController sharedInstance] pendingVideoWithId:self.video.videoId];
    if (existing) self.video = existing;

	[self registerForNotifications];
    [self resetNavButtons];
    [self initCachedTags];
	[self getLocation];
    [self reloadHashtags];
    
    // Get modifiable properties from video
    self.videoName = self.video.name;
    self.videoPrivacy = self.video.privacy;
    self.videoTimebombMinutes = self.video.timebombMinutes;
    self.videoExpirationTime = self.video.expirationTime;
	
	// Caption
    self.titlePlaceholder = @"Write a caption...";
    self.taggedUsers = [NSMutableArray arrayWithArray:self.video.taggedUsers];
	[self updateAutoTitle];
	
    // Video
    if (self.video) {
        self.moviePlayer = [[ORMoviePlayerView alloc] initWithVideo:self.video];
        [self addChildViewController:self.moviePlayer];
		self.moviePlayer.isAirPlayEnabled = NO;
        self.moviePlayer.fullscreenOnly = YES;
        self.moviePlayer.view.frame = self.viewThumbHost.bounds;
        [self.viewThumbHost addSubview:self.moviePlayer.view];
        [self.moviePlayer didMoveToParentViewController:self];
    }
    
    if (self.videoPrivacy == OREpicVideoPrivacyPublic) {
        self.btnPrivate.selected = NO;
        self.btnPublic.selected = YES;
        [self setIndicatorToButton:self.btnPublic];
    } else {
        self.btnPrivate.selected = YES;
        self.btnPublic.selected = NO;
        [self setIndicatorToButton:self.btnPrivate];
	}

	// Load Fb & Tw Pickers
    self.facebookPicker = [ORFacebookPicker new];
    [self addChildViewController:self.facebookPicker];
    [self.facebookPicker.view setFrame:self.viewFacebook.bounds];
    [self.viewFacebook addSubview:self.facebookPicker.view];
    [self.facebookPicker didMoveToParentViewController:self];

    self.twitterPicker = [ORTwitterPicker new];
    [self addChildViewController:self.twitterPicker];
    [self.twitterPicker.view setFrame:self.viewTwitter.bounds];
    [self.viewTwitter addSubview:self.twitterPicker.view];
    [self.twitterPicker didMoveToParentViewController:self];
    
    self.facebookPicker.selected = (self.videoPrivacy == OREpicVideoPrivacyPublic && self.video.facebookId != nil);
    self.twitterPicker.selected = (self.videoPrivacy == OREpicVideoPrivacyPublic && self.video.twitterId != nil);

	[self updateProgressDisplay:0];
    [self updateProgressState];
    [self layoutSubviews];
	
	[self putVideoUrlInClipboard];
	
    self.btnFinish.layer.cornerRadius = 4.0f;
	self.lblDiscardVideoAfter.layer.cornerRadius = 4.0f;
	self.btnShare.layer.cornerRadius = 4.0f;
	
    self.captionTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.captionTableView.backgroundColor = APP_COLOR_LIGHT_GREY;
	
    [self updateFinishButtonText];

	// PROGRESS VIEW
	__weak ORPostCaptureView *weakSelf = self;

	self.progressRing.progressLabelVCBlock = ^(KAProgressLabel *label, CGFloat progress) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (progress == 1.0f){
//				[label setText:@"UPLOAD\nCOMPLETE"];
				weakSelf.viewUploadComplete.hidden = NO;
				[weakSelf.viewUploadComplete.superview bringSubviewToFront:weakSelf.viewUploadComplete];
				[label setText:@""];
				label.numberOfLines = 2;
			} else {
				[label setText:[NSString stringWithFormat:@"%.0f%%", (progress*100)]];
				label.textAlignment = NSTextAlignmentCenter;
			}
		});
	};
	
	[self.progressRing setProgressType:ProgressLabelRect];

	float borderW = 2.0f;
	[self.progressRing setBackBorderWidth:borderW];
	[self.progressRing setFrontBorderWidth:borderW-.2f];

	[self.progressRing setColorTable: @{
								  NSStringFromProgressLabelColorTableKey(ProgressLabelTrackColor):[UIColor darkGrayColor],
								  NSStringFromProgressLabelColorTableKey(ProgressLabelProgressColor):APP_COLOR_PRIMARY
								  }];
    
    [self.progressRing setProgress:0.01f
                            timing:TPPropertyAnimationTimingEaseOut
                          duration:0.2
                             delay:0.0];

    [self.progressRing setProgress:0
                            timing:TPPropertyAnimationTimingEaseOut
                          duration:0.2
                             delay:0.0];

	self.viewUploadComplete.hidden = YES;
	
	// TIMEBOMB
	
    switch (self.videoTimebombMinutes) {
        case 0:
			[self setTimebombIndicator:self.btnTimebombNever];
            break;
        case 60:
			[self setTimebombIndicator:self.btnTimebomb1hr];
            break;
        case 1440:
			[self setTimebombIndicator:self.btnTimebomb1day];
            break;
        default:
			[self setTimebombIndicator:self.btnTimebomb1week];
            break;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    self.title = @"V  I  D  E  O";
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.title = @"VIDEO";
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Transition and Presentation

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self;
}

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self;
}

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.25;
}

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController* vc1 = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController* vc2 = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView* con = [transitionContext containerView];
    UIView* v1 = vc1.view;
    UIView* v2 = vc2.view;
    
    if (vc2 == self) { // presenting
        [con addSubview:v2];
        v2.frame = v1.frame;
        v2.alpha = 0.0f;
        v1.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        
        [UIView animateWithDuration:0.25 animations:^{
            v2.alpha = 1.0f;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else { // dismissing
        [UIView animateWithDuration:0.25 animations:^{
            v1.alpha = 0.0f;
        } completion:^(BOOL finished) {
            v2.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
            [transitionContext completeTransition:YES];
        }];
    }
}

#pragma mark - UI

- (IBAction)btnPrivate_TouchUpInside:(UIButton*)sender
{
	if (sender.isSelected) {
		[self switchToPublic];
		[self setIndicatorToButton:self.btnPublic];
	} else {
		[self switchToPrivate];
		[self setIndicatorToButton:sender];
	}
}

- (IBAction)btnPublic_TouchUpInside:(UIButton*)sender
{
	if (sender.isSelected) {
		[self switchToPrivate];
		[self setIndicatorToButton:self.btnPrivate];
	} else {
		[self switchToPublic];
		[self setIndicatorToButton:sender];
	}
}

- (void)btnVideoOptions_TouchUpInside:(id)sender
{
    [self layoutSubviews];
}

- (IBAction)view_TouchUpInside:(id)sender {
	[self.view endEditing:YES];
}

- (IBAction)btnTimebomb1hr_TouchUpInside:(UIButton*)sender
{
	self.videoTimebombMinutes = 60;
    self.videoExpirationTime = [self.video.startTime dateByAddingTimeInterval:self.videoTimebombMinutes * 60];
	[self setTimebombIndicator:sender];
}

- (IBAction)btnTimebomb1day_TouchUpInside:(UIButton*)sender
{
	self.videoTimebombMinutes = 1440;
    self.videoExpirationTime = [self.video.startTime dateByAddingTimeInterval:self.videoTimebombMinutes * 60];
	[self setTimebombIndicator:sender];
}

- (IBAction)btnTimebomb1week_TouchUpInside:(UIButton*)sender
{
	self.videoTimebombMinutes = 10080;
    self.videoExpirationTime = [self.video.startTime dateByAddingTimeInterval:self.videoTimebombMinutes * 60];
	[self setTimebombIndicator:sender];
}

- (IBAction)btnTimebombNever_TouchUpInside:(UIButton*)sender
{
	if (CurrentUser.subscriptionLevel == 0) {
		[self showSubscriptionUpsell];
	} else {
		self.videoTimebombMinutes = 0;
        self.videoExpirationTime = nil;
		[self setTimebombIndicator:sender];
	}
}

- (IBAction)btnShare_TouchUpInside:(id)sender {
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

- (IBAction)btnLocation_TouchUpInside:(id)sender
{
	[self.view endEditing:YES];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:self.video.latitude longitude:self.video.longitude];
	ORLocationPicker *vc = [[ORLocationPicker alloc] initWithPlaces:self.places selectedPlace:nil location:location];
  
	[self.navigationController pushViewController:vc animated:YES];
}

- (void)btnRemoveLocation_TouchUpInside:(id)sender
{
    [self handleORLocationSelected:nil];
}

- (void)btnForceUpload_TouchUpInside:(id)sender
{
    [self.progressRing setProgress:0
                            timing:TPPropertyAnimationTimingEaseOut
                          duration:0.2
                             delay:0.0];

    [[ORFaspPersistentEngine sharedInstance] setWifiOnlyMode:NO];
    [[ORFaspPersistentEngine sharedInstance] resumeFromBackground];
    [self updateProgressState];
}

- (void)btnFinish_TouchUpInside:(id)sender
{
    [self textViewDidChange:self.txtTitle];
    [self finishedAction];
}

- (void)viewOverlay_TouchUpInside:(id)sender
{
    [self.txtTitle resignFirstResponder];
}

- (IBAction)btnClearCaption_TouchUpInside:(id)sender
{
    if (self.txtTitle.isFirstResponder) {
        self.txtTitle.text = @"";
    } else {
        self.txtTitle.text = self.titlePlaceholder;
        self.txtTitle.textColor = [UIColor lightGrayColor];
    }
}

#pragma mark - Custom

- (void)videoIsReady
{
    [self updateAutoTitle];
    [self.moviePlayer loadVideo];
}

- (void)discardVideoAction
{
    self.alertView = [[UIAlertView alloc] initWithTitle:@"Discard this video?"
                                                message:[NSString stringWithFormat:@"This cannot be undone."]
                                               delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:@"Discard", nil];
    self.alertView.tag = 0;
    [self.alertView show];
}

- (void)finishedAction
{
    [self finishedActionAskPrivate:YES];
}

- (void)finishedActionAskPrivate:(BOOL)askPrivate
{
    [self.view endEditing:YES];
    
    // Pre-Save
    [self prepareVideoForSaving];
    
    if (askPrivate && self.video.privacy == OREpicVideoPrivacyPrivate && (self.video.facebookId || self.video.twitterId)) {
        NSString *message = nil;
        
        if (self.video.facebookId && self.video.twitterId) {
            message = @"Do you also want to remove previous posts to Twitter and Facebook? This will also remove any comments/retweets in the posts.";
        } else if (self.video.twitterId) {
            message = @"Do you also want to remove the previous post to Twitter? This will also remove any retweets in the post.";
        } else if (self.video.facebookId) {
            message = @"Do you also want to remove the previous post to Facebook? This will also remove any comments/likes in the post.";
        }
        
        if (message) {
            self.alertView.delegate = nil;
            self.alertView = [[UIAlertView alloc] initWithTitle:@"Remove shared post?"
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
            self.alertView.tag = 7;
            [self.alertView show];
            
            return;
        }
    }
        
    self.videoSaved = YES;
    [[ORDataController sharedInstance] saveVideo:self.video];
    
    // Post Tweet
    if (self.video.privacy == OREpicVideoPrivacyPublic && !self.video.twitterId && self.twitterPicker.isSelected) {
        OREpicVideo *video = [[ORFaspPersistentEngine sharedInstance] pendingVideoWithId:self.video.videoId];
        if (!video) video = self.video;
        
        if (CurrentUser.selectedTwitterAccount) {
            CurrentUser.twitterTempToken = CurrentUser.selectedTwitterAccount.token;
            CurrentUser.twitterTempSecret = CurrentUser.selectedTwitterAccount.tokenSecret;
        }
        
        [video postToTwitter];
        [[ORFaspPersistentEngine sharedInstance] updatePendingVideos];
    }
    
    // Post to Facebook
    if (self.video.privacy == OREpicVideoPrivacyPublic && !self.video.facebookId && self.facebookPicker.isSelected) {
        OREpicVideo *video = [[ORFaspPersistentEngine sharedInstance] pendingVideoWithId:self.video.videoId];
        if (!video) video = self.video;
        
        if (CurrentUser.selectedFacebookPage) {
            CurrentUser.facebookPageToken = CurrentUser.selectedFacebookPage.accessToken;
            CurrentUser.facebookPageId = CurrentUser.selectedFacebookPage.pageId;
        }
        
        [video postToFacebook];
        [[ORFaspPersistentEngine sharedInstance] updatePendingVideos];
    }
    
    self.video.cachedHeight = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORVideoModified" object:self.video];
    
    [AppDelegate.mixpanel track:@"Video Saved Post-Capture" properties:@{@"VideoId": self.video.videoId}];
    
    // Post-Save
    if (self.video.privacy == OREpicVideoPrivacyPublic && !AppDelegate.pushNotificationsEnabled) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults boolForKey:@"dontShowPushPermission"]) {
            // Pre-OS permission requests are disabled
            [AppDelegate registerForPushNotifications];
        }
        
        [self close];
    } else {
        [self close];
    }
}

- (void)close
{
    ORPopDownView *pop = nil;
    UIAlertView *av = nil;
    
    if (self.videoSaved) {
        NSString *title = nil;
        NSString *subtitle = nil;
        
        if (self.videoSent) {
            title = @"Video Sent";
            subtitle = @"";
        } else if (self.video.privacy == OREpicVideoPrivacyPublic) {
            if (self.video.state == OREpicVideoStateUploaded) {
                title = @"Video Published";
                subtitle = @"";
            } else {
                NSString *title = nil;
                NSString *message = nil;
                
                if (ApiEngine.currentNetworkStatus == NotReachable) {
                    title = @"Upload Pending";
                    message = @"The video will transfer when you have a network connection and will be published once more of the video is transferred successfully.";
                } else if (![[ORFaspPersistentEngine sharedInstance] canUploadNow]) {
                    title = @"Upload Pending";
                    message = @"The video will transfer when you're on a wi-fi network and will be published once more of the video is transferred successfully.";
                } else {
                    title = @"Video Uploading";
                    message = @"The video is still transferring and will be published once more of the video is transferred successfully.";
                }
                
                av = [[UIAlertView alloc] initWithTitle:title
                                                message:message
                                               delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
            }
        } else {
            title = @"Video Saved";
            subtitle = @"";
        }
        
        if (title) pop = [[ORPopDownView alloc] initWithTitle:title subtitle:subtitle];
    };
    
    [RVC dismissPCVWithCompletion:^{
        if (pop) {
            [pop displayInView:RVC.view margin:20.0f hideAfter:4.0f];
        } else if (av) {
            [av show];
        }
    }];
    
}

- (void)resetNavButtons
{
    UIBarButtonItem *delete = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(discardVideoAction)];
    self.navigationItem.rightBarButtonItem = delete;
    
    [self.view endEditing:YES];
}

- (void)updateAutoTitle
{
	if (!ORIsEmpty(self.videoName)) {
		self.txtTitle.text = self.videoName;
	} else {
		self.txtTitle.text = [self.video autoCaption];
	}
	
	[self applyFormattingForTextView:self.txtTitle];
}

- (void)setIndicatorToButton:(UIButton*)btn
{
	[UIView animateWithDuration:0.2f
						  delay:0.0f
						options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 CGRect f;
						 switch (btn.tag) {
							 case 0:
								 f = self.viewFollowers.frame;
								 break;
								 
							 default:
								 f = self.viewJustMe.frame;
								 break;
						 }
						 self.viewIndicator.frame = f;
					 } completion:^(BOOL finished) {
						 btn.selected = YES;
					 }];
}

- (void)setTimebombIndicator:(UIButton*)btn
{
	self.btnTimebomb1hr.selected = NO;
	self.btnTimebomb1day.selected = NO;
	self.btnTimebomb1week.selected = NO;
	self.btnTimebombNever.selected = NO;

	[UIView animateWithDuration:0.2f delay:0.0f
						options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 CGRect f;
						 switch (btn.tag) {
							 case 0:
								 f = self.view1Hour.frame;
								 break;
							 case 1:
								 f = self.view1Day.frame;
								 break;
							 case 2:
								 f = self.view1Week.frame;
								 break;
							 case 3:
								 f = self.viewEver.frame;
								 break;
								 
							 default:
								 f = self.view1Week.frame;
								 break;
						 }
						 self.viewTimebombIndicator.frame = f;
						 btn.selected = YES;
					 } completion:^(BOOL finished) {
						 //
					 }];
	[self setDirty];
}

- (void)showSubscriptionUpsell
{
	ORSubscriptionUpsell *vc = [ORSubscriptionUpsell new];
	[self presentViewController:vc animated:YES completion:nil];
}

- (void)setDirty
{
    [self updateFinishButtonText];
}

- (void)updateFinishButtonText
{
    if (self.directChanged && self.selectedContacts.count > 0) {
        [self.btnFinish setTitle:@"Send" forState:UIControlStateNormal];
    } else if (self.videoPrivacy == OREpicVideoPrivacyPublic) {
        [self.btnFinish setTitle:@"Share" forState:UIControlStateNormal];
    } else {
        [self.btnFinish setTitle:@"Finish" forState:UIControlStateNormal];
    }
}

- (void)layoutSubviews
{
    CGRect f = self.contentView.frame;
    self.scrollView.contentSize = CGSizeMake(CGRectGetMaxX(f), CGRectGetMaxY(f));
}

- (void)updateProgressState
{
    if (self.isTranscoding) return;
    
    if (ApiEngine.currentNetworkStatus == NotReachable) {
		self.viewUploadParent.hidden = NO;
        self.lblUploadProgress.text = @"Waiting for network...";
//        self.lblUsingZeroSpace.hidden = YES;
        self.btnForceUpload.hidden = YES;
    } else if (![[ORFaspPersistentEngine sharedInstance] canUploadNow]) {
		self.viewUploadParent.hidden = NO;
        self.lblUploadProgress.text = @"Wifi-only is ON\nTap to force upload";
//        self.lblUsingZeroSpace.text = @"tap to start uploading now";
//        self.lblUsingZeroSpace.hidden = NO;
        self.btnForceUpload.hidden = NO;
    } else {
		self.viewUploadParent.hidden = YES;
        self.lblUploadProgress.text = @"Preparing upload...";
//        self.lblUsingZeroSpace.hidden = YES;
        self.btnForceUpload.hidden = YES;
    }
}

- (void)updateProgressDisplay:(double)progress
{
    if (self.isTranscoding) return;
 
	DLog(@"%f", progress);

	if (progress < 1) {
        self.btnForceUpload.hidden = YES;
        self.lblTranscoding.hidden = YES;
        
		[self.progressRing setProgress:progress
								timing:TPPropertyAnimationTimingEaseOut
							  duration:0.2
								 delay:0.0];

	} else {
        self.btnForceUpload.hidden = YES;
        self.lblTranscoding.hidden = YES;
		
		[self.progressRing setProgress:1.0f
								timing:TPPropertyAnimationTimingEaseOut
							  duration:0.2
								 delay:0.0];

    }
}

- (void)updateTranscodeDisplay:(double)progress
{
	if (progress < 1) {
        self.isTranscoding = YES;
        self.btnForceUpload.hidden = YES;
        self.lblTranscoding.hidden = NO;
        
        [self.progressRing setProgress:progress
                                timing:TPPropertyAnimationTimingEaseOut
                              duration:0.2
                                 delay:0.0];
	} else {
        self.isTranscoding = NO;
        self.lblTranscoding.hidden = YES;

        [self.progressRing setProgress:0
                                timing:TPPropertyAnimationTimingEaseOut
                              duration:0.2
                                 delay:0.0];

        [self videoIsReady];
		[self updateProgressState];
	}
}

- (void)deleteVideo
{
    OREpicVideo *video = self.video;
    self.video.state = OREpicVideoStateDeleted;
    
    // Cancel the video upload, if pending
    [[ORFaspPersistentEngine sharedInstance] cancelVideoUpload:video];
    
    // Remove the video from server
    [ApiEngine deleteVideoWithId:video.videoId cb:^(NSError *error, BOOL result) {
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
        
		[AppDelegate.mixpanel track:@"Video Discarded" properties:@{@"VideoId": self.video.videoId}];
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORVideoDeleted" object:video];
    [self close];
}

#pragma mark - Sharing

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
	
	if (self.videoPrivacy != OREpicVideoPrivacyPublic && ![self.video.userId isEqualToString:CurrentUser.userId])
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
    
    if (!ORIsEmpty(self.videoName)) self.video.name = self.videoName;
	ORShareActionSheet *share = [[ORShareActionSheet alloc] initWithVideo:self.video andImage:self.moviePlayer.imgThumbnail.image showFacebookAndTwitter:NO];
	share.parentVC = self;
	[self presentViewController:share animated:YES completion:nil];
}

- (void)switchToPrivate
{
	self.videoPrivacy = OREpicVideoPrivacyPrivate;
	self.btnPublic.selected = NO;
	
	self.facebookPicker.selected = NO;
	self.twitterPicker.selected = NO;
	
	[self setIndicatorToButton:self.btnPrivate];
	[self setDirty];
	[self layoutSubviews];
}

- (void)switchToPublic
{
	if (CurrentUser.accountType == 3) {
		[RVC presentSignInWithMessage:@"Sign-in and share with friends." completion:^(BOOL success) {
			if (success) {
				if (![self.video.userId isEqualToString:CurrentUser.userId]) self.video.userId = CurrentUser.userId;
				[self switchToPublic];
			} else {
				[self switchToPrivate];
			}
		}];
		
		return;
	}
	
	self.videoPrivacy = OREpicVideoPrivacyPublic;
	self.btnPrivate.selected = NO;
	
	[self setIndicatorToButton:self.btnPublic];
	[self setDirty];
	[self layoutSubviews];
}

- (void)putVideoUrlInClipboard
{
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
	pasteboard.string = [self videoUrlString];
}

- (NSString*)videoUrlString
{
	NSString *theLink;
	
	if ([self.video.userId isEqualToString:CurrentUser.userId]) {
		theLink = self.video.playerUrlSelected;
	} else {
		theLink = self.video.playerUrlPublic;
	}
	return theLink;
}

- (void)removeTwitterPost
{
    if (CurrentUser.isTwitterAuthenticated) {
        [AppDelegate.twitterEngine destroyId:self.video.twitterId completion:^(NSError *error, ORTweet *tweet) {
            if (error) NSLog(@"Error: %@", error);
            if (!error) NSLog(@"Tweet Removed");
        }];
        
		[AppDelegate.mixpanel track:@"Video Unshared" properties:@{
																 @"VideoId": self.video.videoId,
																 @"Destination": @"Twitter",
																 }];

    } else {
        NSLog(@"Not authenticated to Twitter");
    }
    
    self.video.twitterId = nil;
}

- (void)removeFacebookPost
{
    if ([FBSession.activeSession.permissions containsObject:@"publish_actions"]) {
        [FBRequestConnection startForDeleteObject:self.video.facebookId completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (error) NSLog(@"Error: %@", error);
            if (!error) NSLog(@"Facebook Post Removed");
        }];
        
		[AppDelegate.mixpanel track:@"Video Unshared" properties:@{
																   @"VideoId": self.video.videoId,
																   @"Destination": @"Facebook",
																   }];
    } else {
        NSLog(@"No permission to delete Facebook posts");
    }
    
    self.video.facebookId = nil;
}

- (void)prepareVideoForSaving
{
    if (!ORIsEmpty(self.txtTitle.text) && ![self.txtTitle.text isEqualToString:self.titlePlaceholder]) {
        self.videoName = self.txtTitle.text;
    }
    
    // Move back PCV changed properties to video
    self.video.name = self.videoName;
    self.video.privacy = self.videoPrivacy;
    self.video.timebombMinutes = self.videoTimebombMinutes;
    self.video.expirationTime = self.videoExpirationTime;

    NSArray *hashtags = [self extractHashtagsFromString:self.video.name];
    for (NSString *hashtag in hashtags) {
        [self addTagToCache:hashtag];
    }

    self.video.hashtags = hashtags;
    if (self.video.hashtags.count == 0) self.video.hashtags = nil;
    [self.video parseHashtagsForce:YES];
    
    self.video.taggedUsers = self.taggedUsers;
    if (self.video.taggedUsers.count == 0) self.video.taggedUsers = nil;
    
    if (self.video.authorizedNames.count == 0) {
        self.video.authorizedUserIds = nil;
        self.video.authorizedNames = nil;
        self.video.authorizedKeys = nil;
    }
}

#pragma mark - Location

- (void)getLocation
{
	if (self.video.hasLocationFriendlyName) {
		//
	} else if (self.video.latitude != 0 || self.video.longitude != 0) {
		if (self.places && self.places.count > 0) {
			[self innerSetPlaces:self.places];
		} else {
			
			CLLocation *location = [[CLLocation alloc] initWithLatitude:self.video.latitude longitude:self.video.longitude];
			__weak ORPostCaptureView *weakSelf = self;
			
			[AppDelegate.places getPlacesForLocation:location andRadiusMeters:PLACE_SEARCH_RADIUS completion:^(NSError *error, NSArray *venues) {
				if (error) DLog(@"problem getting places: %@", error.localizedDescription);
				[weakSelf innerSetPlaces:venues];
			}];
		}
	} else {
		//        [self.btnLocation setTitle:@"(no location)" forState:UIControlStateNormal];
	}
}

- (void)innerSetPlaces:(NSArray*)places
{
	self.places = places;
	
	if (self.places.count > 0 && !self.video.hasLocationFriendlyName) {
		ORFoursquareVenue *place = [self.places firstObject];
		self.video.locationFriendlyName = place.name;
		self.video.locationIsCity = place.isCity;
		[self updateAutoTitle];
		
		if (self.video.latitude == 0 && self.video.longitude == 0) {
			self.video.latitude = [place.location.lat doubleValue];
			self.video.longitude = [place.location.lng doubleValue];
			[self reloadHashtags];
		}
	}
}

#pragma mark - Tagging

- (void)reloadHashtags
{
	if (self.isLoadingHashtags) {
		NSLog(@"Already loading hashtags, won't load again.");
		return;
	}
	
	if (CurrentUser.isTwitterAuthenticated) {
		self.isLoadingHashtags = YES;
		
		if (self.video.latitude == 0 && self.video.longitude == 0) {
			[self refreshHashtagsForLocation:1];
			return;
		}
		
		__weak ORPostCaptureView *weakSelf = self;
		CLLocation *location = [[CLLocation alloc] initWithLatitude:self.video.latitude longitude:self.video.longitude];
		
		[AppDelegate.twitterEngine closestPlacesForLocation:location completion:^(NSError *error, NSArray *items) {
			if (error) NSLog(@"Error: %@", error);
			
			if (items && items.count > 0) {
				ORTwitterPlace *place = items[0];
				
				if (!ORIsEmpty(weakSelf.twitterHashtags) && place.woeId == weakSelf.lastWoeId) {
					weakSelf.isLoadingHashtags = NO;
					[weakSelf reloadTags];
					
					return;
				}
				
				[weakSelf refreshHashtagsForLocation:place.woeId];
			} else {
				[weakSelf refreshHashtagsForLocation:1];
			}
		}];
	} else {
		[self reloadTags];
	}
}

- (void)refreshHashtagsForLocation:(NSUInteger)woeId
{
	__weak ORPostCaptureView *weakSelf = self;
	
	[AppDelegate.twitterEngine trendsForPlaceId:woeId completion:^(NSError *error, NSArray *items) {
		if (error) NSLog(@"Error: %@", error);
		
		if (items.count > 0) {
			weakSelf.twitterHashtags = items;
		}
		
		weakSelf.isLoadingHashtags = NO;
		[weakSelf reloadTags];
	}];
}

- (void)initCachedTags
{
	self.cachedTagsFilename = [[ORUtility cachesDirectory] stringByAppendingPathComponent:@"user_cache/hashtags.cache"];
	self.cachedTags = [NSKeyedUnarchiver unarchiveObjectWithFile:self.cachedTagsFilename];
	if (!self.cachedTags) self.cachedTags = [NSMutableOrderedSet orderedSetWithCapacity:1];
}

- (void)reloadTags
{
	NSMutableOrderedSet *tags = [NSMutableOrderedSet orderedSetWithCapacity:self.cachedTags.count + self.twitterHashtags.count];
	
	for (NSString *tag in self.cachedTags) {
		NSCharacterSet *notAllowedChars = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
		NSString *fixed = [[tag componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
		if (!ORIsEmpty(fixed)) [tags addObject:[@"#" stringByAppendingString:fixed]];
	}
	
	for (ORTwitterTrend *hashtag in self.twitterHashtags) {
		if (hashtag.name) {
			NSCharacterSet *notAllowedChars = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
			NSString *fixed = [[hashtag.name componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
			if (!ORIsEmpty(fixed)) [tags addObject:[@"#" stringByAppendingString:fixed]];
		}
	}
	
	self.allHashtags = tags;
	self.filteredHashtags = self.allHashtags;
}

- (void)searchTags:(NSString *)query
{
	if (self.allHashtags.count > 0 && !ORIsEmpty(query)) {
		if ([query isEqualToString:@"#"]) {
			self.filteredHashtags = self.allHashtags;
		} else {
			self.filteredHashtags = [NSMutableOrderedSet orderedSetWithCapacity:self.allHashtags.count];
			query = [query substringWithRange:NSMakeRange(1, query.length - 1)];
			
			for (NSString *hashtag in self.allHashtags) {
				NSUInteger result = [hashtag rangeOfString:query options:NSCaseInsensitiveSearch].location;
				
				if (result != NSNotFound) {
					[self.filteredHashtags addObject:hashtag];
				}
			}
		}
		
		self.nameSearch = NO;
		[self.captionTableView reloadData];
		self.captionTableView.hidden = (self.filteredHashtags.count == 0);
	} else {
		self.captionTableView.hidden = YES;
	}
}

- (void)searchNames:(NSString *)query
{
	if (CurrentUser.relatedUsers.count > 0 && !ORIsEmpty(query)) {
		if ([query isEqualToString:@"@"]) {
			self.filteredUsers = CurrentUser.relatedUsers;
		} else {
			self.filteredUsers = [NSMutableOrderedSet orderedSetWithCapacity:CurrentUser.relatedUsers.count];
			query = [query substringWithRange:NSMakeRange(1, query.length - 1)];
			
			for (OREpicFriend *friend in CurrentUser.relatedUsers) {
				NSUInteger result = [friend.name rangeOfString:query options:NSCaseInsensitiveSearch].location;
				
				if (result != NSNotFound) {
					[self.filteredUsers addObject:friend];
				}
			}
		}
		
		self.nameSearch = YES;
		[self.captionTableView reloadData];
		self.captionTableView.hidden = (self.filteredUsers.count == 0);
	} else {
		self.captionTableView.hidden = YES;
	}
}

- (void)addTagToCache:(NSString *)tag
{
	if (!tag) return;
	
	if ([self.cachedTags containsObject:tag]) [self.cachedTags removeObject:tag];
	[self.cachedTags insertObject:tag atIndex:0];
	[NSKeyedArchiver archiveRootObject:self.cachedTags toFile:self.cachedTagsFilename];
}

- (NSArray *)extractHashtagsFromString:(NSString *)string
{
	NSCharacterSet *notAllowedChars = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
	NSMutableArray *hashtags = [NSMutableArray arrayWithCapacity:1];
	NSScanner *scanner = [NSScanner scannerWithString:string];
	
	[scanner scanUpToString:@"#" intoString:nil];
	
	while (![scanner isAtEnd]) {
		NSString *substring = nil;
		[scanner scanString:@"#" intoString:nil];
		
		if ([scanner scanUpToCharactersFromSet:notAllowedChars intoString:&substring]) {
			if (!ORIsEmpty(substring)) [hashtags addObject:[@"#" stringByAppendingString:substring]];
		}
		
		[scanner scanUpToString:@"#" intoString:nil];
	}
	
	return hashtags;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
	switch (alertView.tag) {

        case 0: // Discard Video
            if (alertView.cancelButtonIndex == buttonIndex) return;
            [self.view endEditing:YES];
            [self deleteVideo];
            break;

        case 1: // Unused
//			if (buttonIndex == alertView.firstOtherButtonIndex) {
//				[self displaySmsComposer];
//			} else if (buttonIndex == alertView.firstOtherButtonIndex + 1) {
//				[self displayEmailComposer];
//			}
			break;

		case 3: // Unused
			// Ask for Push
//            if (buttonIndex == alertView.firstOtherButtonIndex) {       // Yes
//                [AppDelegate registerForPushNotifications];
//            } else if (buttonIndex == alertView.cancelButtonIndex) {    // Don't Ask Again
//                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//                [defaults setBool:YES forKey:@"dontShowPushPermission"];
//                [defaults synchronize];
//            }
//            
//            [self.parentManager close];
            break;
            
        case 7: // Remove Twitter/Facebook posts
            if (buttonIndex == alertView.firstOtherButtonIndex) {
                if (self.video.twitterId) {
                    [self removeTwitterPost];
                }
                
                if (self.video.facebookId) {
                    [self removeFacebookPost];
                }
            }
            
            [self finishedActionAskPrivate:NO];
            break;

        case 8: // Remove FB post
            if (buttonIndex == alertView.firstOtherButtonIndex) {
                [self removeFacebookPost];
                [self setDirty];
            }
            break;
			
        case 9: // Remove TW post
            if (buttonIndex == alertView.firstOtherButtonIndex) {
                [self removeTwitterPost];
                [self setDirty];
            }
            break;
												
		default:
			break;
	}
}

#pragma mark - NS Notifications

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORVideoEncoded:) name:@"ORVideoEncoded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORLocationSelected:) name:@"ORLocationSelected" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORUploadProgress:) name:@"ORUploadProgress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORVideoUploaded:) name:@"ORVideoUploaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORVideoThumbnailUpdated:) name:@"ORVideoThumbnailUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle_ORNetworkStatusChanged:) name:@"ORNetworkStatusChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORTranscodeProgress:) name:@"ORTranscodeProgress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORTranscodeComplete:) name:@"ORTranscodeComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORTranscodeError:) name:@"ORTranscodeError" object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadContacts) name:@"ORAddressBookPaired" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORWillDisplayFindFriends:) name:@"ORWillDisplayFindFriends" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORSubscriptionStarted:) name:@"ORSubscriptionStarted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORFacebookPickerStateChanged:) name:@"ORFacebookPickerStateChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORTwitterPickerStateChanged:) name:@"ORTwitterPickerStateChanged" object:nil];
}

- (void)handleORVideoEncoded:(NSNotification *)n
{
    self.titlePlaceholder = @"Write a caption...";
	[self updateAutoTitle];
    [self videoIsReady];
}

- (void)handleORLocationSelected:(NSNotification*)n
{
	if (!n.object) {
        self.video.locationFriendlyName = nil;
        self.video.latitude = 0;
        self.video.longitude = 0;
        
        ORPopDownView *pop = [[ORPopDownView alloc] initWithTitle:@"Location Removed" subtitle:nil];
        [pop displayInView:self.view hideAfter:4.0f];
    } else {
		ORFoursquareVenue *pl = (ORFoursquareVenue*)n.object;
        self.video.locationFriendlyName = pl.name;
        self.video.locationIsCity = pl.isCity;
        
		if (self.video.latitude == 0 && self.video.longitude == 0) {
            if (!pl.location && pl.googleId) {
                __weak ORPostCaptureView *weakSelf = self;
                [[ORGoogleEngine sharedInstance] getPlaceDetailsWithPlaceId:pl.googleId completion:^(NSError *error, ORGooglePlaceDetails *details) {
                    weakSelf.video.latitude = [details.geometry.location.lat doubleValue];
                    weakSelf.video.longitude = [details.geometry.location.lng doubleValue];
                    [weakSelf reloadHashtags];
                }];
            } else {
                self.video.latitude = [pl.location.lat doubleValue];
                self.video.longitude = [pl.location.lng doubleValue];
                [self reloadHashtags];
            }
		}
        
        ORPopDownView *pop = [[ORPopDownView alloc] initWithTitle:@"Location Updated" subtitle:nil];
        [pop displayInView:self.view hideAfter:4.0f];
    }
    
    [self updateAutoTitle];
	[self setDirty];
}

- (void)handleORUploadProgress:(NSNotification *)n
{
    if (!n.object) return;
	if (self.isUploaded) return;
	
    double uploadProgress = [n.object doubleValue];
	[self updateProgressDisplay:uploadProgress];
}

- (void)handleORTranscodeProgress:(NSNotification *)n
{
    if (!n.object) return;
    
    OREpicVideo *video = n.userInfo[@"video"];
    if (!video || ![video isEqual:self.video]) return;
	
    double transcodeProgress = [n.object doubleValue];
	[self updateTranscodeDisplay:transcodeProgress];
}

- (void)handleORTranscodeComplete:(NSNotification *)n
{
    if (!n.object) return;
    
    OREpicVideo *video = n.object;
    if (!video || ![video isEqual:self.video]) return;
	
	[self updateTranscodeDisplay:1];
}

- (void)handleORTranscodeError:(NSNotification *)n
{
    if (n.object) NSLog(@"Error: %@", n.object);
    
    [[[UIAlertView alloc] initWithTitle:@"Transcoding Failed"
                                message:@"Sorry, unable to transcode the selected video."
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
    
    [self deleteVideo];
}

- (void)handleORVideoUploaded:(NSNotification *)n
{
    if (![self.video isEqual:n.object]) return;
    self.isUploaded = YES;
	[self updateProgressDisplay:1];
	
    if (CurrentUser.totalVideoCount == 1) {
		ORMessageOverlayView *vc = [[ORMessageOverlayView alloc] initWithTitle:@"Well done!"
																	   message:[NSString stringWithFormat:@"You've created your first video and it's already saved to the cloud - privately.\n\nIt is using *NO SPACE* on your phone anymore!\n\nThat's the magic of %@!!\n\nNow see how easy it is to share the video...", APP_NAME]
																   buttonTitle:@"Okay"];
		[vc presentInViewController:self completion:^{
			//
		}];
	}
}

- (void)handle_ORNetworkStatusChanged:(NSNotification *)n
{
    [self updateProgressState];
}

- (void)handleORWillDisplayFindFriends:(NSNotification *)n
{
    [self.txtTitle resignFirstResponder];
}

- (void)handleORSubscriptionStarted:(NSNotification *)n
{
    if (CurrentUser.subscriptionLevel > 0) {
		[self btnTimebombNever_TouchUpInside:self.btnTimebombNever];
    }
}

- (void)handleORFacebookPickerStateChanged:(NSNotification *)n
{
    if (self.facebookPicker.isSelected && self.videoPrivacy != OREpicVideoPrivacyPublic) {
        [self switchToPublic];
    }
    
    [self setDirty];
}

- (void)handleORTwitterPickerStateChanged:(NSNotification *)n
{
    if (self.twitterPicker.isSelected && self.videoPrivacy != OREpicVideoPrivacyPublic) {
        [self switchToPublic];
    }
    
    [self setDirty];
}

#pragma mark - UITableViewDataSource / UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.nameSearch) {
        return self.filteredUsers.count;
    } else {
        return self.filteredHashtags.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.nameSearch) {
        ORUserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"userCell"];
        if (!cell) cell = [[ORUserCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"userCell"];
        
        cell.user = self.filteredUsers[indexPath.row];
        cell.backgroundColor = (indexPath.row % 2 == 0) ? APP_COLOR_LIGHT_GREY : APP_COLOR_LIGHTER_GREY;
        cell.textLabel.textColor = [UIColor darkGrayColor];
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"hashtagCell"];
        if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"hashtagCell"];
        
        cell.textLabel.text = self.filteredHashtags[indexPath.row];
        cell.backgroundColor = (indexPath.row % 2 == 0) ? APP_COLOR_LIGHT_GREY : APP_COLOR_LIGHTER_GREY;
        cell.textLabel.textColor = [UIColor darkGrayColor];
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (self.nameSearch) {
        OREpicFriend *friend = self.filteredUsers[indexPath.row];
        NSString *name = [friend.name stringByAppendingString:@" "];
        ORRangeString *tagged = nil;
        
        if (!ORIsEmpty(name)) {
            if (self.nameRange.location < self.txtTitle.text.length) {
                tagged = [[ORRangeString alloc] initWithString:friend.userId range:NSMakeRange(self.nameRange.location, friend.name.length)];
                self.txtTitle.text = [self.txtTitle.text stringByReplacingCharactersInRange:self.nameRange withString:name];
            } else if (self.txtTitle.text) {
                tagged = [[ORRangeString alloc] initWithString:friend.userId range:NSMakeRange(self.txtTitle.text.length - 1, friend.name.length)];
                self.txtTitle.text = [self.txtTitle.text stringByAppendingString:name];
            } else {
                tagged = [[ORRangeString alloc] initWithString:friend.userId range:NSMakeRange(0, friend.name.length)];
                self.txtTitle.text = name;
            }
            
            if (tagged) {
                if (!self.taggedUsers) self.taggedUsers = [NSMutableArray arrayWithCapacity:1];
                [self.taggedUsers addObject:tagged];
            }
        }
    } else {
        NSString *hashtag = [self.filteredHashtags[indexPath.row] stringByAppendingString:@" "];

        if (!ORIsEmpty(hashtag)) {
            if (self.hashtagRange.location < self.txtTitle.text.length) {
                self.txtTitle.text = [self.txtTitle.text stringByReplacingCharactersInRange:self.hashtagRange withString:hashtag];
            } else if (self.txtTitle.text) {
                self.txtTitle.text = [self.txtTitle.text stringByAppendingString:hashtag];
            } else {
                self.txtTitle.text = hashtag;
            }
        }
    }
    
    [self applyFormattingForTextView:self.txtTitle];
    self.captionTableView.hidden = YES;
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    self.viewOverlay.alpha = 0;
    self.viewOverlay.hidden = NO;
    [self.contentView bringSubviewToFront:self.viewOverlay];
    
    CGRect f = self.viewTitle.frame;
    f.origin.x = 0;
    f.size.width = CGRectGetWidth(self.view.bounds);
    
    CGRect b = self.view.bounds;
    b.origin.y = f.origin.y;
    
    self.previousOffset = self.scrollView.contentOffset;
    
    [UIView animateWithDuration:0.25f animations:^{
        self.viewTitle.frame = f;
        [self.scrollView setContentOffset:CGPointMake(0, f.origin.y) animated:NO];
        [self.scrollView setScrollEnabled:NO];
        
        self.viewOverlay.alpha = 1.0f;
        [self updateOverlay];
    }];
    
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    CGRect f = self.viewTitle.frame;
    f.origin.x = 8.0f;
    f.size.width = CGRectGetWidth(self.view.bounds) - 16.0f;
    
    [UIView animateWithDuration:0.25f animations:^{
        [self.scrollView setContentOffset:self.previousOffset animated:NO];
        [self.scrollView setScrollEnabled:YES];
        
        self.viewTitle.frame = f;
        self.viewOverlay.alpha = 0;
    } completion:^(BOOL finished) {
        self.viewOverlay.hidden = YES;
    }];
    
    return YES;
}

- (void)updateOverlay
{
    CGRect of = self.viewOverlay.frame;
    of.origin.y = CGRectGetMaxY(self.viewTitle.frame);
    of.size.height = CGRectGetHeight(self.view.bounds) - self.viewTitle.frame.size.height - self.keyboardHeight;
    
    self.viewOverlay.frame = of;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([self.txtTitle.text isEqualToString:self.titlePlaceholder]) {
        self.txtTitle.text = @"";
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (ORIsEmpty(self.txtTitle.text)) {
        self.txtTitle.text = self.titlePlaceholder;
        self.txtTitle.textColor = [UIColor lightGrayColor];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    [self updateTaggedUsersWithRange:range replacementText:text];
    
    NSString *newString = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if (ORIsEmpty(text)) range.location--;
    
    if ([self.txtTitle.text isEqualToString:self.titlePlaceholder]) {
        self.txtTitle.text = @"";
        self.captionTableView.hidden = YES;
        return YES;
    }
    
    if ([newString rangeOfString:@"#"].location != NSNotFound) {
        NSCharacterSet *validSet = [NSCharacterSet alphanumericCharacterSet];
        
        unichar buffer[range.location + 2];
        [newString getCharacters:buffer range:NSMakeRange(0, range.location + 1)];
        
        NSRange hashtagRange = NSMakeRange(NSNotFound, 0);
        
        for (int i = range.location; i >= 0; i--) {
            if (![validSet characterIsMember:buffer[i]] && buffer[i] != '#') break;
            
            if (buffer[i] == '#') {
                hashtagRange.location = i;
                hashtagRange.length = (range.location - i) + 1;
                break;
            }
        }
        
        if (hashtagRange.location != NSNotFound) {
            self.hashtagRange = hashtagRange;
            [self searchTags:[newString substringWithRange:hashtagRange]];
            return YES;
        }
    }
    
    if ([newString rangeOfString:@"@"].location != NSNotFound) {
        NSCharacterSet *validSet = [NSCharacterSet alphanumericCharacterSet];
        
        unichar buffer[range.location + 2];
        [newString getCharacters:buffer range:NSMakeRange(0, range.location + 1)];
        
        NSRange nameRange = NSMakeRange(NSNotFound, 0);
        
        for (int i = range.location; i >= 0; i--) {
            if (![validSet characterIsMember:buffer[i]] && buffer[i] != '@') break;
            
            if (buffer[i] == '@') {
                nameRange.location = i;
                nameRange.length = (range.location - i) + 1;
                break;
            }
        }
        
        if (nameRange.location != NSNotFound) {
            self.nameRange = nameRange;
            [self searchNames:[newString substringWithRange:nameRange]];
            return YES;
        }
    }
    
    self.captionTableView.hidden = YES;
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (![self.txtTitle.text isEqualToString:self.titlePlaceholder] && !ORIsEmpty(self.txtTitle.text)) {
        self.videoName = ORIsEmpty(self.txtTitle.text) ? nil : self.txtTitle.text;
        [self applyFormattingForTextView:textView];
    } else {
        self.videoName = nil;
    }

    [self setDirty];
}

- (void)updateTaggedUsersWithRange:(NSRange)range replacementText:(NSString *)text
{
    NSMutableIndexSet *remove = [NSMutableIndexSet indexSet];
    NSUInteger idx = 0;
    
    NSRange r = NSMakeRange(range.location, MAX(range.length, 1));
    
    for (ORRangeString *string in self.taggedUsers) {
        if (NSIntersectionRange(r, string.range).length > 0) {
            [remove addIndex:idx];
        } else {
            if (range.location > string.range.location) {
                idx++;
                continue;
            }
            
            string.range = NSMakeRange(string.range.location + (text.length - range.length), string.range.length);
        }
        
        idx++;
    }
    
    if (remove.count > 0) [self.taggedUsers removeObjectsAtIndexes:remove];
}

- (void)applyFormattingForTextView:(UITextView *)textView
{
    textView.scrollEnabled = NO;
    NSRange selectedRange = textView.selectedRange;
    NSString *text = textView.text;
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text
                                                                                         attributes:@{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:18.0f],
                                                                                                      NSForegroundColorAttributeName: [UIColor darkGrayColor]}];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"#(\\w+)" options:0 error:NULL];
    NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    
    for (NSTextCheckingResult *match in matches) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:APP_COLOR_LIGHT_PURPLE range:[match rangeAtIndex:0]];
    }
    
    for (ORRangeString *string in self.taggedUsers) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:APP_COLOR_LIGHT_PURPLE range:string.range];
    }
    
    textView.attributedText = attributedString;
    textView.selectedRange = selectedRange;
    textView.scrollEnabled = YES;
}

#pragma mark - Keyboard

-(void)keyboardWillShow:(NSNotification*)notify
{
	NSDictionary* keyboardInfo = [notify userInfo];
    NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    self.keyboardHeight = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;

    [UIView animateWithDuration:[animationDuration doubleValue] animations:^{
        [self updateOverlay];
    }];
}

-(void)keyboardWillHide:(NSNotification*)notify
{
    NSDictionary* keyboardInfo = [notify userInfo];
    NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    self.keyboardHeight = 0;
    
    [UIView animateWithDuration:[animationDuration doubleValue] animations:^{
        [self updateOverlay];
    }];
}

@end
