//
//  ORBroadcastBehaviorView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 4/8/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORBroadcastBehaviorView.h"
#import "ORCaptureView.h"
#import "ORLocationPicker.h"
#import "ORHashtagPicker.h"
#import "ORTwitterTrend.h"
#import "ORFoursquareVenue.h"
#import "ORFoursquareVenueLocation.h"
#import "ORGooglePlaceDetails.h"
#import "ORGooglePlaceDetailsGeometry.h"
#import "ORGooglePlaceDetailsGeometryLocation.h"
#import "ORFacebookConnectView.h"
#import "ORTwitterConnectView.h"

@interface ORBroadcastBehaviorView () <UIAlertViewDelegate>

@property (nonatomic, strong) OREpicVideo *video;
@property (assign, nonatomic) BOOL notifyFollowers;
@property (assign, nonatomic) BOOL postTweet;
@property (assign, nonatomic) BOOL postToFacebook;
@property (assign, nonatomic) BOOL drawerIsOpen;
@property (strong, nonatomic) NSMutableOrderedSet *currentTags;
@property (nonatomic, strong) NSString *cachedTagsFilename;
@property (nonatomic, strong) NSMutableOrderedSet *cachedTags;
@property (nonatomic, strong) NSMutableOrderedSet *allHashtags;
@property (nonatomic, strong) UIAlertView *alertView;

@end

@implementation ORBroadcastBehaviorView

- (void)dealloc
{
    self.alertView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithVideo:(OREpicVideo *)video
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.video = video;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initCachedTags];
	
	self.notifyFollowers = CurrentUser.followers.count > 0;
	self.postTweet = CurrentUser.isTwitterAuthenticated;
	self.postToFacebook = CurrentUser.isFacebookAuthenticated;
    self.txtCaption.text = [self.video autoCaption];

	self.btnFb.selected = self.postToFacebook;
	self.btnTw.selected = self.postTweet;
	
    [self showLocationNotification];
    [self showCurrentHashtags];

	self.viewHost.layer.cornerRadius = 5.0f;
	self.viewHost.layer.borderWidth = 1.0f;
	self.viewHost.layer.borderColor = [UIColor whiteColor].CGColor;
	
	self.viewLocation.layer.cornerRadius = 5.0f;
	self.viewHashtags.layer.cornerRadius = 5.0f;
	self.btnSend.layer.cornerRadius = 5.0f;
	self.viewDrawer.layer.cornerRadius = 5.0f;
    
    [self reloadTags];
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORPlacesListLoaded:) name:@"ORPlacesListLoaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORHashtagsLoaded:) name:@"ORHashtagsLoaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORLocationSelected:) name:@"ORLocationSelected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORHashtagSelected:) name:@"ORHashtagSelected" object:nil];
}

#pragma mark - UI

- (IBAction)btnSend_TouchUpInside:(id)sender
{
    self.video.liveNotificationMessage = self.txtCaption.text;
    self.video.liveNotificationToFollowers = YES;
    self.video.liveNotificationToFacebook = self.postToFacebook;
    self.video.liveNotificationToTwitter = self.postTweet;
    self.video.privacy = OREpicVideoPrivacyPublic;
    
    [self.parent hideBroadcastOverlayAndMarkAsSent:YES];
}

- (IBAction)btnCancel_TouchUpInside:(id)sender
{
	if (self.drawerIsOpen) {
		[self collapseDrawer];
	} else {
		[self.parent hideBroadcastOverlayAndMarkAsSent:NO];
	}
}

- (IBAction)btnLocation_TouchUpInside:(id)sender
{
    if (!AppDelegate.isAllowedToUseLocationManager) {
        [RVC requestLocationPermissionFromUser];
    }

    ORLocationPicker *picker = [[ORLocationPicker alloc] initWithPlaces:[ORDataController sharedInstance].places selectedPlace:self.parent.selectedPlace location:AppDelegate.lastKnownLocation];
    [self.parent presentViewController:picker animated:YES completion:nil];
}

- (IBAction)btnHashtags_TouchUpInside:(id)sender
{
    ORHashtagPicker *vc = [[ORHashtagPicker alloc] init];
    [self.parent presentViewController:vc animated:YES completion:nil];
}

- (IBAction)btnFb_TouchUpInside:(id)sender
{
    self.postToFacebook = !self.postToFacebook;
    self.btnFb.selected = self.postToFacebook;
    
    if (self.postToFacebook && !CurrentUser.isFacebookAuthenticated) {
        self.alertView.delegate = nil;
        self.alertView = [[UIAlertView alloc] initWithTitle:@"Connect Facebook"
                                                    message:@"You need to connect Facebook before posting. Connect now?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
        self.alertView.tag = 10;
        [self.alertView show];
        return;
    }
}

- (IBAction)btnTw_TouchUpInside:(id)sender
{
    self.postTweet = !self.postTweet;
    self.btnTw.selected = self.postTweet;
    
    if (self.postTweet && !CurrentUser.isTwitterAuthenticated) {
        self.alertView.delegate = nil;
        self.alertView = [[UIAlertView alloc] initWithTitle:@"Connect Twitter"
                                                    message:@"You need to connect Twitter before posting. Connect now?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
        self.alertView.tag = 11;
        [self.alertView show];
        return;
    }
}

- (IBAction)btnClearHashtags_TouchUpInside:(id)sender
{
    self.currentTags = [NSMutableOrderedSet orderedSet];
    [self showCurrentHashtags];
}

- (IBAction)drawerCloseAction:(id)sender
{
	[self collapseDrawer];
}

#pragma mark - UITableViewDataSource / UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tblLocation) {
        return [ORDataController sharedInstance].places.count + 1;
    } else if (tableView == self.tblHashtags) {
        return self.allHashtags.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tblLocation) {
        if (indexPath.row == 0) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LocationCell"];
            if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LocationCell"];
            cell.textLabel.text = @"Remove Location";
            cell.textLabel.textColor = [UIColor redColor];
            return cell;
        } else {
            ORFoursquareVenue *place = [ORDataController sharedInstance].places[indexPath.row - 1];
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LocationCell"];
            if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LocationCell"];
            cell.textLabel.text = place.name;
            cell.textLabel.textColor = [UIColor blackColor];
            return cell;
        }
    } else if (tableView == self.tblHashtags) {
        NSString *tag = self.allHashtags[indexPath.row];
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HashtagCell"];
        if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"HashtagCell"];
        cell.textLabel.text = tag;
        return cell;
    }

    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (tableView == self.tblLocation) {
        if (indexPath.row == 0) {
			[self locationSelected:nil];
        } else {
            ORFoursquareVenue *place = [ORDataController sharedInstance].places[indexPath.row - 1];
            [self locationSelected:place];
        }
    } else if (tableView == self.tblHashtags) {
        NSString *tag = self.allHashtags[indexPath.row];
        [self.currentTags addObject:tag];
        
        [self showCurrentHashtags];
        [self collapseDrawer];
    }
}

#pragma mark - Custom

- (void)expandDrawer:(int)page
{
	if (self.drawerIsOpen == YES) {
		[self.viewDrawer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	}
	
	if (page == 0) {
		[self.viewDrawer addSubview:self.viewLocationDrawer];
	} else {
		[self.viewDrawer addSubview:self.viewHashtagDrawer];
	}
	
	self.drawerIsOpen = YES;
	
	[UIView animateWithDuration:0.3f delay:0.0f
						options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
					 animations:^{
//						 CGRect f1 = self.viewHost.frame;
//						 f1.origin.x = 31.0f;
//						 self.viewHost.frame = f1;
						 
						 CGRect f2 = self.viewDrawer.frame;
						 f2.origin.x = self.viewHost.frame.origin.x + self.viewHost.frame.size.width;
						 self.viewDrawer.frame = f2;
					 } completion:^(BOOL finished) {
						 //
					 }];
}

- (void)collapseDrawer
{
	[UIView animateWithDuration:0.3f delay:0.0f
						options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
					 animations:^{
//						 CGRect f1 = self.viewHost.frame;
//						 f1.origin.x = 124.0f;
//						 self.viewHost.frame = f1;
						 
						 CGRect f2 = self.viewDrawer.frame;
						 f2.origin.x = self.viewHost.frame.origin.x + self.viewHost.frame.size.width - self.viewDrawer.frame.size.width;
						 self.viewDrawer.frame = f2;
					 } completion:^(BOOL finished) {
						 [self.viewDrawer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
						 self.drawerIsOpen = NO;
					 }];
}

- (void)showLocationNotification
{
    if (self.parent.selectedPlace) {
        [self.btnLocation setTitle:self.parent.selectedPlace.name forState:UIControlStateNormal];
    } else if (!AppDelegate.isAllowedToUseLocationManager) {
        [self.btnLocation setTitle:@"Tap to Select Location" forState:UIControlStateNormal];
    } else {
        [self.btnLocation setTitle:@"(no location)" forState:UIControlStateNormal];
    }
}

- (void)showCurrentHashtags
{
    self.video.hashtags = [self.currentTags array];
    
    if (!ORIsEmpty(self.video.hashtags)) {
        [self.btnHashtags setTitle:[self.video.hashtags componentsJoinedByString:@" "] forState:UIControlStateNormal];
        self.btnClearHashtags.hidden = NO;
        self.lblHashtags.hidden = YES;
    } else {
        [self.btnHashtags setTitle:@"Select Hashtags" forState:UIControlStateNormal];
        self.btnClearHashtags.hidden = YES;
        self.lblHashtags.hidden = NO;
    }
}

#pragma mark - NSNotifications

- (void)locationSelected:(ORFoursquareVenue *)pl
{
	if (!pl) {
		if (AppDelegate.isRecording) {
			self.video.locationFriendlyName = nil;
			self.video.latitude = 0;
			self.video.longitude = 0;
		}
		
		self.parent.selectedPlace = nil;
	} else {
		self.parent.selectedPlace = pl;
		
		if (AppDelegate.isRecording) {
			self.video.locationFriendlyName = self.parent.selectedPlace.name;
            self.video.locationIsCity = self.parent.selectedPlace.isCity;
		}
		
		if (self.video.latitude == 0 && self.video.longitude == 0) {
            if (!pl.location && pl.googleId) {
                __weak OREpicVideo *video = self.video;
                [[ORGoogleEngine sharedInstance] getPlaceDetailsWithPlaceId:pl.googleId completion:^(NSError *error, ORGooglePlaceDetails *details) {
                    video.latitude = [details.geometry.location.lat doubleValue];
                    video.longitude = [details.geometry.location.lng doubleValue];
                }];
            } else {
                self.video.latitude = [pl.location.lat doubleValue];
                self.video.longitude = [pl.location.lng doubleValue];
            }
		}
	}
    
    [self showLocationNotification];
    [self collapseDrawer];
    
    if (!self.video) return;
    [[ORDataController sharedInstance] saveVideo:self.video];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORVideoModified" object:self.video];
}
         
- (void)handleORPlacesListLoaded:(NSNotification *)n
{
    [self.tblLocation reloadData];
    [self showLocationNotification];
}

- (void)handleORHashtagsLoaded:(NSNotification *)n
{
    [self reloadTags];
}

- (void)handleORLocationSelected:(NSNotification*)n
{
    if (!n.object) {
        [self.btnLocation setTitle:@"(no location)" forState:UIControlStateNormal];
        self.video.locationFriendlyName = nil;
        self.video.latitude = 0;
        self.video.longitude = 0;
    } else {
        ORFoursquareVenue *pl = (ORFoursquareVenue*)n.object;
        [self.btnLocation setTitle:pl.name forState:UIControlStateNormal];
        
        self.video.locationFriendlyName = pl.name;
        self.video.locationIsCity = pl.isCity;
        
        if (self.video.latitude == 0 && self.video.longitude == 0) {
            if (!pl.location && pl.googleId) {
                __weak ORBroadcastBehaviorView *weakSelf = self;
                [[ORGoogleEngine sharedInstance] getPlaceDetailsWithPlaceId:pl.googleId completion:^(NSError *error, ORGooglePlaceDetails *details) {
                    weakSelf.video.latitude = [details.geometry.location.lat doubleValue];
                    weakSelf.video.longitude = [details.geometry.location.lng doubleValue];
                }];
            } else {
                self.video.latitude = [pl.location.lat doubleValue];
                self.video.longitude = [pl.location.lng doubleValue];
            }
        }
    }
    
    self.txtCaption.text = [self.video autoCaption];
}

- (void)handleORHashtagSelected:(NSNotification*)n
{
    if (n.object) {
        NSString *tag = (NSString *)n.object;
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithArray:self.video.hashtags];
        if (!set) set = [NSMutableOrderedSet orderedSetWithCapacity:1];
        if (!ORIsEmpty(tag)) [set addObject:tag];
        self.video.hashtags = [set array];
    } else {
        self.video.hashtags = nil;
    }
    
    self.txtCaption.text = [self.video autoCaption];
}

#pragma mark - Hashtags

- (void)initCachedTags
{
    self.cachedTagsFilename = [[ORUtility cachesDirectory] stringByAppendingPathComponent:@"user_cache/hashtags.cache"];
    self.cachedTags = [NSKeyedUnarchiver unarchiveObjectWithFile:self.cachedTagsFilename];
    if (!self.cachedTags) self.cachedTags = [NSMutableOrderedSet orderedSetWithCapacity:1];
    
    self.currentTags = [NSMutableOrderedSet orderedSetWithArray:self.video.hashtags];
    if (!self.currentTags) self.currentTags = [NSMutableOrderedSet orderedSet];
}

- (void)reloadTags
{
    NSMutableOrderedSet *tags = [NSMutableOrderedSet orderedSetWithCapacity:self.cachedTags.count + [ORDataController sharedInstance].twitterHashtags.count];
    
    for (NSString *tag in self.cachedTags) {
        NSCharacterSet *notAllowedChars = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
        NSString *fixed = [[tag componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
        if (!ORIsEmpty(fixed)) [tags addObject:[@"#" stringByAppendingString:fixed]];
    }
    
    for (ORTwitterTrend *hashtag in [ORDataController sharedInstance].twitterHashtags) {
        if (hashtag.name) {
            NSCharacterSet *notAllowedChars = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
            NSString *fixed = [[hashtag.name componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
            if (!ORIsEmpty(fixed)) [tags addObject:[@"#" stringByAppendingString:fixed]];
        }
    }
    
    self.allHashtags = tags;
    [self.tblHashtags reloadData];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    
    if (alertView.tag == 10) {
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            [self connectFacebook];
        } else {
            self.postToFacebook = NO;
            self.btnFb.selected = NO;
        }
    } else if (alertView.tag == 11) {
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            [self connectTwitter];
        } else {
            self.postTweet = NO;
            self.btnTw.selected = NO;
        }
    }
}

- (void)connectFacebook
{
    ORFacebookConnectView *vc = [ORFacebookConnectView new];
    [vc setCompletionBlock:^(BOOL success) {
        self.postToFacebook = success;
        self.btnFb.selected = success;
        [self.parent dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [self.parent presentViewController:vc animated:YES completion:nil];
}

- (void)connectTwitter
{
    ORTwitterConnectView *vc = [ORTwitterConnectView new];
    [vc setCompletionBlock:^(BOOL success) {
        self.postTweet = success;
        self.btnTw.selected = success;
        [self.parent dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [self.parent presentViewController:vc animated:YES completion:nil];
}

@end
