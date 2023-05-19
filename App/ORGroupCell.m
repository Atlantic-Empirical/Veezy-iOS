//
//  ORGroupCell.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 14/05/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <Social/Social.h>
#import <MessageUI/MessageUI.h>
#import "ORGroupCell.h"
#import "ORContact.h"

@interface ORGroupCell ()

@end

@implementation ORGroupCell


- (void)setGroup:(OREpicGroup *)group
{
    _group = group;
    
    self.lblTitle.text = group.name;
    self.imgAvatar.image = [UIImage imageNamed:@"profile"];
    
    if (group.lastActivity) {
        self.lblSubtitle.text = [NSString stringWithFormat:@"Last Activity: %@", group.lastActivity];
    } else {
        self.lblSubtitle.text = [NSString stringWithFormat:@"Members: %d", group.userIds.count];
    }
	
    if (group.imageUrl) {
        if ([group.imageUrl hasPrefix:@"http"]) {
            __weak OREpicGroup *weakGroup = group;
            __weak ORGroupCell *weakCell = self;
            
            NSURL *url = [NSURL URLWithString:group.imageUrl];
            
            if (url) {
                [[ORCachedEngine sharedInstance] imageAtURL:url size:CGSizeMake(40.0f, 40.0f) fill:YES maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
                    if (error) NSLog(@"Error: %@", error);
                    
                    if (image && weakGroup == weakCell.group) {
                        weakCell.imgAvatar.image = image;
                    }
                }];
            }
        } else {
            self.imgAvatar.image = [UIImage imageNamed:group.imageUrl];
        }
    }
}

@end
