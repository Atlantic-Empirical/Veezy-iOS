//
//  ORUserStatsView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/17/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORUserStatsView.h"

#define BYTES_PER_SECOND 196608 // 1.5 Mbit
#define BYTES_PER_MINUTE BYTES_PER_SECOND * 60

@interface ORUserStatsView () <UIAlertViewDelegate>

@property (nonatomic, strong) UIAlertView *alertView;
@property (assign, nonatomic) int bufferVideoCount;

@end

@implementation ORUserStatsView

- (void)dealloc
{
    self.alertView.delegate = nil;
    self.contentView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addSubview:self.contentView];
    ((UIScrollView *)self.view).contentSize = self.contentView.frame.size;
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
	self.title = NSLocalizedStringFromTable(@"Stats", @"UserSettingsSub", @"Stats");
	self.screenName = @"UserStats";

//    if (self.navigationController.childViewControllers.count == 1) {
//        // Camera as left bar button
//        UIBarButtonItem *camera = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"camera-icon-black-40x"] style:UIBarButtonItemStylePlain target:RVC action:@selector(showCamera)];
//        self.navigationItem.leftBarButtonItem = camera;
//    }
	
	[self updateUserStats];
	[self updateSystemSpace];
	[self registerForNotifications];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI

- (void)btnResetWifi_TouchUpInside:(id)sender
{
    self.alertView.delegate = nil;
    self.alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                message:@"Reset uploaded data for Wifi? This can't be undone."
                                               delegate:self
                                      cancelButtonTitle:@"No"
                                      otherButtonTitles:@"Reset", nil];
    self.alertView.tag = 1;
    [self.alertView show];
}

- (void)btnResetWwan_TouchUpInside:(id)sender
{
    self.alertView.delegate = nil;
    self.alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                message:@"Reset uploaded data for Cellular? This can't be undone."
                                               delegate:self
                                      cancelButtonTitle:@"No"
                                      otherButtonTitles:@"Reset", nil];
    self.alertView.tag = 2;
    [self.alertView show];
}

- (void)btnInfo_UploadData_TouchUpInside:(id)sender
{
    [self showAlert:NSLocalizedStringFromTable(@"totalUploaded", @"UserSettingsSub", @"Total Uploaded Data") andMessage:NSLocalizedStringFromTable(@"totalUploadedMsg", @"UserSettingsSub", @"Tells you how much data Veezy has used to upload your videos.")];
}

- (IBAction)btnInfo_TotalStored_TouchUpInside:(id)sender
{
	[self showAlert:NSLocalizedStringFromTable(@"totalStored", @"UserSettingsSub", @"Total Stored") andMessage:NSLocalizedStringFromTable(@"totalStoredMsg", @"UserSettingsSub", @"Tells you how many videos you have stored in Veezy and if they were all one video - how long would it be!")];
}

- (IBAction)btnInfo_Viewership_TouchUpInside:(id)sender
{
	[self showAlert:NSLocalizedStringFromTable(@"viewership", @"UserSettingsSub", @"Viewership") andMessage:NSLocalizedStringFromTable(@"viewershipMsg", @"UserSettingsSub", @"How many views and likes have all your videos gotten, total, combined.")];
}

- (IBAction)btnInfo_BufferFree_TouchUpInside:(id)sender
{
	[self showAlert:NSLocalizedStringFromTable(@"bufferFree", @"UserSettingsSub", @"Buffer Free") andMessage:NSLocalizedStringFromTable(@"bufferFreeMsg", @"UserSettingsSub", @"How much space is free on your phone and how many minutes of video that space would hold (while Veezy uploads it and clears up the space)")];
}

- (IBAction)btnInfo_BufferUsed_TouchUpInside:(id)sender
{
	[self showAlert:NSLocalizedStringFromTable(@"bufferUsed", @"UserSettingsSub", @"Buffer Used") andMessage:NSLocalizedStringFromTable(@"bufferUsedMsg", @"UserSettingsSub", @"How much space Veezy is using right now on your phone. If this number is above zero it is because Veezy is currently uploading your video(s) or a problem occurred.")];
}

- (IBAction)btnInfo_CurrentTransfer_TouchUpInside:(id)sender
{
	[self showAlert:NSLocalizedStringFromTable(@"currTransfer", @"UserSettingsSub", @"Current Transfer") andMessage:NSLocalizedStringFromTable(@"currTransferMsg", @"UserSettingsSub", @"If Veezy is currently transfering a video to storage, the transfer speed would be provided here.")];
}

- (void)showAlert:(NSString*)title andMessage:(NSString*)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:nil
										  cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"UserSettingsSub", @"OK")
										  otherButtonTitles:nil];
	[alert show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.alertView.delegate = nil;
    
    if (alertView.tag == 1) {
        if (buttonIndex == alertView.cancelButtonIndex) return;
        
        CurrentUser.totalBytesWIFI = 0;
        CurrentUser.currentBytesWIFI = 0;
    } else if (alertView.tag == 2) {
        if (buttonIndex == alertView.cancelButtonIndex) return;

        CurrentUser.totalBytesWWAN = 0;
        CurrentUser.currentBytesWWAN = 0;
    }
    
    [CurrentUser saveLocalUser];
    [self updateUserStats];
}

#pragma mark - User Stats

- (void)updateUserStats
{
    self.lblUploadWifi.text = [NSByteCountFormatter stringFromByteCount:(CurrentUser.totalBytesWIFI + CurrentUser.currentBytesWIFI) countStyle:NSByteCountFormatterCountStyleFile];
    self.lblUploadWwan.text = [NSByteCountFormatter stringFromByteCount:(CurrentUser.totalBytesWWAN + CurrentUser.currentBytesWWAN) countStyle:NSByteCountFormatterCountStyleFile];
    
	self.lblLikeCount.text = [self formatNumber:CurrentUser.likeCount];
    self.lblViewCount.text = [self formatNumber:CurrentUser.viewCount];
    self.lblVideoCount.text = [self formatNumber:CurrentUser.totalVideoCount];
    
	// Video Minutes
	if (!CurrentUser.totalDuration) {
        [[ORDataController sharedInstance] userVideosForceReload:NO cacheOnly:NO completion:^(NSError *error, BOOL final, NSArray *feed) {
			if (error) {
                NSLog(@"Error: %@", error);
			} else {
				NSUInteger totalDuration = 0;
				for (OREpicVideo *video in feed)
					totalDuration += video.duration;
				CurrentUser.totalDuration = totalDuration;
				NSUInteger minutes = (int)ceilf(CurrentUser.totalDuration / 60.0f);
				self.lblVideoMin.text = [self formatNumber:minutes];
			}
        }];
	} else {
		NSUInteger minutes = (int)ceilf(CurrentUser.totalDuration / 60.0f);
		self.lblVideoMin.text = [self formatNumber:minutes];
	}
}

#pragma mark - File System

- (void)updateSystemSpace {
	uint64_t freeDiscSpace = [self getFreeDiskspace];
//	DLog(@"%llu", freeDiscSpace);
	self.lblBufferCapacityInBytes.text = [NSByteCountFormatter stringFromByteCount:freeDiscSpace countStyle:NSByteCountFormatterCountStyleFile];
	float min = freeDiscSpace / roundf(BYTES_PER_MINUTE);
//	DLog(@"%f", min);
	self.lblBufferCapacityInMinutes.text = [self formatNumber:min];
	
	uint64_t bufferUsed = [self sizeOfFolder:[ORUtility documentsDirectory]];
	self.lblBufferUsedInBytes.text = [NSByteCountFormatter stringFromByteCount:bufferUsed countStyle:NSByteCountFormatterCountStyleFile];
	min = (bufferUsed / roundf(BYTES_PER_MINUTE));
	self.lblBufferUsedInMinutes.text = [self formatNumber:min];
	self.lblBufferedVideoCount.text = [NSString localizedStringWithFormat:@"%d", self.bufferVideoCount];
}

-(uint64_t)getFreeDiskspace {
    uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
	
    if (dictionary) {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
        NSLog(@"Memory Capacity of %llu MiB with %llu MiB Free memory available.", ((totalSpace/1024ll)/1024ll), ((totalFreeSpace/1024ll)/1024ll));
    } else {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }
	
    return totalFreeSpace;
}

- (int)numberOfFilesInDocsDirectory
{
	NSArray *directoryContent  = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[ORUtility documentsDirectory] error:nil];
	return [directoryContent count];
}

-(uint64_t)sizeOfFolder:(NSString *)folderPath
{
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *contentsEnumurator = [contents objectEnumerator];
	
    NSString *file;
    unsigned long long int folderSize = 0;
	
    while (file = [contentsEnumurator nextObject]) {
//		DLog(@"%@", file);
		if ([file isEqualToString:@"aspera.archive"] || [file isEqualToString:@"user.archive"] || [file isEqualToString:@"locations.archive"]) {
			// don't count them
		} else {
			NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:file] error:nil];
			NSString *fileType = [fileAttributes objectForKey:NSFileType];
			if (fileType == NSFileTypeDirectory) {
				uint64_t sz = [self innerFolderSize:[folderPath stringByAppendingPathComponent:file]];
				if (sz == UINT64_MAX) {
					// don't count it, it's all jpgs
				} else {
                    folderSize += [[fileAttributes objectForKey:NSFileSize] intValue];
					folderSize += sz;
					self.bufferVideoCount++;
				}
			}
		}
    }
	
	return folderSize;
}

- (uint64_t)innerFolderSize:(NSString*)folderPath {
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *contentsEnumurator = [contents objectEnumerator];
	
    NSString *file;
    unsigned long long int folderSize = 0;
	
	BOOL foundAnonJpg = NO;
	
	DLog(@"*****************");
	DLog(@"%@", folderPath);
	
    while (file = [contentsEnumurator nextObject]) {
		DLog(@"%@", file);
		if (!foundAnonJpg) {
			if (![[file pathExtension] isEqualToString:@"jpg"]) {
				foundAnonJpg = YES;
			}
		}
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:file] error:nil];
		folderSize += [[fileAttributes objectForKey:NSFileSize] intValue];
    }
	
	if (!foundAnonJpg) {
		DLog(@"Folder is all JPGs: %@", folderPath);
		return UINT64_MAX;
	} else {
		return folderSize;
	}
}

#pragma mark - Utility

- (NSString*)formatNumber:(float)num
{
	num = floorf(num);
	NSNumberFormatter *formatter = [NSNumberFormatter new];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
	return [formatter stringFromNumber:[NSNumber numberWithInteger:num]];
}

#pragma mark - NSNotifications

- (void)registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORUploadProgress:) name:@"ORUploadProgress" object:nil];
}

- (void)handleORUploadProgress:(NSNotification*)n
{
    double bitrate = [n.userInfo[@"bitrate"] doubleValue];
    
    if (bitrate > 0) {
//        double expected_video_bitrate = MIN(DEFAULT_MAX_VIDEO_BITRATE, bitrate - DEFAULT_AUDIO_BITRATE);
//        expected_video_bitrate = MAX(expected_video_bitrate, DEFAULT_MIN_VIDEO_BITRATE);
//        self.videoBitrate = expected_video_bitrate;
        NSLog(@"New video bitrate for next segment: %f", bitrate);
		self.lblTransferRateInKbps.text = [NSString localizedStringWithFormat:@"%@ %@", [NSByteCountFormatter stringFromByteCount:bitrate countStyle:NSByteCountFormatterCountStyleFile], NSLocalizedStringFromTable(@"perSec", @"UserSettingsSub", @"/sec")];
    } else {
		self.lblTransferRateInKbps.text = NSLocalizedStringFromTable(@"notActive", @"UserSettingsSub", @"Not Active");
	}
}

@end
