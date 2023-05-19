//
//  ORMoviePlayerView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 23/07/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORMoviePlayerView.h"
#import "ORFaspPersistentEngine.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ORMoviePlayerView () <UIAlertViewDelegate>

@property (nonatomic, strong) MPMoviePlayerController *player;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) NSURL *urlToUse;
@property (nonatomic, strong) OREpicVideo *video;
@property (nonatomic, assign) BOOL playbackStartedSuccessfully;
@property (nonatomic, assign) BOOL startedLocalServer;

@end

@implementation ORMoviePlayerView

- (void)dealloc
{
    if (self.player) {
        float percentViewed = self.player.currentPlaybackTime / self.video.duration;
        if (percentViewed == 0 && self.playbackStartedSuccessfully) percentViewed = 100.0f;
        [AppDelegate.mixpanel track:@"Video Watched" properties:@{@"VideoId": self.video.videoId,
                                                                  @"Percent Viewed": [NSString stringWithFormat:@"%f", percentViewed]}];
    }
    
    self.alertView.delegate = nil;
    
    [self deregisterFromPlayerNotifications:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.player stop];
    [self.player.view removeFromSuperview];
    
    if (self.startedLocalServer) {
        [AppDelegate stopServerForVideo:self.video.videoId];
        self.startedLocalServer = NO;
    }
    
    if (self.video.uploadFinished) {
        // Upload for this video finished while player active, delete local files
        [[ORFaspPersistentEngine sharedInstance] cleanOrphanDirectories];
    }
}

- (id)initWithVideo:(OREpicVideo *)video
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.video = video;
	
	self.isAirPlayEnabled = YES;
	
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORVideoUploaded:) name:@"ORVideoUploaded" object:nil];
    
    self.isLocalPlayback = NO;
    self.btnPlay.hidden = YES;
    self.aiLoading.color = APP_COLOR_PRIMARY;
    [self.aiLoading startAnimating];
    
    if (self.video) [self loadThumbnail];

}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (self.view.frame.size.width < 100.0f) {
        [self.btnPlay setImage:[UIImage imageNamed:@"play-icon-24x"] forState:UIControlStateNormal];
    }
}

#pragma mark - Playback

- (void)loadVideo
{
	self.btnPlay.hidden = NO;
	[self.aiLoading stopAnimating];
	
	[self prepareLocalServerIfAvailable];
}

- (void)prepareLocalServerIfAvailable
{
	if (![self.video.userId isEqualToString:CurrentUser.userId]) return; // Can only local play own videos
	
	NetworkStatus status = ApiEngine.currentNetworkStatus;
	
	NSString *ipAddress = (status == ReachableViaWiFi && self.isAirPlayEnabled) ? [ORUtility getWifiIPAddress] : @"127.0.0.1";
	NSLog(@"ipAddress: %@", ipAddress);
	
	NSString *videoPath = [[ORUtility documentsDirectory] stringByAppendingPathComponent:self.video.videoId];
	NSString *playlistPath = [videoPath stringByAppendingPathComponent:VIDEO_PLAYLIST_FILE];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:playlistPath]) {
		[ORLoggingEngine logEvent:@"ORMoviePlayerView" video:self.video.videoId msg:@"Found local path: %@", playlistPath];
		
		self.startedLocalServer = [AppDelegate startServerForVideo:self.video.videoId];
		self.urlToUse = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:8080/%@", ipAddress, VIDEO_PLAYLIST_FILE]];
		self.isLocalPlayback = YES;
	} else if ([self.video.captureSource isEqualToString:@"CameraRoll"]) {
		NSString *file = [VIDEO_PLAYLIST_FILE stringByReplacingOccurrencesOfString:@".m3u8" withString:@".mp4"];
		playlistPath = [videoPath stringByAppendingPathComponent:file];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:playlistPath]) {
			self.startedLocalServer = [AppDelegate startServerForVideo:self.video.videoId];
			self.urlToUse = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:8080/%@", ipAddress, file]];
			self.isLocalPlayback = YES;
		}
	}
		
//	if (status == ReachableViaWWAN || !self.isAirPlayEnabled) {
//		
//		// We're on mobile network and it is user's own video - see if we have a local file
//	} else {
//		// We're on Wifi (or a bad state) & AirPlay is enabled & so AirPlay is possibly, so we must force playback from remote server
//		// to avoid the bug where airplay video won't start for 127 IP address video
//	}
}

- (void)initializePlayback
{
    [self.aiLoading startAnimating];
    [self.delegate moviePlayerWillStartPlaying:self];
    self.btnPlay.hidden = YES;
    
    if (self.isLocalPlayback) {
        NSLog(@"Loading local video with URL: %@", self.urlToUse);
        [self loadVideoAndPlay];
        
        return;
    } else {
        self.urlToUse = [NSURL URLWithString:self.video.playlistURL];
        NSLog(@"Loading remote video with URL: %@", self.urlToUse);
    }
    
    if (!self.urlToUse) {
        self.alertView.delegate = nil;
        self.alertView = [[UIAlertView alloc] initWithTitle:APP_NAME
                                                    message:@"Unable to load the video right now. Please try again later."
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
        self.alertView.tag = 0;
        [self.alertView show];
        return;
    }
    
    if (ApiEngine.currentNetworkStatus == NotReachable) {
        self.alertView.delegate = nil;
        self.alertView = [[UIAlertView alloc] initWithTitle:APP_NAME
                                                    message:@"Unable to play video without an internet connection."
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
        self.alertView.tag = 0;
        [self.alertView show];
        return;
    }
    
    __weak ORMoviePlayerView *weakSelf = self;
    
	[ApiEngine fileAccessibleAtUrlString:self.urlToUse.absoluteString cb:^(NSError *error, BOOL result) {
        if (!error && !result) {
            [weakSelf tryAlternativeURL];
        } else if (error) {
            weakSelf.alertView.delegate = nil;
			weakSelf.alertView = [[UIAlertView alloc] initWithTitle:APP_NAME
															message:@"Unable to load the video right now. Please try again later."
														   delegate:weakSelf
												  cancelButtonTitle:@"Ok"
												  otherButtonTitles:nil];
            weakSelf.alertView.tag = 0;
			[weakSelf.alertView show];
        } else {
            [weakSelf loadVideoAndPlay];
		}
	}];
}

- (void)tryAlternativeURL
{
	self.urlToUse = [NSURL URLWithString:[self.video.playlistURL stringByReplacingOccurrencesOfString:@".m3u8" withString:@".mp4"]];
	NSLog(@"Loading remote video with URL: %@", self.urlToUse);
    
    if (!self.urlToUse) {
        self.alertView.delegate = nil;
        self.alertView = [[UIAlertView alloc] initWithTitle:APP_NAME
                                                    message:@"Unable to load the video right now. Please try again later."
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
        self.alertView.tag = 0;
        [self.alertView show];
        return;
    }
    
    __weak ORMoviePlayerView *weakSelf = self;
	
	[ApiEngine fileAccessibleAtUrlString:self.urlToUse.absoluteString cb:^(NSError *error, BOOL result) {
        if (!error && !result) {
            weakSelf.alertView.delegate = nil;
			weakSelf.alertView = [[UIAlertView alloc] initWithTitle:APP_NAME
															message:@"This video is no longer available."
														   delegate:weakSelf
												  cancelButtonTitle:@"Ok"
												  otherButtonTitles:nil];
            weakSelf.alertView.tag = 0;
			[weakSelf.alertView show];
        } else if (error) {
            weakSelf.alertView.delegate = nil;
			weakSelf.alertView = [[UIAlertView alloc] initWithTitle:APP_NAME
															message:@"Unable to load the video right now. Please try again later."
														   delegate:weakSelf
												  cancelButtonTitle:@"Ok"
												  otherButtonTitles:nil];
            weakSelf.alertView.tag = 0;
			[weakSelf.alertView show];
        } else {
            [weakSelf loadVideoAndPlay];
		}
	}];
}

- (void)loadVideoAndPlay
{
    if (self.fullscreenOnly) {
        [self.aiLoading stopAnimating];
        self.btnPlay.hidden = NO;

        MPMoviePlayerViewController *vc = [[MPMoviePlayerViewController alloc] initWithContentURL:self.urlToUse];
        vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:vc animated:YES completion:nil];
        return;
    }

	self.player = [[MPMoviePlayerController alloc] initWithContentURL:self.urlToUse];
    [self registerForPlayerNotifications:self];

    self.player.allowsAirPlay = self.isAirPlayEnabled;
    [self.player prepareToPlay];
    
	self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.player.view.frame = self.imgThumbnail.bounds;
	
	if (self.isAirPlayEnabled) {
		// Add AirPlay Picker to the player
		MPVolumeView *volumeView = [MPVolumeView new];
		volumeView.showsVolumeSlider = NO;
		volumeView.showsRouteButton = YES;
		[self.viewAirPlayHost addSubview:volumeView];
		volumeView.frame = self.viewAirPlayHost.bounds;
	}

	[self.imgThumbnail addSubview:self.player.view];
    
    [self.player play];
}

- (void)setFullscreen:(BOOL)fullscreen
{
	[self.player setFullscreen:fullscreen animated:YES];
}

#pragma mark - Player Notifications

- (void)registerForPlayerNotifications:(id)observer
{
	[[NSNotificationCenter defaultCenter] addObserver:observer
											 selector:@selector(nowPlayingMovieDidChange:)
												 name:MPMoviePlayerNowPlayingMovieDidChangeNotification
											   object:self.player];
    
    [[NSNotificationCenter defaultCenter] addObserver:observer
											 selector:@selector(loadStateDidChange:)
												 name:MPMoviePlayerLoadStateDidChangeNotification
											   object:self.player];
    
	[[NSNotificationCenter defaultCenter] addObserver:observer
											 selector:@selector(playbackStateDidChange:)
												 name:MPMoviePlayerPlaybackStateDidChangeNotification
											   object:self.player];
	
	[[NSNotificationCenter defaultCenter] addObserver:observer
											 selector:@selector(playbackDidFinish:)
												 name:MPMoviePlayerPlaybackDidFinishNotification
											   object:self.player];
	
	[[NSNotificationCenter defaultCenter] addObserver:observer
											 selector:@selector(didExitFullscreen:)
												 name:MPMoviePlayerDidExitFullscreenNotification
											   object:self.player];
    
	[[NSNotificationCenter defaultCenter] addObserver:observer
											 selector:@selector(readyForDisplayDidChange:)
												 name:MPMoviePlayerReadyForDisplayDidChangeNotification
											   object:self.player];
	
	[[NSNotificationCenter defaultCenter] addObserver:observer
											 selector:@selector(isAirPlayVideoActiveDidChange:)
												 name:MPMoviePlayerIsAirPlayVideoActiveDidChangeNotification
											   object:self.player];

	
	
}

- (void)deregisterFromPlayerNotifications:(id)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:MPMoviePlayerNowPlayingMovieDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:MPMoviePlayerDidExitFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:MPMoviePlayerReadyForDisplayDidChangeNotification object:nil];
}

- (void)isAirPlayVideoActiveDidChange:(NSNotification*)notification
{
	DLog(@"AirPlay is active: %@", ORStringFromBOOL(self.player.airPlayVideoActive));
	if (self.player.airPlayVideoActive) {
		
//		if (self.isLocalPlayback) {
//			[self stop];
//			self.isLocalPlayback = NO;
//			[self initializePlayback];
//		} else {
			[self.aiLoading stopAnimating];
			[ [UIApplication sharedApplication] beginReceivingRemoteControlEvents];
			[self becomeFirstResponder];
//		}
	} else {
		[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
		[self resignFirstResponder];
	}
}

- (void)nowPlayingMovieDidChange:(NSNotification*)notification
{
    if (![self.video.userId isEqualToString:CurrentUser.userId]) {
        self.video.viewCount++;
        if (!self.video.viewed) {
            self.video.uniqueViewCount++;
            self.video.viewed = YES;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORVideoViewed" object:nil];
        }
    }
    
    [ApiEngine video:self.video.videoId newEvent:OREpicVideoEventStart completion:^(NSError *error, BOOL result) {
    }];
}

- (void)playbackStateDidChange:(NSNotification*)notification
{
	switch (self.player.playbackState) {
		case MPMoviePlaybackStateStopped:
            [self.delegate moviePlayerDidFinishPlaying:self];
			self.btnPlay.hidden = NO;
            NSLog(@"MPMoviePlaybackStateStopped");
			break;
			
		case MPMoviePlaybackStatePaused:
			NSLog(@"MPMoviePlaybackStatePaused");
            [self.aiLoading stopAnimating];
			break;
			
		case MPMoviePlaybackStatePlaying:
			NSLog(@"MPMoviePlaybackStatePlaying");
			break;
			
		case MPMoviePlaybackStateSeekingBackward:
			NSLog(@"MPMoviePlaybackStateSeekingBackward");
			break;
			
		case MPMoviePlaybackStateSeekingForward:
			NSLog(@"MPMoviePlaybackStateSeekingForward");
			break;
			
		case MPMoviePlaybackStateInterrupted:
            NSLog(@"MPMoviePlaybackStateInterrupted");
			break;
	}
}

- (void)loadStateDidChange:(NSNotification *)n
{
    switch (self.player.loadState) {
        case MPMovieLoadStateUnknown:
            NSLog(@"MPMovieLoadStateUnknown");
            break;
        case MPMovieLoadStatePlayable:
            NSLog(@"MPMovieLoadStatePlayable");
            break;
        case MPMovieLoadStatePlaythroughOK:
            NSLog(@"MPMovieLoadStatePlaythroughOK");
            [self.aiLoading stopAnimating];
            break;
        case MPMovieLoadStateStalled:
            NSLog(@"MPMovieLoadStateStalled");
            break;
    }
}

- (void)readyForDisplayDidChange:(NSNotification *)n
{
    NSLog(@"Ready for Display: %d", self.player.readyForDisplay);
    
    if (self.player.readyForDisplay) {
        [self.delegate moviePlayerDidStartPlaying:self];
        self.playbackStartedSuccessfully = YES;
        [self.aiLoading stopAnimating];
    }
}

- (void)playbackDidFinish:(NSNotification*)notification
{
	int reason = [[notification.userInfo valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
	
	switch (reason) {
			
		case MPMovieFinishReasonPlaybackEnded:
			break;
			
		case MPMovieFinishReasonUserExited:
			//user hit the done button
			break;
			
		case MPMovieFinishReasonPlaybackError: {
			NSError *error = [notification.userInfo valueForKey:@"error"];
            
            if (self.isLocalPlayback) {
                [ORLoggingEngine logEvent:@"ORMoviePlayerView" video:self.video.videoId msg:@"Local playback failed: %@", error.localizedDescription];
            }

			break;
		}
			
		default:
			break;
	}
    
    [self unloadVideo];
    
    [ApiEngine video:self.video.videoId newEvent:OREpicVideoEventFinish completion:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
    }];
}

- (void)didExitFullscreen:(NSNotification *)n
{
    [self.delegate moviePlayerDidExitFullscreen:self];

//    [self.player pause];
//    [self.aiLoading stopAnimating];
//    self.btnPlay.hidden = NO;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    [self.delegate moviePlayerDidFailPlaying:self];
}

#pragma mark - UI

- (void)btnPlay_TouchUpInside:(id)sender
{
    if (!self.player) {
        [self initializePlayback];
    } else {
		//        [self.player setFullscreen:YES animated:YES];
        [self unpause];
    }
}

#pragma mark - Transport Commands

- (void)play
{
    if (self.player) {
        [self registerForPlayerNotifications:self];
        [self.player play];
    }
}

- (void)stop
{
    if (self.player) {
        [self.player pause];
        [self deregisterFromPlayerNotifications:self];
    }
}

- (void)unloadVideo
{
    [self.player pause];
    [self deregisterFromPlayerNotifications:self];
    [self.player.view removeFromSuperview];
    self.player = nil;
    
    [self.delegate moviePlayerDidFinishPlaying:self];
    [self.aiLoading stopAnimating];
    self.btnPlay.hidden = NO;
}

// will not pause if currently on AirPlay
- (void)softPause
{
	if (self.player.isAirPlayVideoActive) return;
	
	if (self.player.playbackState == MPMoviePlaybackStatePlaying) {
		[self.player pause];
	}
}

// will pause regardless of AirPlay state
- (void)hardPause
{
	if (self.player.playbackState == MPMoviePlaybackStatePlaying) {
		[self.player pause];
    }
}

- (void)unpause
{
	if (self.player.playbackState == MPMoviePlaybackStatePaused || self.player.playbackState == MPMoviePlaybackStateStopped) {
		[self.player play];
    }
}

- (void)playPauseToggle
{
	if (self.player.playbackState == MPMoviePlaybackStatePlaying) {
		[self.player pause];
	} else {
		[self.player play];
	}
}

#pragma mark - Custom

- (void)loadThumbnail
{
	NSString *local = nil;
	
	if ([self.video.userId isEqualToString:CurrentUser.userId]) {
		NSString *file = [NSString stringWithFormat:VIDEO_THUMBNAIL_FORMAT, self.video.thumbnailIndex];
		local = [[ORUtility documentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", self.video.videoId, file]];
	}
	
	if (local && [[NSFileManager defaultManager] fileExistsAtPath:local]) {
		UIImage *thumb = [UIImage imageWithContentsOfFile:local];
		[self.imgThumbnail setImage:thumb];
	} else {
		if (self.video.thumbnailURL && ![self.video.thumbnailURL isEqualToString:@""]) {
			NSURL *url = [NSURL URLWithString:self.video.thumbnailURL];
			__weak ORMoviePlayerView *weakSelf = self;
			__weak OREpicVideo *weakVideo = self.video;
			
			[self.imgThumbnail setImage:nil];
			
			[[ORCachedEngine sharedInstance] imageAtURL:url size:((UIImageView *)self.imgThumbnail).frame.size fill:NO maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
				if (error) {
					NSLog(@"Error: %@", error);
					
					if ([weakSelf.video isEqual:weakVideo]) {
						[weakSelf.imgThumbnail setImage:[UIImage imageNamed:@"video"]]; // put default in place
					}
				} else if (image && [weakSelf.video isEqual:weakVideo]) {
					[weakSelf.imgThumbnail setImage:image];
				}
			}];
		} else {
			[self.imgThumbnail setImage:[UIImage imageNamed:@"video"]]; // put default in place
		}
	}
}

#pragma mark - NSNotifications

- (void)handleORVideoUploaded:(NSNotification *)n
{
	if (![self.video isEqual:n.object]) return;
	if (!self.video.uploadFinished) self.video.uploadFinished = YES;
}

#pragma mark - Remote Control Commands

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
	if (receivedEvent.type == UIEventTypeRemoteControl) {
		
		switch (receivedEvent.subtype) {
				
			case UIEventSubtypeRemoteControlTogglePlayPause:
				[self playPauseToggle];
				break;

			case UIEventSubtypeRemoteControlPause:
				[self hardPause];
				break;
				
			case UIEventSubtypeRemoteControlPlay:
				[self play];
				break;
				
			case UIEventSubtypeRemoteControlStop:
				[self stop];
				break;

			case UIEventSubtypeRemoteControlBeginSeekingForward:
				[self.player beginSeekingForward];
				break;
				
			case UIEventSubtypeRemoteControlBeginSeekingBackward:
				[self.player beginSeekingBackward];
				break;

			case UIEventSubtypeRemoteControlEndSeekingForward:
			case UIEventSubtypeRemoteControlEndSeekingBackward:
				[self.player endSeeking];
				break;
				
			case UIEventSubtypeNone:
			case UIEventSubtypeMotionShake:
			case UIEventSubtypeRemoteControlPreviousTrack:
			case UIEventSubtypeRemoteControlNextTrack:
				// N/A
				break;
				
		}
		
	}
}

@end
