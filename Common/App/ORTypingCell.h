//
//  ORTypingCell.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 25/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORTypingCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *lblComment;
@property (nonatomic, strong) OREpicVideoComment *comment;

@end
