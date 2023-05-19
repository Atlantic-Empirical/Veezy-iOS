//
//  ORGeneralSettingsView.m
//  OneCent
//
//  Created by Thomas Purnell-Fisher on 12/18/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORTransferSettingsView.h"
#import "ORFaspPersistentEngine.h"
#import "ORNavigationController.h"
#import "ORUserStatsView.h"
#import "ORQualitySelectView.h"

@interface ORTransferSettingsView ()

@property (nonatomic, assign) BOOL modified;

@end

@implementation ORTransferSettingsView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
    self.title = @"Data";
	self.screenName = @"DataUsageMgr";

	[self loadSettings];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadSettings) name:@"ORUserSettingsUpdated" object:nil];

}

- (void)viewDidDisappear:(BOOL)animated
{
    if (self.modified) {
        [[ORFaspPersistentEngine sharedInstance] setWifiOnlyMode:CurrentUser.settings.wifiTransferOnly];
        [CurrentUser saveLocalUser];
        
        [ApiEngine saveUserSettings:CurrentUser.settings cb:^(NSError *error, BOOL result) {
            if (error) {
                NSLog(@"Error: %@", error);
            } else {
                DLog(@"User settings saved.");
            }
        }];
    }
}

- (void)loadSettings
{
	[self.swWifiTransferOnly setOn:CurrentUser.settings.wifiTransferOnly];
    
    switch (CurrentUser.settings.videoQuality) {
        case 1:
            self.lblVideoQuality.text = @"Medium";
            break;
        case 2:
            self.lblVideoQuality.text = @"Low";
            break;
            
        default:
            self.lblVideoQuality.text = @"High";
            break;
    }
	[self setDataUsageMessage];
}

#pragma mark - UI

- (IBAction)btnStats_TouchUpInside:(id)sender
{
	ORUserStatsView *vc = [[ORUserStatsView alloc] initWithNibName:nil bundle:nil];
	[self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)swWifiTransferOnly_ValueChanged:(id)sender
{
	CurrentUser.settings.wifiTransferOnly = self.swWifiTransferOnly.isOn;
    self.modified = YES;
}

- (void)btnVideoQuality_TouchUpInside:(id)sender
{
    ORQualitySelectView *vc = [[ORQualitySelectView alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Custom

- (void)setDataUsageMessage
{
	NSString *first = [NSString stringWithFormat:@"%@ uses about", APP_NAME];
	NSString *third = @"per hour of video transfered from your phone.";
	NSString *amount;
	
	switch (CurrentUser.settings.videoQuality) {
	
		case 1:
			amount = @"1/4 a gigabyte";
			self.lblDataUsageMessage.text = [NSString stringWithFormat:@"%@ %@ %@", first, amount, third];
			break;
			
		case 2:
			amount = @"1/8 of a gigabyte";
			self.lblDataUsageMessage.text = [NSString stringWithFormat:@"%@ %@ %@", first, amount, third];
			break;

		default:
			amount = @"1/2 a gigabyte";
			self.lblDataUsageMessage.text = [NSString stringWithFormat:@"%@ %@ %@", first, amount, third];
			break;
	}
}

@end
