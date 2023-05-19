//
//  ORLegalStuffParentView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 12/26/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORLegalStuffParentView.h"
#import "ORTextReaderView.h"
#import "ORWebView.h"

@interface ORLegalStuffParentView ()

@end

@implementation ORLegalStuffParentView

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
    self.title = NSLocalizedStringFromTable(@"Legal", @"UserSettingsSub", @"Legal");
	self.screenName = @"Legal";

//    if (self.navigationController.childViewControllers.count == 1) {
//        // Camera as left bar button
//        UIBarButtonItem *camera = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"camera-icon-black-40x"] style:UIBarButtonItemStylePlain target:RVC action:@selector(showCamera)];
//        self.navigationItem.leftBarButtonItem = camera;
//    }
}

- (void)viewWillAppear:(BOOL)animated
{
	self.navigationController.toolbarHidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)btnToS_TouchUpInside:(id)sender {
	self.btnToS.enabled = NO;
	[ApiEngine getAppSetting:@"cc-tos-global" completion:^(NSError *error, NSString *result) {
		self.btnToS.enabled = YES;
		if (error) {
			
		} else {
			if (!result) return;
			ORWebView *vc = [[ORWebView alloc] initWithURLString:result];
			[self.navigationController pushViewController:vc animated:YES];
			vc.title = NSLocalizedStringFromTable(@"tos", @"UserSettingsSub", @"Terms of Use");
		}
	}];
}

- (IBAction)btnPrivacy_TouchUpInside:(id)sender {
	self.btnPrivacy.enabled = NO;
	[ApiEngine getAppSetting:@"cc-pp-global" completion:^(NSError *error, NSString *result) {
		self.btnPrivacy.enabled = YES;
		if (error) {
			
		} else {
			if (!result) return;
			ORWebView *vc = [[ORWebView alloc] initWithURLString:result];
			[self.navigationController pushViewController:vc animated:YES];
			vc.title = NSLocalizedStringFromTable(@"pp", @"UserSettingsSub", @"Privacy Policy");
		}
	}];
}

- (IBAction)btnAcknowledgements_TouchUpInside:(id)sender {
	self.btnAcknowledgements.enabled = NO;
	[ApiEngine getAppSetting:@"cc-acks-global" completion:^(NSError *error, NSString *result) {
		self.btnAcknowledgements.enabled = YES;
		if (error) {
			
		} else {
			if (!result) return;
			ORWebView *vc = [[ORWebView alloc] initWithURLString:result];
			[self.navigationController pushViewController:vc animated:YES];
			vc.title = NSLocalizedStringFromTable(@"acks", @"UserSettingsSub", @"Acknowledgements");
		}
	}];
}

- (IBAction)btnOpenSource_TouchUpInside:(id)sender {
	
	NSString *osi = @"";
	NSString *googleMapsOpenSource = [GMSServices openSourceLicenseInfo];
	osi = [osi stringByAppendingString:[NSString localizedStringWithFormat:@"%@\n\n", googleMapsOpenSource]];
	ORTextReaderView *vc = [[ORTextReaderView alloc] initWithText:osi andTitle:NSLocalizedStringFromTable(@"openSource", @"UserSettingsSub", @"Open Source")];
	[self.navigationController pushViewController:vc animated:YES];
}

@end
