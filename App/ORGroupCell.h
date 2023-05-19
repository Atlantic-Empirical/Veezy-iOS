//
//  ORGroupCell.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 14/05/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORGroupCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *imgAvatar;
@property (nonatomic, weak) IBOutlet UILabel *lblTitle;
@property (nonatomic, weak) IBOutlet UILabel *lblSubtitle;

@property (nonatomic, strong) OREpicGroup *group;

@end
