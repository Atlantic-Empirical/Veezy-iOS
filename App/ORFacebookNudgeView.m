//
//  ORFacebookNudgeView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 22/07/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORFacebookNudgeView.h"
#import "ORFacebookConnectView.h"

@interface ORFacebookNudgeView ()

@end

@implementation ORFacebookNudgeView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.lblTitle.text = @"Connect Facebook";
    self.lblSubtitle.text = @"Find friends & share videos"; //Find & invite your friends"
	   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORFacebookPaired:) name:@"ORFacebookPaired" object:nil];
}

- (void)cellTapped:(id)sender
{
	ORFacebookConnectView *vc = [ORFacebookConnectView new];
    [vc setCompletionBlock:^(BOOL success) {
        [RVC dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [RVC presentViewController:vc animated:YES completion:nil];
}

- (void)handleORFacebookPaired:(NSNotification *)n
{
    [RVC hideNudge:self];
}

@end
