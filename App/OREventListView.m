//
//  OREventView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 1/16/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "OREventListView.h"
#import "OREpicEvent.h"

@interface OREventListView ()

@property (strong, nonatomic) OREpicEvent *event;

@end

@implementation OREventListView

- (id)initWithEvent:(OREpicEvent*)event
{
    self = [super initWithNibName:@"OREventListView" bundle:nil];
    if (self) {
		_event = event;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
    self.title = self.event.name;
	
	UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
    self.navigationItem.leftBarButtonItem = done;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)doneAction:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

@end
