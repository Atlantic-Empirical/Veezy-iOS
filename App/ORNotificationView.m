//
//  ORNotificationView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 26/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORNotificationView.h"

@implementation ORNotificationView

- (id)initWithNotification:(NSDictionary *)notification
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.notification = notification;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.screenName = @"InAppNotification";

    self.lblText.text = self.notification[@"aps"][@"alert"];
}

- (void)btnAction_TouchUpInside:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORDismissNotification" object:self userInfo:self.notification];
}

@end
