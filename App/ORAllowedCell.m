//
//  ORAllowedCell.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 6/30/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORAllowedCell.h"

@implementation ORAllowedCell

+ (CGFloat)heightForCellWithVideo:(OREpicVideo *)video
{
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CGSize sizeToFit = [[self namesForVideo:video] sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f] constrainedToSize:CGSizeMake(282.0f, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    #pragma clang diagnostic pop
    
    return fmaxf(24.0f, ceilf(sizeToFit.height + 4.0f));
}

+ (NSString *)namesForVideo:(OREpicVideo *)video
{
    if (video.privacy == OREpicVideoPrivacyPublic && ![video.userId isEqualToString:CurrentUser.userId]) {
        return @"Public";
    }
    
    if (video.privacy != OREpicVideoPrivacyPublic && video.authorizedNames.count == 0) {
        return @"Private";
    }
    
    NSMutableArray *nameArray = [NSMutableArray arrayWithCapacity:video.authorizedNames.count];
    if (video.privacy == OREpicVideoPrivacyPublic) [nameArray addObject:@"Public"];
    
    if (![video.userId isEqualToString:CurrentUser.userId]) {
        [nameArray addObject:@"You"];
        
        NSUInteger count = video.authorizedNames.count;
        if (count > 1) {
            [nameArray addObject:[NSString stringWithFormat:@"%d others", count - 1]];
        }
    } else {
        for (NSString *name in video.authorizedNames) {
            [nameArray addObject:name];
        }
    }
    
    return [nameArray componentsJoinedByString:@", "];
}

- (void)setVideo:(OREpicVideo *)video
{
    _video = video;
    self.lblNames.text = [ORAllowedCell namesForVideo:video];
    
    if (video.privacy == OREpicVideoPrivacyPublic) {
        self.imgPrivacy.image = [UIImage imageNamed:@"public-icon-wire-black-30x"];
    } else if (video.privacy != OREpicVideoPrivacyPublic && video.authorizedNames.count == 0) {
        self.imgPrivacy.image = [UIImage imageNamed:@"private-icon-black-30x"];
    } else {
        self.imgPrivacy.image = [UIImage imageNamed:@"direct-icon-black-30x"];
    }
}

@end
