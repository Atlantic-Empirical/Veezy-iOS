//
//  ORColdStartInstant.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/20/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORColdStartTwo.h"
#import <QuartzCore/QuartzCore.h>

@interface ORColdStartTwo ()

@end

@implementation ORColdStartTwo

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
    // Do any additional setup after loading the view from its nib.
	self.view.backgroundColor = [UIColor clearColor];
	self.viewNumber.layer.cornerRadius = 0.5 * self.viewNumber.frame.size.height;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
