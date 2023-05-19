//
//  ORProfessionalSettingsView.m
//  OneCent
//
//  Created by Thomas Purnell-Fisher on 12/18/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORProSettingsView.h"

#define MAX_VIDEO_BITRATE 5000 // 5Mbps, 5,000Kbps
#define MAX_AUDIO_BITRATE 1000	// 1Mbps, 1000Kbps

@interface ORProSettingsView ()

@end

@implementation ORProSettingsView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
    self.title = NSLocalizedStringFromTable(@"Professional", @"UserSettingsSub", @"Professional");
	self.screenName = @"ProSettings";

	[self loadSettings];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[CurrentUser saveLocalUser];
	[ApiEngine saveUserSettings:CurrentUser.settings cb:^(NSError *error, BOOL result) {
		if (error) {

		} else {
			DLog(@"User settings saved.");
		}
		[self.navigationController popViewControllerAnimated:YES];
	}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadSettings
{
	[self.switchKeepVideos setOn:CurrentUser.settings.preserveLocalCopies];
	[self.sldVideoBitrate setValue:(CurrentUser.settings.targetVideoBitrate / MAX_VIDEO_BITRATE)];
	[self.sldAudioBitrate setValue:(CurrentUser.settings.targetAudioBitrate / MAX_AUDIO_BITRATE)];
}

- (void)switchKeepVideos_ValueChanged:(id)sender
{
	CurrentUser.settings.preserveLocalCopies = self.switchKeepVideos.isOn;
}

- (IBAction)sldVideoBitrate_ValueChanged:(UISlider*)sender {
	int newBitrate = roundf(sender.value * MAX_VIDEO_BITRATE);
	self.lblVideoBitrate.text = [NSString localizedStringWithFormat:@"%dKbps", newBitrate];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"newVideoBitrate" object:[NSNumber numberWithInt:newBitrate]];
	CurrentUser.settings.targetVideoBitrate = newBitrate;
}

- (IBAction)sldAudioBitrate_ValueChanged:(UISlider*)sender {
	int newBitrate = roundf(sender.value * MAX_AUDIO_BITRATE);
	self.lblAudioBitrate.text = [NSString localizedStringWithFormat:@"%dKbps", newBitrate];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"newAudioBitrate" object:[NSNumber numberWithInt:newBitrate]];
	CurrentUser.settings.targetAudioBitrate = newBitrate;
}

@end
