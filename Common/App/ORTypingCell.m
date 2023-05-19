//
//  ORTypingCell.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 25/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORTypingCell.h"

@implementation ORTypingCell

- (void)awakeFromNib
{
    self.lblComment.layer.cornerRadius = 2.0f;
}

- (void)setComment:(OREpicVideoComment *)comment
{
    _comment = comment;
    self.lblComment.text = comment.comment;
}

@end
