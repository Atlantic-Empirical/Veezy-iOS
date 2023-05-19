//
//  ORPendingVideosView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 29/04/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORPendingVideosView.h"
#import "ORFaspPersistentEngine.h"
#import "ORUserProfileView.h"

@interface ORPendingVideosView ()

@property (nonatomic, assign) NSUInteger pendingVideosCount;

@end

@implementation ORPendingVideosView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORUploadProgress:) name:@"ORUploadProgress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle_ORNetworkStatusChanged:) name:@"ORNetworkStatusChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle_ORPendingVideosUpdated:) name:@"ORPendingVideosUpdated" object:nil];
    
    self.lblTitle.text = @"";
    self.lblSubtitle.text = @"";
    self.btnClose.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self refreshPendingVideos];
}

- (void)handleORUploadProgress:(NSNotification *)n
{
    double uploadProgress = [n.object doubleValue] * 100;
    
    if (uploadProgress == 100) {
        self.lblSubtitle.text = @"Upload Complete";
    } else if (uploadProgress > 0) {
        self.lblSubtitle.text = [NSString stringWithFormat:@"%d%% complete", (int)ceilf(uploadProgress)];
    }
}

- (void)handle_ORNetworkStatusChanged:(NSNotification *)n
{
    [self updateState];
}

- (void)handle_ORPendingVideosUpdated:(NSNotification *)n
{
    [self refreshPendingVideos];
}

- (void)refreshPendingVideos
{
    NSArray *pending = [[ORFaspPersistentEngine sharedInstance] allPendingVideos];
    self.pendingVideosCount = pending.count;
    [self updateState];
}

- (void)updateState
{
    if (ApiEngine.currentNetworkStatus == NotReachable) {
        self.lblTitle.text = [NSString stringWithFormat:@"%@ pending", [self videosTitleForCount:self.pendingVideosCount]];
        self.lblSubtitle.text = @"Waiting for network...";
    } else if (![[ORFaspPersistentEngine sharedInstance] canUploadNow]) {
        self.lblTitle.text = [NSString stringWithFormat:@"%@ pending", [self videosTitleForCount:self.pendingVideosCount]];
        self.lblSubtitle.text = @"Waiting for Wi-Fi...";
    } else {
        self.lblTitle.text = [NSString stringWithFormat:@"%@ uploading", [self videosTitleForCount:self.pendingVideosCount]];
        self.lblSubtitle.text = @"Preparing upload...";
    }
    
    if (self.pendingVideosCount > 0) {
        [RVC showPendingVideos];
    } else {
        [RVC hidePendingVideos];
    }
}

- (NSString *)videosTitleForCount:(NSUInteger)count
{
    if (count == 0) {
        return [NSString stringWithFormat:@"No videos"];
    } else if (count == 1) {
        return [NSString stringWithFormat:@"1 video"];
    } else {
        return [NSString stringWithFormat:@"%d videos", count];
    }
}

- (void)cellTapped:(id)sender
{
    ORUserProfileView *vc = [[ORUserProfileView alloc] initWithFriend:CurrentUser.asFriend];
    [RVC pushToMainViewController:vc completion:nil];
}

@end
