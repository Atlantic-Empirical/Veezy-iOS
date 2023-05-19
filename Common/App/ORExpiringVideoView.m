//
//  ORExipiringVideoView.m
//  Veezy
//
//  Created by Thomas Purnell-Fisher on 10/27/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORExpiringVideoView.h"
#import "ORSubscriptionUpsell.h"
#import "ORWatchView.h"
#import "ORFaspPersistentEngine.h"
#import "SORelativeDateTransformer.h"

@interface ORExpiringVideoView () < UIAlertViewDelegate>

@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) OREpicVideo *video;
@property (nonatomic, strong) UIAlertView *alertView;

@end

@implementation ORExpiringVideoView

- (void)dealloc
{
    self.alertView.delegate = nil;
}

- (id)initWithVideoId:(NSString *)videoId
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.videoId = videoId;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.screenName = @"ExpiringVideo";
    self.title = @"Video Expiring";
    
    if (!ORIsEmpty(self.videoId)) {
        __weak ORExpiringVideoView *weakSelf = self;
        self.viewLoading.hidden = NO;
        
        [ApiEngine videoWithId:self.videoId completion:^(NSError *error, OREpicVideo *video) {
            if (error) NSLog(@"Error: %@", error);
            if (!weakSelf) return;
            
            if (!video) {
                weakSelf.alertView.delegate = nil;
                weakSelf.alertView = [[UIAlertView alloc] initWithTitle:APP_NAME
                                                                message:@"This video is no longer available."
                                                               delegate:weakSelf
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
                weakSelf.alertView.tag = 0;
                [weakSelf.alertView show];
            } else {
                weakSelf.video = video;
                [weakSelf loadVideoData];
            }
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    if (CurrentUser.subscriptionLevel > 0 && self.video) {
        [self close];
    }
}

#pragma mark - UI

- (IBAction)btnSubscribe_TouchUpInside:(id)sender
{
	if (CurrentUser.subscriptionLevel > 0) {
		[[ORDataController sharedInstance] saveVideo:self.video];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ORVideoModified" object:self.video];
		[self close];
	} else {
		[self showSubscriptionUpsell];
	}
}

- (IBAction)btnOpenVideo_TouchUpInside:(id)sender
{
	OREpicVideo *video = self.video;
	
	[self dismissViewControllerAnimated:YES completion:^{
		ORWatchView *vc = [[ORWatchView alloc] initWithVideo:video];
		[RVC pushToMainViewController:vc completion:nil];
	}];
}

- (IBAction)btnIgnore_TouchUpInside:(id)sender
{
	[self close];
}

- (IBAction)btnDelete_TouchUpInside:(id)sender
{
	self.alertView = [[UIAlertView alloc] initWithTitle:@"Discard this video?"
												message:[NSString stringWithFormat:@"This cannot be undone."]
											   delegate:self
									  cancelButtonTitle:@"Cancel"
									  otherButtonTitles:@"Discard", nil];
	self.alertView.tag = 9;
	[self.alertView show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
	
    switch (alertView.tag) {
        case 0: // Video unplayable
            [self close];
            break;
        case 9: // Delete Video
            if (buttonIndex == alertView.cancelButtonIndex) return;
            [self deleteVideo];
        default:
            break;
    }
}

#pragma mark - Custom

- (void)close
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadVideoData
{
    self.lblTitle.text = [self.video autoTitle];
    self.lblViewCount.text = [NSString stringWithFormat:@"%d views", self.video.viewCount];
    
    [self.imgThumb setImage:[UIImage imageNamed:@"video"]]; // put default in place
    
    if (self.video.thumbnailURL && ![self.video.thumbnailURL isEqualToString:@""]) {
        NSString *local = nil;
        
        if ([self.video.userId isEqualToString:CurrentUser.userId]) {
            NSString *file = [NSString stringWithFormat:VIDEO_THUMBNAIL_FORMAT, self.video.thumbnailIndex];
            local = [[ORUtility documentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", self.video.videoId, file]];
        }
        
        if (local && [[NSFileManager defaultManager] fileExistsAtPath:local]) {
            UIImage *thumb = [UIImage imageWithContentsOfFile:local];
            [self.imgThumb setImage:thumb];
        } else {
            NSURL *url = [NSURL URLWithString:self.video.thumbnailURL];
            __weak ORExpiringVideoView *weakSelf = self;
            __weak OREpicVideo *weakVideo = self.video;
            
            [self.imgThumb setImage:nil];
            
            [[ORCachedEngine sharedInstance] imageAtURL:url size:((UIImageView *)self.imgThumb).frame.size fill:NO maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
                if (error) {
                    NSLog(@"Error: %@", error);
                } else if (image && [weakSelf.video isEqual:weakVideo]) {
                    [weakSelf.imgThumb setImage:image];
                }
            }];
        }
    }
	
	if (self.video.timebombMinutes > 0) {
		switch (self.video.state) {
			case OREpicVideoStateExpired:
				self.lblExpirationInfo.text = @"";
				break;
				
			default: {
				SORelativeDateTransformer *rdt = [[SORelativeDateTransformer alloc] init];
				NSString *expiresStr = [rdt transformedValue:self.video.expirationTime];
				self.lblExpirationInfo.text = [NSString stringWithFormat:@"Video will expire %@.", expiresStr];
				break;
			}
		}
	} else {
		self.lblExpirationInfo.text = @"This video will not expire.";
	}
	
    self.viewLoading.hidden = YES;
}

- (void)showSubscriptionUpsell
{
    ORSubscriptionUpsell *upsell = [[ORSubscriptionUpsell alloc] init];
    [self presentViewController:upsell animated:YES completion:nil];
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
    [self close];
}

@end
