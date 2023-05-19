//
//  ORTwitterNudgeView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 22/07/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORTwitterNudgeView.h"
#import "ORTwitterConnectView.h"

@interface ORTwitterNudgeView ()

@end

@implementation ORTwitterNudgeView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.lblTitle.text = @"Connect Twitter";
    self.lblSubtitle.text = @"Find friends & Tweet your videos";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORTwitterPaired:) name:@"ORTwitterPaired" object:nil];
}

- (void)cellTapped:(id)sender
{
    ORTwitterConnectView *vc = [ORTwitterConnectView new];
    [vc setCompletionBlock:^(BOOL success) {
        if (!success) {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:@(YES) forKey:@"twitterDisabled"];
            [prefs synchronize];
        }
        
        [RVC dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [RVC presentViewController:vc animated:YES completion:nil];
}

- (void)handleORTwitterPaired:(NSNotification *)n
{
    [RVC hideNudge:self];
}

- (void)btnClose_TouchUpInside:(id)sender
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:@(YES) forKey:@"twitterDisabled"];
    [prefs synchronize];

    [super btnClose_TouchUpInside:sender];
}

@end
