//
//  ORUserCell.m
//  Epic
//
//  Created by Rodrigo Sieiro on 01/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORUserCell.h"
#import "OREpicFriend.h"
#import "ORContact.h"
#import "ORFacebookPage.h"

@implementation ORUserCell

- (void)setUserId:(NSString*)userId
{
    _userId = userId;
    
	[ApiEngine friendWithId:userId completion:^(NSError *error, OREpicFriend *user) {
		if (error) {
            NSLog(@"Error: %@", error);
		} else {
			self.user = user;
		}
	}];
}

- (void)setUser:(OREpicFriend *)user
{
    _user = user;
    _contact = nil;
    _page = nil;
    
    self.textLabel.text = user.name;
    self.imageView.image = [UIImage imageNamed:@"profile"];
	self.imageView.contentMode = UIViewContentModeScaleAspectFill;
	self.imageView.clipsToBounds = YES;
    
	self.textLabel.textColor = [UIColor blackColor];
	self.detailTextLabel.textColor = [UIColor blackColor];
	self.backgroundColor = [UIColor whiteColor];
    
    if (!ORIsEmpty(user.bio)) {
        self.detailTextLabel.text = user.bio;
    } else {
        self.detailTextLabel.text = nil;
    }

	
    if (user.profileImageUrl) {
        if ([user.profileImageUrl hasPrefix:@"http"]) {
            __weak OREpicFriend *weakUser = user;
            __weak ORUserCell *weakCell = self;
            
            NSURL *url = [NSURL URLWithString:user.profileImageUrl];
            
            if (url) {
                [[ORCachedEngine sharedInstance] imageAtURL:url size:CGSizeMake(40.0f, 40.0f) fill:YES maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
                    if (error) NSLog(@"Error: %@", error);
                    
                    if (image && weakUser == weakCell.user) {
                        weakCell.imageView.image = image;
                        [weakCell setNeedsLayout];
                    }
                }];
            }
        } else {
            self.imageView.image = [UIImage imageNamed:user.profileImageUrl];
        }
    }
    
    [self setNeedsLayout];
}

- (void)setContact:(id<MBContactPickerModelProtocol>)contact
{
    _contact = contact;
    _user = nil;
    _page = nil;
    
    self.textLabel.text = contact.contactTitle;
    self.detailTextLabel.text = contact.contactSubtitle;
    self.imageView.image = [UIImage imageNamed:@"profile"];
	self.imageView.contentMode = UIViewContentModeScaleAspectFill;
	self.imageView.clipsToBounds = YES;
    
	self.textLabel.textColor = [UIColor blackColor];
	self.detailTextLabel.textColor = [UIColor blackColor];
    
	self.backgroundColor = [UIColor whiteColor];
	
    if (contact.contactImageURL) {
        __weak id<MBContactPickerModelProtocol> weakContact = contact;
        __weak ORUserCell *weakCell = self;
        
        NSURL *url = [NSURL URLWithString:contact.contactImageURL];
        [[ORCachedEngine sharedInstance] imageAtURL:url size:CGSizeMake(40.0f, 40.0f) fill:YES maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
            if (error) NSLog(@"Error: %@", error);
            
            if (image && weakContact == weakCell.contact) {
                weakCell.imageView.image = image;
                [weakCell setNeedsLayout];
            }
        }];
    }
    
    [self setNeedsLayout];
}

- (void)setPage:(ORFacebookPage *)page
{
    _page = page;
    _user = nil;
    _contact = nil;
    
    self.textLabel.text = page.pageName;
    self.imageView.image = [UIImage imageNamed:@"profile"];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    
    self.textLabel.textColor = [UIColor darkGrayColor];
    
    if (page.profilePicture) {
        __weak ORFacebookPage *weakPage = page;
        __weak ORUserCell *weakCell = self;
        
        NSURL *url = [NSURL URLWithString:page.profilePicture];
        [[ORCachedEngine sharedInstance] imageAtURL:url size:CGSizeMake(40.0f, 40.0f) fill:YES maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
            if (error) NSLog(@"Error: %@", error);
            
            if (image && weakPage == weakCell.page) {
                weakCell.imageView.image = image;
                [weakCell setNeedsLayout];
            }
        }];
    }
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(15.0f, 2.0f, 40.0f, 40.0f);
    self.imageView.layer.cornerRadius = self.imageView.frame.size.width / 2;
    
    CGRect f = self.textLabel.frame;
    f.origin.x = 74.0f;
    self.textLabel.frame = f;
    
    if (!ORIsEmpty(self.detailTextLabel.text)) {
        CGRect f = self.detailTextLabel.frame;
        f.origin.x = 74.0f;
        self.detailTextLabel.frame = f;
    }
}

@end
