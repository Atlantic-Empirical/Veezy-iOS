//
//  ORAllowedCell.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 6/30/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORAllowedCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *lblNames;
@property (nonatomic, weak) IBOutlet UIImageView *imgPrivacy;
@property (nonatomic, strong) OREpicVideo *video;

+ (CGFloat)heightForCellWithVideo:(OREpicVideo *)video;

@end
