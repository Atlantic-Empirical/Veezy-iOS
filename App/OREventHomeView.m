//
//  OREventHomeView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/25/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "OREventHomeView.h"
#import "OREpicEvent.h"

@interface OREventHomeView ()

@property (strong, nonatomic) OREpicEvent *event;

@end

@implementation OREventHomeView

- (id)initWithEvent:(OREpicEvent*)event
{
    self = [super initWithNibName:@"OREventHomeView" bundle:nil];
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

#pragma mark - Setup

- (void)setupForEvent
{
	self.lblEventName.text = self.event.name;
}

@end
