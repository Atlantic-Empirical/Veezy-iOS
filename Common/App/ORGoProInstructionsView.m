//
//  ORGoProInstructionsView.m
//  Huck
//
//  Created by Thomas Purnell-Fisher on 10/2/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORGoProInstructionsView.h"

@interface ORGoProInstructionsView ()

@end

@implementation ORGoProInstructionsView

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"GoPro";
	self.screenName = @"GoProInstructions";
    
    if (self.presentingViewController) {
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction)];
        self.navigationItem.leftBarButtonItem = done;
    }
}

- (void)doneAction
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
