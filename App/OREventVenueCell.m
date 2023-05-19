//
//  ORFifaStadiumCell.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/4/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "OREventVenueCell.h"
#import "OREpicEventVenue.h"

@implementation OREventVenueCell

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

- (void)setVenue:(OREpicEventVenue *)venue
{
	_venue = venue;
	self.lblVenueName.text = self.venue.name;
	self.lblDescription.text = self.venue.venueDescription;
	self.lblStats.text = [NSString stringWithFormat:@"%d videos in past 6 hours", arc4random_uniform(100)];
	
	if (self.venue.imageUrlString) {
		__weak OREpicEventVenue *weakVenue = self.venue;
		__weak OREventVenueCell *weakSelf = self;
		
		[[ORCachedEngine sharedInstance] imageAtURL:[NSURL URLWithString:self.venue.imageUrlString] size:self.imgVenue.frame.size completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
			if (error) {
				NSLog(@"Error: %@", error);
			} else {
				if (image && weakSelf.venue == weakVenue) {
					weakSelf.imgVenue.image = image;
				}
			}
		}];
	}
}

@end
