//
//  ORTrimVideoView.m
//  Epic
//
//  Created by Thomas Purnell-Fisher on 11/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORTrimVideoView.h"

@interface ORTrimVideoView ()

@end

@implementation ORTrimVideoView

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
	self.screenName = @"VideoTrimer";
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnCommitTrim_TouchUpInside:(id)sender {
}

- (IBAction)view_TouchUpInside:(id)sender {
	[self.view removeFromSuperview];
}

@end
