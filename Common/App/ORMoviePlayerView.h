//
//  ORMoviePlayerView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 23/07/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ORMoviePlayerViewDelegate;

@interface ORMoviePlayerView : UIViewController

@property (nonatomic, weak) IBOutlet UIImageView *imgThumbnail;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *aiLoading;
@property (nonatomic, weak) IBOutlet UIButton *btnPlay;
@property (weak, nonatomic) IBOutlet UIView *viewAirPlayHost;

- (IBAction)btnPlay_TouchUpInside:(id)sender;
- (id)initWithVideo:(OREpicVideo *)video;

@property (nonatomic, weak) id<ORMoviePlayerViewDelegate> delegate;
@property (nonatomic, assign) BOOL isLocalPlayback;
@property (nonatomic, assign) BOOL isAirPlayEnabled;
@property (nonatomic, assign) BOOL fullscreenOnly;

- (void)play;
- (void)stop;
- (void)softPause;
- (void)hardPause;
- (void)unpause;
- (void)loadVideo;
- (void)unloadVideo;
- (void)setFullscreen:(BOOL)fullscreen;

@end

@protocol ORMoviePlayerViewDelegate <NSObject>

- (void)moviePlayerWillStartPlaying:(ORMoviePlayerView *)moviePlayer;
- (void)moviePlayerDidStartPlaying:(ORMoviePlayerView *)moviePlayer;
- (void)moviePlayerDidFinishPlaying:(ORMoviePlayerView *)moviePlayer;
- (void)moviePlayerDidFailPlaying:(ORMoviePlayerView *)moviePlayer;
- (void)moviePlayerDidExitFullscreen:(ORMoviePlayerView *)moviePlayer;

@end
