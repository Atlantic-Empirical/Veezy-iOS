//
//  ORSubscriptionManager_plus.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 1/17/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORAccountManagerView.h"
#import "SORelativeDateTransformer.h"
#import "ORUserStatsView.h"
#import <StoreKit/StoreKit.h>
#import "ORSubscriptionController.h"
#import "ORSubscriptionUpsell.h"

@interface ORAccountManagerView()

@end

@implementation ORAccountManagerView

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Account";
	self.screenName = @"AccountMgr";
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORSubscriptionsReload:) name:@"ORSubscriptionsReload" object:nil];
    [self handleORSubscriptionsReload:nil];
}

- (void)handleORSubscriptionsReload:(NSNotification *)n
{
    SORelativeDateTransformer *rdt = [[SORelativeDateTransformer alloc] init];

    if (CurrentUser.subscriptionLevel == 0) {
        self.lblText.text = [NSString stringWithFormat:@"You have no subscription at the moment."];
    } else if (CurrentUser.subscriptionIsTrial) {
        self.lblText.text = [NSString stringWithFormat:@"You have a free trial. It expires %@.", [rdt transformedValue:CurrentUser.expirationDate]];
    } else {
        self.lblText.text = [NSString stringWithFormat:@"You have a paid subscription. It expires %@, and will be automatically renewed on that day unless you cancel it before then.", [rdt transformedValue:CurrentUser.expirationDate]];
    }
}

#pragma mark - UI

- (IBAction)btnStats_TouchUpInside:(id)sender {
	ORUserStatsView *vc = [[ORUserStatsView alloc] initWithNibName:nil bundle:nil];
	[self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)btnManageSubscription_TouchUpInside:(id)sender
{
	if (CurrentUser.subscriptionIsTrial) {
        ORSubscriptionUpsell *vc = [ORSubscriptionUpsell new];
        [self presentViewController:vc animated:YES completion:nil];
	} else {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://support.apple.com/kb/ht4098"]];
	}
}

@end
