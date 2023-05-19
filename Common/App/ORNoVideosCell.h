//
//  ORNoVideosCell.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 16/09/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORNoVideosCell : UITableViewCell

@property (nonatomic, strong) OREpicFriend *user;

@property (weak, nonatomic) IBOutlet UILabel *lblMessage;

@end
