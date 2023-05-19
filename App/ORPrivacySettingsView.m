//
//  ORPrivacySettingsView.m
//  OneCent
//
//  Created by Thomas Purnell-Fisher on 12/18/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORPrivacySettingsView.h"
#import "ORPrivacyZonesView.h"

@interface ORPrivacySettingsView ()

@property (nonatomic, assign) BOOL modified;

@end

@implementation ORPrivacySettingsView

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
    self.title = NSLocalizedStringFromTable(@"Privacy", @"UserSettingsSub", @"Privacy");
	self.screenName = @"PrivacyMgr";

	[self.swEnhancedPrivacyIsOn setOn:CurrentUser.isPrivate];
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (self.modified) {
        self.modified = NO;
        
        [ApiEngine saveUser:CurrentUser cb:^(NSError *error, OREpicUser *user) {
            if (error) {
                NSLog(@"Error: %@", error);
            } else {
                if (user) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORProfileUpdated" object:nil];
                    [CurrentUser saveLocalUser];
                }
            }
        }];
    }
}

- (IBAction)swAccountIsPublic_ValueChanged:(id)sender
{
    self.modified = YES;
	CurrentUser.isPrivate = self.swEnhancedPrivacyIsOn.isOn;
}

- (void)btnPrivacyZones_TouchUpInside:(id)sender
{
    ORPrivacyZonesView *vc = [ORPrivacyZonesView new];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
