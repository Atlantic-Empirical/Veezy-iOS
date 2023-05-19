//
//  ORGoProSourceView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 5/17/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORGoProSourceView.h"
#import "ORGoProEngine.h"
#import "ORGoProCameraInfo.h"
#import "ORGoProListView.h"
#import "ORGoProPreview.h"

#define MAX_RETRIES 5

@interface ORGoProSourceView () <ORGoProEngineDelegate>

@property (strong, nonatomic) ORGoProEngine *gpe;
@property (assign, nonatomic) NSUInteger retries;

@end

@implementation ORGoProSourceView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
	UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
	self.navigationItem.leftBarButtonItem = done;
	self.title = @"GoPro";
	self.screenName = @"GoPro";
	
	self.gpe = [ORGoProEngine sharedInstance];
    self.gpe.delegate = self;
    self.btnRecord.hidden = YES;
    self.btnList.hidden = YES;
    
	self.btnList.layer.cornerRadius = 6.0f;
	self.btnRecord.layer.cornerRadius = 6.0f;
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORRecordingStarted:) name:@"ORRecordingStarted" object:nil];
    
    self.retries = 0;
    [self lookForCamera];

	self.aiLoading.color = APP_COLOR_PRIMARY;
	self.aiPreview.color = APP_COLOR_PRIMARY;
}

- (void)close
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UI

- (void)handleORRecordingStarted:(NSNotification *)n
{
    [self close];
}

- (IBAction)btnList_TouchUpInside:(id)sender
{
	[AppDelegate.mixpanel track:@"BTN - GoPro List Vids" properties:nil];
	ORGoProListView *lv = [[ORGoProListView alloc] initWithGoProEngine:self.gpe];
	[self presentViewController:lv animated:YES completion:^{
		//
	}];
}

- (IBAction)btnRecord_TouchUpInside:(id)sender
{
	[AppDelegate.mixpanel track:@"BTN - GoPro Record" properties:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORStartGoProRecording" object:nil userInfo:nil];
    
    [self.aiPreview startAnimating];
    [self.viewPreview setPlayer:nil];
}

- (IBAction)btnRetryConnectToCamera_TouchUpInside:(id)sender {
	[self lookForCamera];
	self.btnRetryConnectToCamera.hidden = YES;
}

#pragma mark - GoPro Camera Interaction

- (void)lookForCamera
{
    self.lblCameraInfo.text = @"Looking for camera...";
    [self.aiLoading startAnimating];
    
    __weak ORGoProSourceView *weakSelf = self;
    
    [self.gpe initializeCameraWithCompletion:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
        
        if (result) {
            [weakSelf.aiLoading stopAnimating];
            weakSelf.lblCameraInfo.text = [NSString stringWithFormat:@"Connected to %@", self.gpe.camera.cameraName];
            weakSelf.btnRecord.hidden = NO;
//            weakSelf.btnList.hidden = NO;
            
            [weakSelf.aiPreview startAnimating];
            [weakSelf.gpe startPreview];
            return;
        }
        
        weakSelf.retries++;
        
        if (weakSelf.retries >= MAX_RETRIES) {
            [weakSelf.aiLoading stopAnimating];
            weakSelf.lblCameraInfo.text = @"Camera not found";
			weakSelf.btnRetryConnectToCamera.hidden = NO;
            weakSelf.btnRecord.hidden = YES;
            weakSelf.btnList.hidden = YES;
        } else {
            [weakSelf lookForCamera];
        }
    }];
}

#pragma mark - ORGoProEngineDelegate

- (void)goproDidStartPreview
{
    NSLog(@"Preview Started");
    [self.viewPreview setPlayer:self.gpe.previewPlayer];
    [self.aiPreview stopAnimating];
}

- (void)goproDidFailPreviewWithError:(NSError *)error
{
    NSLog(@"Preview Failed: %@", error);
    [self.viewPreview setPlayer:nil];
    [self.aiPreview startAnimating];

    __weak ORGoProSourceView *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [weakSelf.gpe startPreview];
    });
}

- (void)goproDidStopPreview
{
    NSLog(@"Preview Stopped");
    [self.viewPreview setPlayer:nil];
}

- (void)goproWillStartRecording
{
    NSLog(@"Will start recording...");
}

- (void)goproDidStartRecording
{
    NSLog(@"Recording started");
}

- (void)goproWillStopRecording
{
    NSLog(@"Will stop recording...");
}

- (void)goproDidStopRecording
{
    NSLog(@"Recording stopped");
}

- (void)goproDidFailRecordingWithError:(NSError *)error
{
    NSLog(@"Recording failed: %@", error);
}

@end
