//
//  ORViewerCell.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 1/7/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORViewerCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgAvatar;
@property (weak, nonatomic) IBOutlet UILabel *lblName;

@property (strong, nonatomic) OREpicFriend *eFriend;

@end
