//
//  ORShootVideoView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 29/04/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreMotion/CoreMotion.h>
#import "ORShootNudgeView.h"

@interface ORShootNudgeView ()

@property (nonatomic, copy) NSString *message;

@end

@implementation ORShootNudgeView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (CurrentUser.totalVideoCount == 0) {
        self.message = @"Record your first video!";
    } else {
        self.message = @"Record your second video!";
    }
    
    self.lblTitle.text = self.message;
    self.lblSubtitle.text = @"Turn phone sideways and tap red button";
}

- (void)cellTapped:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:self.message
                                message:@"It's easy!\nJust turn your phone sideways, then tap the big red button to start recording."
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

@end
