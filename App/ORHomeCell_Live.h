//
//  ORLiveCell.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 3/24/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORHomeCell_Live : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *imgThumbnail;
@property (nonatomic, weak) IBOutlet UIImageView *imgAvatar;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *aiLoading;
@property (nonatomic, weak) IBOutlet UILabel *lblUserName;
@property (nonatomic, weak) IBOutlet UILabel *lblLocation;
@property (nonatomic, weak) IBOutlet UIView *viewLiveBadge;
@property (nonatomic, weak) IBOutlet UIView *viewNotLiveBadge;
@property (nonatomic, weak) IBOutlet UILabel *lblWhen;

@property (nonatomic, strong) OREpicFeedItem *item;

@end
