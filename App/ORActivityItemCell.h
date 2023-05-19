//
//  ORNotificationCell.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 29/07/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TTTAttributedLabel;

@interface ORActivityItemCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *imgAvatar;
@property (nonatomic, weak) IBOutlet UIImageView *imgThumbnail;
@property (nonatomic, weak) IBOutlet TTTAttributedLabel *lblText;

@property (nonatomic, weak) UIViewController *parent;
@property (nonatomic, strong) OREpicFeedItem *item;

+ (CGFloat)heightForItem:(OREpicFeedItem *)item;
- (IBAction)btnAvatar_TouchUpInside:(id)sender;

@end
