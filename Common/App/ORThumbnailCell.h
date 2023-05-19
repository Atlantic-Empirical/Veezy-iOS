//
//  ORThumbnailCell.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 25/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORThumbnailCell : UICollectionViewCell

@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, weak) UIActivityIndicatorView *aiLoading;
@property (nonatomic, assign) NSUInteger thumbnailIndex;

@end
