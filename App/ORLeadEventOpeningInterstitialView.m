//
//  OROpeningInterstitial_FIFA.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/2/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORLeadEventOpeningInterstitialView.h"
#import "OREpicEvent.h"
#import "OREpicEventSponsorship.h"

@interface ORLeadEventOpeningInterstitialView ()

@property (strong, nonatomic) OREpicEvent *event;

@end

@implementation ORLeadEventOpeningInterstitialView

- (id)initWithEvent:(OREpicEvent*)event
{
    self = [super initWithNibName:@"ORLeadEventOpeningInterstitialView" bundle:nil];
    if (self) {
		_event = event;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setupForEvent];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)close:(BOOL)goToSponsorView
{
	[UIView animateWithDuration:0.5f delay:0.0f
						options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 self.view.frame = CGRectMake(0, self.view.superview.frame.size.height, self.view.superview.frame.size.width, self.view.superview.frame.size.height);
					 } completion:^(BOOL finished) {
						 [[NSNotificationCenter defaultCenter] postNotificationName:@"ORLeadEventInterstitalDismissed" object:[NSNumber numberWithBool:self.isFromSignIn]];
						 if (goToSponsorView) {
							 [RVC showMainInterfaceWithCompletion:nil];
							 [[NSNotificationCenter defaultCenter] postNotificationName:@"ORGotoLeadEvent" object:nil];
						 }
					 }];
}

#pragma mark - UI

- (IBAction)btnGoToEvent_TouchUpInside:(id)sender {
	[self close:YES];
}

- (IBAction)btnContinue_TouchUpInside:(id)sender {
	[self close:NO];
}

#pragma mark - Setup

- (void)setupForEvent
{
	self.lblEventName.text = self.event.name;
	self.lblSponsorName.text = self.event.activeSponsorship.sponsorName;
	
	[[ORCachedEngine sharedInstance] imageAtURL:self.event.interstitalImageURL maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
		if (error) {
			NSLog(@"Error: %@", error);
		} else {
			if (image) {
				self.imgMain.image = image;
			}
		}
	}];
}

@end
