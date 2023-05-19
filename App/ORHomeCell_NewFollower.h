//
//  ORHomeCell_NewFollower.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 03/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORHomeCell_NewFollower : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *imgAvatar;
@property (nonatomic, weak) IBOutlet UILabel *lblUserName;
@property (nonatomic, strong) OREpicFeedItem *item;
@property (nonatomic, weak) UIViewController *parent;
@property (weak, nonatomic) IBOutlet UILabel *lblViewCount;
@property (weak, nonatomic) IBOutlet UILabel *lblFavoriteCount;
@property (weak, nonatomic) IBOutlet UILabel *lblRepostCount;

- (IBAction)cell_TouchUpInside:(id)sender;

@end
