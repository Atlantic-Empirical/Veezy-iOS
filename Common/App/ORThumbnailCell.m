//
//  ORThumbnailCell.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 25/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORThumbnailCell.h"

@implementation ORThumbnailCell

- (void)awakeFromNib
{
	self.aiLoading.color = APP_COLOR_PRIMARY;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:imageView];
    
    UIActivityIndicatorView *aiLoading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    aiLoading.hidesWhenStopped = YES;
    aiLoading.center = self.contentView.center;
    aiLoading.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:aiLoading];
    
    self.imageView = imageView;
    self.aiLoading = aiLoading;
    
    return self;
}

- (void)prepareForReuse
{
    self.imageView.image = nil;
    [self.aiLoading stopAnimating];
}

@end
