//
//  ORTextReaderView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 12/26/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORTextReaderView.h"

@interface ORTextReaderView ()

@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) NSString *screenTitle;

@end

@implementation ORTextReaderView

- (id)initWithText:(NSString *)text andTitle:(NSString*)title
{
    self = [super initWithNibName:@"ORTextReaderView" bundle:nil];
    if (self) {
		_text = text;
		_screenTitle = title;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
    self.title = self.screenTitle;
	self.txtMain.text = self.text;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
