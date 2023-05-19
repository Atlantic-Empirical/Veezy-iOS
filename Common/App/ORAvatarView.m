//
//  ORAvatarView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 12/1/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORAvatarView.h"

@interface ORAvatarView ()

@property (strong, nonatomic) UIImage *avatar;
@property (strong, nonatomic) NSString *titleString;

@end

@implementation ORAvatarView

- (id)initWithImage:(UIImage *)img andTitle:(NSString*)title
{
    self = [super initWithNibName:@"ORAvatarView" bundle:nil];
    if (self) {
        // Custom initialization
		_avatar = img;
		_titleString = title;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
	
	self.screenName = @"AvatarView";
	
	self.imgAvatar.image = self.avatar;
	self.title = self.titleString;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
