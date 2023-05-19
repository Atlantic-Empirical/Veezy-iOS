//
//  ORColdStartAnywhere.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 3/11/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORColdStartOne.h"
#import <QuartzCore/QuartzCore.h>

@interface ORColdStartOne ()

@end

@implementation ORColdStartOne

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
	self.viewNumber.layer.cornerRadius = 0.5 * self.viewNumber.frame.size.height;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
