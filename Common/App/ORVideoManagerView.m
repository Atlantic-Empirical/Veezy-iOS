//
//  ORVideoManagerInnerView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/27/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORVideoManagerView.h"
#import "OREpicVideo.h"
#import "ORLocationPicker.h"
#import "ORFaspPersistentEngine.h"
#import "ORTweet.h"
#import "SORelativeDateTransformer.h"
#import "ORFoursquareVenue.h"
#import "ORFoursquareVenueLocation.h"
#import "ORGooglePlaceDetails.h"
#import "ORGooglePlaceDetailsGeometry.h"
#import "ORGooglePlaceDetailsGeometryLocation.h"
#import "ORDirectSendView.h"
#import "ORMoviePlayerView.h"
#import "ORTwitterPlace.h"
#import "ORTwitterTrend.h"
#import "ORUserCell.h"
#import "ORRangeString.h"
#import "ORSubscriptionUpsell.h"
#import "ORShareActionSheet.h"
#import "ORPopDownView.h"
#import "ORWatchView.h"

@interface ORVideoManagerView () <UIAlertViewDelegate>

@property (nonatomic, readonly) UIScrollView *scrollView;
@property (strong, nonatomic) OREpicVideo* video;
@property (strong, nonatomic) NSArray *places;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, assign) BOOL isLoadingHashtags;
@property (nonatomic, strong) ORLocationPicker *locationPicker;
@property (nonatomic, strong) NSString *originalTitle;

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
@property (nonatomic, assign) BOOL videoExpired;

@property (nonatomic, assign) BOOL isDirty;
@property (nonatomic, assign) BOOL videoSaved;
@property (nonatomic, assign) BOOL videoDeleted;
@property (assign, nonatomic) BOOL videoSent;
@property (strong, nonatomic) OREpicVideo *oldVideo;

@end

@implementation ORVideoManagerView

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
    self = [super initWithNibName:@"ORVideoManagerView" bundle:nil];
    if (self) {
        _video = video;
		_places = places;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addSubview:self.contentView];
    self.scrollView.contentSize = self.contentView.frame.size;
    
    self.screenName = @"VideoManager";
	
    OREpicVideo *existing = [[ORDataController sharedInstance] pendingVideoWithId:self.video.videoId];
    if (existing) self.video = existing;
    
    [self prepareOldVideo];
	[self registerForNotifications];
    [self resetNavButtons];
    [self putVideoUrlInPasteboard];
    [self initCachedTags];
	[self getLocation];
    [self reloadHashtags];
	
	// Caption
	self.titlePlaceholder = @"Write a caption...";
	self.taggedUsers = [NSMutableArray arrayWithArray:self.video.taggedUsers];
	self.originalTitle = [self.video autoCaption];
    if (ORIsEmpty(self.video.name)) {
        self.txtTitle.text = self.titlePlaceholder;
        self.txtTitle.textColor = [UIColor lightGrayColor];
    } else {
        self.txtTitle.text = self.video.name;
        [self applyFormattingForTextView:self.txtTitle];
    }
	self.captionTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.captionTableView.backgroundColor = APP_COLOR_LIGHT_GREY;

    // Video
    if (self.video) {
        self.moviePlayer = [[ORMoviePlayerView alloc] initWithVideo:self.video];
        [self addChildViewController:self.moviePlayer];
		self.moviePlayer.isAirPlayEnabled = NO;
        self.moviePlayer.fullscreenOnly = YES;
        self.moviePlayer.view.frame = self.viewThumbHost.bounds;
        [self.viewThumbHost addSubview:self.moviePlayer.view];
        [self.moviePlayer didMoveToParentViewController:self];
        
        if (![self.video.captureSource isEqualToString:@"CameraRoll"]) {
            [self performSelector:@selector(videoIsReady) withObject:nil afterDelay:0.5f];
        }
        
        self.videoExpired = (self.video.state == OREpicVideoStateExpired);
    }
	
	// Privacy
	if (self.video.privacy == OREpicVideoPrivacyPublic) {
		self.btnPrivate.selected = NO;
		self.btnPublic.selected = YES;
		[self setIndicatorToButton:self.btnPublic];
	} else {
		self.btnPrivate.selected = YES;
		self.btnPublic.selected = NO;
		[self setIndicatorToButton:self.btnPrivate];
	}
	
	// Timebomb
	[self setTimebombStateDisplay];

	// Etc
	[self layoutSubviews];
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

#pragma mark - UI

- (IBAction)btnLocation_TouchUpInside:(id)sender
{
	[self.view endEditing:YES];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:self.video.latitude longitude:self.video.longitude];
	ORLocationPicker *vc = [[ORLocationPicker alloc] initWithPlaces:self.places selectedPlace:nil location:location];
    
	[self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)viewOverlay_TouchUpInside:(id)sender
{
    [self.txtTitle resignFirstResponder];
}

- (IBAction)btnTimebomb1hr_TouchUpInside:(UIButton*)sender
{
	self.alertView.delegate = nil;
	self.alertView = [[UIAlertView alloc] initWithTitle:@"Confirm Expiration: 1 Hour"
												message:@"Do you want this video to expire one hour from now?"
											   delegate:self
									  cancelButtonTitle:@"No"
									  otherButtonTitles:@"Yes", nil];
	self.alertView.tag = 4;
	[self.alertView show];
}

- (IBAction)btnTimebomb1day_TouchUpInside:(UIButton*)sender
{
	self.alertView.delegate = nil;
	self.alertView = [[UIAlertView alloc] initWithTitle:@"Confirm Expiration: 1 Day"
												message:@"Do you want this video to expire one day from now?"
											   delegate:self
									  cancelButtonTitle:@"No"
									  otherButtonTitles:@"Yes", nil];
	self.alertView.tag = 5;
	[self.alertView show];
}

- (IBAction)btnTimebomb1week_TouchUpInside:(UIButton*)sender
{
	self.alertView.delegate = nil;
	self.alertView = [[UIAlertView alloc] initWithTitle:@"Confirm Expiration: 1 Week"
												message:@"Do you want this video to expire one week from now?"
											   delegate:self
									  cancelButtonTitle:@"No"
									  otherButtonTitles:@"Yes", nil];
	self.alertView.tag = 6;
	[self.alertView show];
}

- (IBAction)btnTimebombNever_TouchUpInside:(UIButton*)sender
{
    if (CurrentUser.subscriptionLevel == 0) {
        [self showSubscriptionUpsell];
    } else {
        self.videoExpired = NO;
        self.video.timebombMinutes = 0;
        self.video.expirationTime = nil;
        [self setDirty];
    }
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

- (IBAction)btnRecoverVideo_TouchUpInside:(id)sender
{
    [self btnTimebombNever_TouchUpInside:self.btnTimebombNever];
}

#pragma mark - Custom

- (void)showUploadComplete:(id)sender
{
    ORPopDownView *pop = [[ORPopDownView alloc] initWithTitle:@"Video Transfer Complete"
                                                     subtitle:@"Now using zero space on your phone"];
    
    [pop displayInView:self.view hideAfter:4.0f];
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
    
    [self.view endEditing:YES];
        
    // Pre-Save
    [self prepareTags];
    
    self.oldVideo = nil;
    self.videoSaved = YES;
    [[ORDataController sharedInstance] saveVideo:self.video];
    
    self.video.cachedHeight = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORVideoModified" object:self.video];
    
    [AppDelegate.mixpanel track:@"Video Saved Post-Capture" properties:@{@"VideoId": self.video.videoId}];
    
    [self close];
}

- (void)close
{
    ORPopDownView *pop = nil;
    
    if (self.oldVideo) {
        [self revertToOldVideo];
    } else if (self.videoSaved) {
        NSString *title = nil;
        NSString *subtitle = nil;
        
        if (self.videoSent) {
            title = @"Video Sent";
            subtitle = @"";
        } else if (self.video.privacy == OREpicVideoPrivacyPublic) {
            title = @"Video Published";
            subtitle = @"";
        } else {
            title = @"Video Saved";
            subtitle = @"";
        }
        
        pop = [[ORPopDownView alloc] initWithTitle:title subtitle:subtitle];
    };
    
    if (self.navigationController.viewControllers.count > 2 && self.videoDeleted) {
        UIViewController *vc = self.navigationController.viewControllers[self.navigationController.viewControllers.count - 2];
        if ([vc isKindOfClass:[ORWatchView class]]) {
            vc = self.navigationController.viewControllers[self.navigationController.viewControllers.count - 3];
        }
        
        [self.navigationController popToViewController:vc animated:YES];
        [pop displayInView:vc.view hideAfter:4.0f];
    } else if (self.navigationController.viewControllers.count > 1) {
        UIViewController *vc = self.navigationController.viewControllers[self.navigationController.viewControllers.count - 2];
        [self.navigationController popViewControllerAnimated:YES];
        [pop displayInView:vc.view hideAfter:4.0f];
    } else if (self.presentingViewController) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            [AppDelegate unlockOrientation];
            [pop displayInView:self.presentingViewController.view hideAfter:4.0f];
        }];
    } else {
        [RVC showCamera];
        [pop displayInView:RVC.view margin:20.0f hideAfter:4.0f];
    }
}

- (void)videoIsReady
{
    [self.moviePlayer loadVideo];
}

- (void)resetNavButtons
{
    if (self.isDirty) {
        UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(finishedAction)];
        self.navigationItem.leftBarButtonItem = save;
        
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)];
        self.navigationItem.rightBarButtonItem = cancel;
    } else {
        UIBarButtonItem *delete = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(discardVideoAction)];
        self.navigationItem.rightBarButtonItem = delete;
        self.navigationItem.leftBarButtonItem = nil;
        
        [self.view endEditing:YES];
        
    }
}

- (void)putVideoUrlInPasteboard
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [self videoUrlString];
}

- (NSString *)videoUrlString
{
    NSString *theLink;
    
    if ([self.video.userId isEqualToString:CurrentUser.userId]) {
        theLink = self.video.playerUrlSelected;
    } else {
        theLink = self.video.playerUrlPublic;
    }
    return theLink;
}

- (void)prepareOldVideo
{
    self.oldVideo = [OREpicVideo new];
    
    // Save the old property values
    self.oldVideo.name = self.video.name;
    self.oldVideo.privacy = self.video.privacy;
    self.oldVideo.thumbnailIndex = self.video.thumbnailIndex;
    self.oldVideo.thumbnailURL = self.video.thumbnailURL;
    self.oldVideo.locationFriendlyName = self.video.locationFriendlyName;
    self.oldVideo.locationIsCity = self.video.locationIsCity;
    self.oldVideo.latitude = self.video.latitude;
    self.oldVideo.longitude = self.video.longitude;
    self.oldVideo.timebombMinutes = self.video.timebombMinutes;
    self.oldVideo.expirationTime = self.video.expirationTime;
}

- (void)revertToOldVideo
{
    if (self.oldVideo) {
        // Revert to old property values
        self.video.name = self.oldVideo.name;
        self.video.privacy = self.oldVideo.privacy;
        self.video.thumbnailIndex = self.oldVideo.thumbnailIndex;
        self.video.thumbnailURL = self.oldVideo.thumbnailURL;
        self.video.locationFriendlyName = self.oldVideo.locationFriendlyName;
        self.video.locationIsCity = self.oldVideo.locationIsCity;
        self.video.latitude = self.oldVideo.latitude;
        self.video.longitude = self.oldVideo.longitude;
        self.video.timebombMinutes = self.oldVideo.timebombMinutes;
        self.video.expirationTime = self.oldVideo.expirationTime;
        
        self.oldVideo = nil;
    }
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

- (void)addTimeToTimebomb:(int)minutes
{
	// 0) Fudge to make SODateTransformer output a value that won't annoy users
	minutes += 20;
	
	// 1) you need to calculate the elapsed minutes since startTime
	NSTimeInterval timeInterval = [self.video.startTime timeIntervalSinceNow];
	int elapsedMin = floorf(abs(timeInterval) / 60);
	
	// 2) add new minutes to elapsed value
	int newTimebombMin = elapsedMin + minutes;
	
	// 3) update timebombMinutes with this value
	self.video.timebombMinutes = newTimebombMin;
	
	// 4) calculate and set new expirationDate with startTime + timebombMinutes
	self.video.expirationTime = [self.video.startTime dateByAddingTimeInterval:(newTimebombMin*60)];
	
	// 5) setDirty
	[self setDirty];
}

- (void)setTimebombStateDisplay
{
	self.btnTimebomb1hr.selected = NO;
	self.btnTimebomb1day.selected = NO;
	self.btnTimebomb1week.selected = NO;
	self.btnTimebombNever.selected = NO;
	
	[UIView animateWithDuration:0.2f delay:0.0f
						options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 
						 if (self.video.timebombMinutes == 0 && !self.videoExpired) {
							 self.viewTimebombIndicator.hidden = NO;
							 CGRect f = self.viewEver.frame;
							 self.viewTimebombIndicator.frame = f;
							 self.btnTimebombNever.selected = YES;
						 } else {
							 self.viewTimebombIndicator.hidden = YES;
						 }
					 } completion:^(BOOL finished) {
						 //
					 }];

	
	self.btnRecoverVideo.hidden = YES;

    switch (self.video.state) {
        case OREpicVideoStateExpired:
            self.lblExpirationInfo.text = @"";
            self.btnRecoverVideo.hidden = NO;
            break;
            
        default: {
            if (self.video.timebombMinutes > 0) {
                SORelativeDateTransformer *rdt = [[SORelativeDateTransformer alloc] init];
                NSString *expiresStr = [rdt transformedValue:self.video.expirationTime];
                self.lblExpirationInfo.text = [NSString stringWithFormat:@"Video will expire %@.", expiresStr];
            } else {
                self.lblExpirationInfo.text = @"This video will not expire.";
            }
            
            break;
                
        }
    }
}

- (void)showSubscriptionUpsell
{
	ORSubscriptionUpsell *vc = [ORSubscriptionUpsell new];
	[self presentViewController:vc animated:YES completion:nil];
}

- (void)switchToPrivate
{
    self.btnPrivate.selected = YES;
    self.btnPublic.selected = NO;
    self.video.privacy = OREpicVideoPrivacyPrivate;
    [self setDirty];
    [self layoutSubviews];
}

- (void)switchToPublic
{
	if (CurrentUser.accountType == 3) {
        [RVC presentSignInWithMessage:@"Sign-in and share with friends." completion:^(BOOL success) {
            if (success) {
                if (![self.video.userId isEqualToString:CurrentUser.userId]) self.video.userId = CurrentUser.userId;
            } else {
				//
            }
        }];
	} else {
        self.btnPrivate.selected = NO;
        self.btnPublic.selected = YES;
		self.video.privacy = OREpicVideoPrivacyPublic;
		[self setDirty];
		[self layoutSubviews];
	}
}

- (void)setDirty
{
    if (!self.isDirty) {
        self.isDirty = YES;
        [self resetNavButtons];
    }
    
	[self setTimebombStateDisplay];
}

- (void)layoutSubviews
{
//    CGRect f = self.viewEverythingExceptProgress.frame;
//    f.size.height = CGRectGetMaxY(self.viewContactPickerParent.frame) + 10.0f;
//    f.size.height = MAX(f.size.height, self.parentManager.view.bounds.size.height);
//    self.viewEverythingExceptProgress.frame = f;
//    
//    f = self.view.frame;
//    f.size.height = CGRectGetMaxY(self.viewEverythingExceptProgress.frame);
//    self.view.frame = f;
//
//    self.parentManager.scrollerMain.contentSize = CGSizeMake(CGRectGetMaxX(f), CGRectGetMaxY(f));
}

- (void)deleteVideo
{
    OREpicVideo *video = self.video;
    self.video.state = OREpicVideoStateDeleted;
    
    // Cancel the video upload, if pending
    [[ORFaspPersistentEngine sharedInstance] cancelVideoUpload:video];
    
    if (video.videoId) {
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
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORVideoDeleted" object:video];
    self.videoDeleted = YES;
    [self close];
}

#pragma mark - Sharing

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
			__weak ORVideoManagerView *weakSelf = self;
			
			[AppDelegate.places getPlacesForLocation:location andRadiusMeters:PLACE_SEARCH_RADIUS completion:^(NSError *error, NSArray *venues) {
				if (error) DLog(@"problem getting places: %@", error.localizedDescription);
				[weakSelf innerSetPlaces:venues];
			}];
		}
	} else {
		//
	}
}

- (void)innerSetPlaces:(NSArray*)places
{
	self.places = places;
	
	if (self.places.count > 0 && !self.video.hasLocationFriendlyName) {
		ORFoursquareVenue *place = [self.places firstObject];
		self.video.locationFriendlyName = place.name;
		self.video.locationIsCity = place.isCity;
		
		if (self.video.latitude == 0 && self.video.longitude == 0) {
			self.video.latitude = [place.location.lat doubleValue];
			self.video.longitude = [place.location.lng doubleValue];
			[self reloadHashtags];
		}
	} else if (!self.video.hasLocationFriendlyName && self.video.latitude != 0 && self.video.longitude != 0) {
		//
	} else {
		//
	}
}

- (void)updateAutoTitle
{
	if (ORIsEmpty(self.txtTitle.text) || [self.txtTitle.text isEqualToString:self.titlePlaceholder] || [self.txtTitle.text isEqualToString:self.originalTitle]) {
		self.txtTitle.text = [self.video autoCaption];
		self.originalTitle = self.txtTitle.text;
	}
	
	[self applyFormattingForTextView:self.txtTitle];
}

#pragma mark - Tags

- (void)prepareTags
{
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
		
		__weak ORVideoManagerView *weakSelf = self;
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
	__weak ORVideoManagerView *weakSelf = self;
	
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

        case 1: // not used
			break;
			
		case 2: // not used
			// Video Expired
//            if (buttonIndex == alertView.firstOtherButtonIndex) {
//                [self btnTimebombNever_TouchUpInside:self.btnTimebombNever];
//            } else {
//                [self.parentManager close];
//            }
            break;
			
		case 3: // not used
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

		case 4: // Set to 1h timebomb
			if (buttonIndex == alertView.firstOtherButtonIndex) {       // Yes
				[self addTimeToTimebomb:60];
			} else if (buttonIndex == alertView.cancelButtonIndex) {
			}
			break;

		case 5: // Set to 1d timebomb
			if (buttonIndex == alertView.firstOtherButtonIndex) {       // Yes
				[self addTimeToTimebomb:1440];
			} else if (buttonIndex == alertView.cancelButtonIndex) {
			}
			break;

		case 6: // Set to 1w timebomb
			if (buttonIndex == alertView.firstOtherButtonIndex) {       // Yes
				[self addTimeToTimebomb:10080];
			} else if (buttonIndex == alertView.cancelButtonIndex) {
			}
			break;

		case 8: // not used
			// Remove FB post
//            if (buttonIndex == alertView.firstOtherButtonIndex) {
//                [self removeFacebookPost];
//                [self setDirty];
//            }
            break;
			
		case 9: // not used
			// Remove TW post
//            if (buttonIndex == alertView.firstOtherButtonIndex) {
//                [self removeTwitterPost];
//                [self setDirty];
//            }
            break;
			
		case 12: // not used
			// Make Video Public
//            if (buttonIndex == alertView.firstOtherButtonIndex) {
//				[self switchToPublic];
//            } else {
//				[self switchToPrivate];
//            }
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORVideoUploaded:) name:@"ORVideoUploaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORLocationSelected:) name:@"ORLocationSelected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORThumbnailSelected:) name:@"ORThumbnailSelected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORVideoThumbnailUpdated:) name:@"ORVideoThumbnailUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORWillDisplayFindFriends:) name:@"ORWillDisplayFindFriends" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORSubscriptionStarted:) name:@"ORSubscriptionStarted" object:nil];
}

- (void)handleORVideoUploaded:(NSNotification*)n
{
    [self showUploadComplete:self];
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
                __weak ORVideoManagerView *weakSelf = self;
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

- (void)handleORWillDisplayFindFriends:(NSNotification *)n
{
    [self.txtTitle resignFirstResponder];
}

- (void)handleORSubscriptionStarted:(NSNotification *)n
{
    if (CurrentUser.subscriptionLevel > 0) {
        [self btnTimebombNever_TouchUpInside:self.btnTimebombNever];
    }
	[self setTimebombStateDisplay];
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
    f.origin.x = 6.0f;
    f.size.width = CGRectGetWidth(self.view.bounds) - 12.0f;
    
    [UIView animateWithDuration:0.25f animations:^{
        [self.scrollView setContentOffset:self.previousOffset animated:NO];
        [self.scrollView setScrollEnabled:YES];
        
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
    of.size.height = CGRectGetHeight(self.view.bounds) - self.viewTitle.frame.size.height - self.keyboardHeight + RVC.bottomMargin;
    
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
    if (![self.txtTitle.text isEqualToString:self.titlePlaceholder]) {
        self.video.name = ORIsEmpty(self.txtTitle.text) ? nil : self.txtTitle.text;
        [self applyFormattingForTextView:textView];
    } else {
        self.video.name = nil;
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
                                                                                         attributes:@{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:15.0f],
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
