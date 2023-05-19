//
//  ORNudgeView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 29/04/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORNudgeView.h"

@implementation ORNudgeView

- (id)init
{
    self = [super initWithNibName:@"ORNudgeView" bundle:nil];
    if (!self) return nil;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.layer.cornerRadius = 4.0f;
}

- (void)cellTapped:(id)sender
{
    // Nothing
}

- (void)btnClose_TouchUpInside:(id)sender
{
    [RVC hideNudge:self];
}

@end
