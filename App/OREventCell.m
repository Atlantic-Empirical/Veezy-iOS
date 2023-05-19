//
//  OREventCell.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 1/25/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "OREventCell.h"

@implementation OREventCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setEvent:(OREpicEvent *)event
{
//	cell.textLabel.text = event.name;
//	cell.detailTextLabel.text = [NSString stringWithFormat:@"%f,%f", event.latitude, event.longitude];
//	cell.backgroundColor = [UIColor whiteColor];
//	cell.textLabel.textColor = APP_COLOR_FOREGROUND;
//	cell.detailTextLabel.textColor = APP_COLOR_FOREGROUND;
}

@end
