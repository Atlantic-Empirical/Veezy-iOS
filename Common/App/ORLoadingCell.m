//
//  ORLoadingCell.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 16/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORLoadingCell.h"

@implementation ORLoadingCell

- (void)awakeFromNib
{
	self.aiLoading.color = APP_COLOR_PRIMARY;
}

- (void)prepareForReuse
{
    [self.aiLoading startAnimating];
}

@end
